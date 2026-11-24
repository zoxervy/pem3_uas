#!/usr/bin/env python3
"""MCP server buat ngatur server sendiri lewat Claude.

Jalan di 127.0.0.1 (nggak diekspos langsung). Caddy yang nerima HTTPS dan
nerusin ke sini. Semua tool jalan sebagai user Linux yang menjalankan service
ini, jadi batas sebenarnya adalah hak akses user itu (bukan kode di bawah).
"""
import asyncio
import logging
import os
import signal
from pathlib import Path

from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings

DOMAIN = os.environ.get("MCP_DOMAIN", "")
HOST = os.environ.get("MCP_HOST", "127.0.0.1")
PORT = int(os.environ.get("MCP_PORT", "8000"))
WORKDIR = Path(os.environ.get("MCP_WORKDIR", str(Path.home()))).expanduser().resolve()
MAX_OUT = 60_000  # karakter output yang dikembalikan ke Claude

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
log = logging.getLogger("mcp-server")

allowed_hosts = [f"127.0.0.1:{PORT}", f"localhost:{PORT}", "127.0.0.1", "localhost"]
allowed_origins = ["https://claude.ai", "https://claude.com"]
if DOMAIN:
    allowed_hosts += [DOMAIN, f"{DOMAIN}:443"]
    allowed_origins.append(f"https://{DOMAIN}")

mcp = FastMCP(
    "server-gue",
    host=HOST,
    port=PORT,
    streamable_http_path="/mcp",
    stateless_http=True,  # aman di belakang reverse proxy, nggak butuh session
    transport_security=TransportSecuritySettings(
        enable_dns_rebinding_protection=True,
        allowed_hosts=allowed_hosts,
        allowed_origins=allowed_origins,
    ),
)


def _resolve(path: str) -> Path:
    p = Path(path).expanduser() if path else Path(".")
    return p if p.is_absolute() else (WORKDIR / p)


def _clip(text: str) -> str:
    if len(text) <= MAX_OUT:
        return text
    half = MAX_OUT // 2
    return f"{text[:half]}\n...[dipotong {len(text) - MAX_OUT} karakter]...\n{text[-half:]}"


@mcp.tool()
async def run_command(command: str, timeout: int = 60, cwd: str = "") -> str:
    """Jalanin perintah shell (bash -lc) di server. Balikin exit code, stdout, stderr.

    timeout dalam detik (1-900). cwd opsional, default folder kerja.
    Perintah interaktif nggak didukung (stdin kosong).
    """
    timeout = max(1, min(int(timeout), 900))
    workdir = _resolve(cwd)
    log.info("run_command cwd=%s timeout=%s cmd=%r", workdir, timeout, command)
    proc = await asyncio.create_subprocess_exec(
        "bash", "-lc", command,
        cwd=str(workdir),
        stdin=asyncio.subprocess.DEVNULL,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        start_new_session=True,  # biar bisa kill seluruh process group
    )
    try:
        out, err = await asyncio.wait_for(proc.communicate(), timeout=timeout)
        status = f"exit code: {proc.returncode}"
    except asyncio.TimeoutError:
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        out, err = await proc.communicate()
        status = f"TIMEOUT setelah {timeout}s, proses di-kill"
    return _clip(
        f"{status}\n--- stdout ---\n{out.decode(errors='replace')}"
        f"\n--- stderr ---\n{err.decode(errors='replace')}"
    )


@mcp.tool()
def read_file(path: str, max_bytes: int = 200_000) -> str:
    """Baca file teks. Path relatif dihitung dari folder kerja."""
    p = _resolve(path)
    log.info("read_file %s", p)
    with open(p, "rb") as f:
        data = f.read(max(1, int(max_bytes)) + 1)
    text = data[:max_bytes].decode(errors="replace")
    return text + ("\n...[file dipotong]..." if len(data) > max_bytes else "")


@mcp.tool()
def write_file(path: str, content: str, append: bool = False) -> str:
    """Tulis (atau append) teks ke file. Folder induk dibuat kalau belum ada."""
    p = _resolve(path)
    log.info("write_file %s append=%s bytes=%d", p, append, len(content))
    p.parent.mkdir(parents=True, exist_ok=True)
    with open(p, "a" if append else "w", encoding="utf-8") as f:
        f.write(content)
    return f"ok: {p} ({len(content.encode())} bytes)"


@mcp.tool()
def list_dir(path: str = ".") -> str:
    """Daftar isi folder (nama, tipe, ukuran)."""
    p = _resolve(path)
    log.info("list_dir %s", p)
    rows = []
    for e in sorted(p.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower())):
        try:
            size = "-" if e.is_dir() else str(e.stat().st_size)
        except OSError:
            size = "?"
        rows.append(f"{'d' if e.is_dir() else 'f'}  {size:>10}  {e.name}")
    return f"{p}\n" + "\n".join(rows) if rows else f"{p}\n(kosong)"


if __name__ == "__main__":
    log.info("MCP server di %s:%s, workdir=%s, domain=%s", HOST, PORT, WORKDIR, DOMAIN or "-")
    mcp.run(transport="streamable-http")
