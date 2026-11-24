# MCP server buat ngatur server lewat Claude

`server.py` = MCP server (tool: `run_command`, `read_file`, `write_file`, `list_dir`).
`install.sh` = pasang semuanya di Ubuntu/Debian: venv, service systemd, dan route di **Caddy**
(sertifikat HTTPS diurus Caddy otomatis). App jalan di `127.0.0.1:8008` (bukan 8000, sering bentrok).

## Sebelum jalanin
1. Caddy sudah terpasang dan jalan sebagai service systemd (`systemctl status caddy`),
   config di `/etc/caddy/Caddyfile` (atau set `CADDYFILE=...`).
2. A record `mcp.ysfdev.my.id` -> IP server (kalau pakai Cloudflare, awan oranye boleh).
3. Port **80 dan 443** terbuka di firewall panel provider (security group), bukan cuma ufw.
   Port 80/443 dipakai Caddy buat verifikasi sertifikat, 443 dipakai Claude.

## Pasang (di server)
```bash
sudo bash install.sh
# opsi: MCP_ALLOW_SUDO=1 (izinkan sudo), MCP_USER=..., MCP_DOMAIN=..., CADDYFILE=...
```
Yang dilakukan ke Caddy: menulis `/etc/caddy/conf.d/mcp-server.caddy` dan menambah SATU baris
`import /etc/caddy/conf.d/*.caddy` di akhir Caddyfile (backup otomatis `Caddyfile.bak.<waktu>`).
Config divalidasi dulu; kalau gagal, Caddyfile dikembalikan dari backup. Site lain di Caddyfile nggak disentuh.

Di akhir, script nyetak URL `https://mcp.ysfdev.my.id/mcp/<token>`.

## Daftarin ke Claude
claude.ai -> Customize -> Connectors -> Add custom connector
- Nama: bebas (mis. `server-gue`)
- URL server MCP: URL dari script di atas

Lalu **mulai sesi baru** (connector baru kebaca saat sesi dimulai).

## Keamanan (penting)
- **URL itu password.** Siapa pun yang punya bisa jalanin perintah di server sebagai user service.
  Jangan di-commit ke git, jangan di-share, jangan di-screenshot.
- Default `NoNewPrivileges=true`: tool **nggak bisa sudo**. Aktifkan `MCP_ALLOW_SUDO=1` hanya kalau perlu,
  dan sadar bahwa kalau user itu punya sudo tanpa password, URL itu efektif jadi akses root.
- Tool file nggak dibatasi ke satu folder: karena ada `run_command`, pembatas yang nyata cuma hak akses user Linux.
- Semua perintah tercatat: `journalctl -u mcp-server -f`.
- Matiin akses: `sudo systemctl stop mcp-server`.
- Ganti token: `sudo rm /etc/mcp-server/token && sudo bash install.sh` (URL lama langsung mati).
