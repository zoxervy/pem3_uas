#!/usr/bin/env bash
# Install MCP server + route Caddy (HTTPS otomatis) di Ubuntu/Debian.
# Asumsi: Caddy sudah terpasang sebagai service systemd, config di /etc/caddy/Caddyfile.
#
#   sudo bash install.sh
#
# Opsi (env var, semuanya opsional):
#   MCP_DOMAIN=mcp.ysfdev.my.id     domain yang A record-nya sudah ke server ini
#   MCP_USER=claude                 user Linux yang menjalankan tool (bukan root)
#   MCP_ALLOW_SUDO=1                izinkan tool pakai sudo (default: TIDAK)
#   CADDYFILE=/etc/caddy/Caddyfile  lokasi Caddyfile kalau beda
#
# Aman dijalankan ulang (idempotent). Token lama dipakai lagi kalau sudah ada.
set -euo pipefail

DOMAIN="${MCP_DOMAIN:-mcp.ysfdev.my.id}"
RUN_USER="${MCP_USER:-${SUDO_USER:-claude}}"
ALLOW_SUDO="${MCP_ALLOW_SUDO:-0}"
CADDYFILE="${CADDYFILE:-/etc/caddy/Caddyfile}"
PORT=8008
APP_DIR=/opt/mcp-server
CONF_DIR=/etc/mcp-server
SNIPPET_DIR="$(dirname "$CADDYFILE")/conf.d"
SNIPPET="$SNIPPET_DIR/mcp-server.caddy"
MCP_PIN="mcp>=1.10,<2"   # SDK mcp v2 ganti total API, jadi di-pin ke v1

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Jalankan pakai sudo:  sudo bash install.sh"
command -v apt-get >/dev/null || die "Script ini cuma support Debian/Ubuntu (apt-get)."
[ "$RUN_USER" != "root" ] || die "Jangan jalanin tool sebagai root. Set MCP_USER=<user biasa>."
id "$RUN_USER" >/dev/null 2>&1 || die "User '$RUN_USER' nggak ada. Set MCP_USER=<user yang ada>."
HOME_DIR="$(getent passwd "$RUN_USER" | cut -d: -f6)"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SRC_DIR/server.py" ] || die "server.py nggak ketemu di $SRC_DIR"

say "Cek Caddy"
command -v caddy >/dev/null || die "Caddy belum terpasang. Pasang dulu: https://caddyserver.com/docs/install#debian-ubuntu-raspbian"
[ -f "$CADDYFILE" ] || die "Caddyfile nggak ketemu di $CADDYFILE. Set CADDYFILE=<path>."
systemctl is-active --quiet caddy || die "Service caddy nggak aktif (systemctl status caddy). Script ini butuh Caddy jalan via systemd."
echo "Caddy: $(caddy version | head -1)"

say "Install paket (python3-venv, curl, openssl)"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3 python3-venv curl openssl >/dev/null

say "Cek DNS $DOMAIN"
PUB_IP="$(curl -4fsS --max-time 8 https://api.ipify.org 2>/dev/null || true)"
DNS_IP="$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk '{print $1; exit}' || true)"
echo "IP publik server : ${PUB_IP:-?}"
echo "A record $DOMAIN : ${DNS_IP:-BELUM ADA}"
if [ -z "$DNS_IP" ]; then
  die "$DOMAIN belum resolve. Buat A record ke ${PUB_IP:-IP server} dulu, tunggu propagasi, jalankan ulang."
elif [ -n "$PUB_IP" ] && [ "$DNS_IP" != "$PUB_IP" ]; then
  echo "PERINGATAN: A record ($DNS_IP) beda dari IP publik server ($PUB_IP)."
  echo "            Kalau pakai proxy Cloudflare (awan oranye) itu normal, kalau bukan sertifikat akan gagal terbit."
fi

say "Pasang aplikasi di $APP_DIR"
install -d -m 755 "$APP_DIR"
install -m 644 "$SRC_DIR/server.py" "$APP_DIR/server.py"
[ -x "$APP_DIR/venv/bin/python" ] || python3 -m venv "$APP_DIR/venv"
"$APP_DIR/venv/bin/pip" install -q --upgrade pip
"$APP_DIR/venv/bin/pip" install -q "$MCP_PIN"

say "Token rahasia"
install -d -m 700 "$CONF_DIR"
if [ ! -s "$CONF_DIR/token" ]; then
  (umask 077; openssl rand -hex 32 > "$CONF_DIR/token")
  echo "Token baru dibuat."
else
  echo "Pakai token yang sudah ada ($CONF_DIR/token)."
fi
chmod 600 "$CONF_DIR/token"
TOKEN="$(tr -d '\n' < "$CONF_DIR/token")"

say "systemd service (mcp-server, user: $RUN_USER, sudo diizinkan: $ALLOW_SUDO)"
NNP="true"; [ "$ALLOW_SUDO" = "1" ] && NNP="false"
cat > /etc/systemd/system/mcp-server.service <<EOF
[Unit]
Description=MCP server ($DOMAIN)
After=network.target

[Service]
User=$RUN_USER
WorkingDirectory=$HOME_DIR
Environment=MCP_DOMAIN=$DOMAIN
Environment=MCP_HOST=127.0.0.1
Environment=MCP_PORT=$PORT
Environment=MCP_WORKDIR=$HOME_DIR
ExecStart=$APP_DIR/venv/bin/python $APP_DIR/server.py
Restart=always
RestartSec=3
NoNewPrivileges=$NNP

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --quiet mcp-server
systemctl restart mcp-server

say "Firewall lokal (ufw, kalau aktif)"
if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow 80/tcp >/dev/null && ufw allow 443/tcp >/dev/null && echo "ufw: port 80 dan 443 dibuka."
else
  echo "ufw nggak aktif, dilewati."
fi

say "Konfigurasi Caddy"
install -d -m 755 "$SNIPPET_DIR"
BACKUP="$CADDYFILE.bak.$(date +%Y%m%d%H%M%S)"
cp -p "$CADDYFILE" "$BACKUP"
IMPORT_LINE="import $SNIPPET_DIR/*.caddy"
if ! grep -qF "$IMPORT_LINE" "$CADDYFILE"; then
  printf '\n# ditambahkan oleh claude-mcp-server/install.sh\n%s\n' "$IMPORT_LINE" >> "$CADDYFILE"
  echo "Menambah baris '$IMPORT_LINE' ke $CADDYFILE (backup: $BACKUP)"
fi
# Caddy otomatis ambil & perpanjang sertifikat Let's Encrypt buat site address ini.
# Cuma path rahasia yang diteruskan ke app, sisanya 404.
cat > "$SNIPPET" <<EOF
$DOMAIN {
    handle /mcp/$TOKEN {
        rewrite * /mcp
        reverse_proxy 127.0.0.1:$PORT {
            flush_interval -1
        }
    }
    handle {
        respond 404
    }
}
EOF
chmod 640 "$SNIPPET"
if getent group caddy >/dev/null; then chgrp caddy "$SNIPPET"; fi
if ! caddy validate --config "$CADDYFILE" --adapter caddyfile >/tmp/caddy-validate.log 2>&1; then
  cp -p "$BACKUP" "$CADDYFILE"; rm -f "$SNIPPET"
  cat /tmp/caddy-validate.log >&2
  die "Caddyfile nggak valid (mungkin $DOMAIN sudah didefinisikan di tempat lain). Caddyfile dikembalikan dari backup."
fi
systemctl reload caddy

say "Self-test (nunggu Caddy ambil sertifikat, maks ~90 detik)"
CODE=000
for _ in $(seq 1 30); do
  CODE="$(curl -sS -m 10 -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"selftest","version":"1"}}}' \
    "https://$DOMAIN/mcp/$TOKEN" 2>/dev/null || true)"
  [ "$CODE" = "200" ] && break
  sleep 3
done
BAD="$(curl -sS -m 10 -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/mcp/salah" 2>/dev/null || true)"
if [ "$CODE" = "200" ] && [ "$BAD" = "404" ]; then
  echo "OK: sertifikat valid, path token => 200, path lain => 404."
else
  echo "PERINGATAN: self-test gagal (token=$CODE, salah=$BAD)."
  echo "  Sertifikat belum terbit? Cek: journalctl -u caddy -n 50 --no-pager"
  echo "  Penyebab paling umum: A record salah, atau port 80/443 belum dibuka di firewall PANEL PROVIDER."
  echo "  Aplikasi: journalctl -u mcp-server -n 50 --no-pager"
fi

cat <<EOF

============================================================
SELESAI. URL buat kolom "URL server MCP" di claude.ai:

    https://$DOMAIN/mcp/$TOKEN

URL ini = PASSWORD. Siapa pun yang punya bisa jalanin perintah
di server ini sebagai user '$RUN_USER'. Jangan di-share/screenshot.

Perintah berguna:
  journalctl -u mcp-server -f        # lihat semua perintah yang dijalankan
  sudo systemctl stop mcp-server     # matiin akses seketika
  sudo systemctl start mcp-server    # nyalain lagi
  sudo rm $CONF_DIR/token && sudo bash install.sh   # ganti token (URL lama mati)
  sudo rm $SNIPPET && sudo systemctl reload caddy    # copot route dari Caddy
============================================================
EOF
