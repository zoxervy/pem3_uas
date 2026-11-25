#!/usr/bin/env bash
# SEKALI JALAN, butuh sudo:  sudo bash setup-server.sh
# 1) izin AppArmor php-fpm untuk folder backend   2) pool PHP-FPM (jalan sebagai user biasa)
# 3) validasi + reload Caddy (blok resto.ysfdev.my.id sudah ada di /etc/caddy/Caddyfile). Setelah ini deploy ulang cukup redeploy.sh (tanpa sudo).
# Aman diulang.
set -euo pipefail

DOMAIN="${DOMAIN:-resto.ysfdev.my.id}"
APP_USER="${APP_USER:-${SUDO_USER:-ubuntu}}"
PHPV="${PHPV:-8.3}"
HOME_DIR="$(getent passwd "$APP_USER" | cut -d: -f6)"
BACKEND="$HOME_DIR/pem3_uas/backend"
WEBROOT="$HOME_DIR/www/resto"
POOL="/etc/php/$PHPV/fpm/pool.d/resto.conf"
SOCK="/run/php/php$PHPV-resto-fpm.sock"          # harus cocok pola AppArmor php*-fpm.sock
AA_LOCAL=/etc/apparmor.d/local/php-fpm
CADDYFILE=/etc/caddy/Caddyfile

say() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Jalankan pakai sudo:  sudo bash $0"
[ "$APP_USER" != root ] || die "APP_USER jangan root"
[ -f "$BACKEND/public/index.php" ] || die "Backend nggak ketemu di $BACKEND"
[ -f "$WEBROOT/index.html" ] || die "Web build belum ada di $WEBROOT (jalankan redeploy.sh dulu)"
id caddy >/dev/null 2>&1 || die "User caddy nggak ada"

say "AppArmor: izinkan php-fpm membaca backend (tulis hanya storage & bootstrap/cache)"
if [ -f /etc/apparmor.d/php-fpm ]; then
  touch "$AA_LOCAL"
  if ! grep -q '# >>> resto' "$AA_LOCAL"; then
    cp -p "$AA_LOCAL" "$AA_LOCAL.bak.$(date +%Y%m%d%H%M%S)"
    cat >> "$AA_LOCAL" <<AAEOF
# >>> resto (ditambahkan oleh pem3_uas/deploy/setup-server.sh)
$HOME_DIR/pem3_uas/backend/ r,
$HOME_DIR/pem3_uas/backend/** r,
$HOME_DIR/pem3_uas/backend/storage/** rwk,
$HOME_DIR/pem3_uas/backend/bootstrap/cache/** rwk,
# <<< resto
AAEOF
    echo "Ditambahkan ke $AA_LOCAL"
  else
    echo "Blok resto sudah ada di $AA_LOCAL"
  fi
  apparmor_parser -r /etc/apparmor.d/php-fpm
else
  echo "Profil AppArmor php-fpm nggak ada, dilewati."
fi

say "Pool PHP-FPM 'resto' (user: $APP_USER)"
cat > "$POOL" <<POOLEOF
[resto]
user = $APP_USER
group = $APP_USER
listen = $SOCK
listen.owner = caddy
listen.group = caddy
listen.mode = 0660
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 30s
POOLEOF
"php-fpm$PHPV" -t 2>&1 | tail -1
systemctl restart "php$PHPV-fpm"
for _ in $(seq 1 10); do [ -S "$SOCK" ] && break; sleep 1; done
[ -S "$SOCK" ] || die "Socket $SOCK nggak muncul. Cek: journalctl -u php$PHPV-fpm -n 30"
echo "Socket siap: $SOCK"

say "Caddy: cek blok $DOMAIN di $CADDYFILE"
grep -qE "^$DOMAIN[[:space:]]*\\{" "$CADDYFILE" || die "Blok '$DOMAIN {' belum ada di $CADDYFILE."
grep -qF "$SOCK" "$CADDYFILE" || die "Blok $DOMAIN di Caddyfile nggak memakai socket $SOCK."
[ -e /etc/caddy/conf.d/resto.caddy ] && die "Ada /etc/caddy/conf.d/resto.caddy sisa versi lama (bakal dobel). Hapus dulu: sudo rm /etc/caddy/conf.d/resto.caddy"
if ! caddy validate --config "$CADDYFILE" --adapter caddyfile >/tmp/caddy-validate.log 2>&1; then
  cat /tmp/caddy-validate.log >&2
  die "Caddyfile nggak valid, TIDAK di-reload (Caddy lama tetap jalan). Pulihkan dari backup di ~/Caddyfile.bak.*-resto kalau perlu."
fi
systemctl reload caddy
echo "Caddy di-reload."

say "Self-test (nunggu sertifikat, maks ~90 detik)"
WEB=000; API=000
for _ in $(seq 1 30); do
  WEB="$(curl -sS -m 10 -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" "https://$DOMAIN/" 2>/dev/null || true)"
  API="$(curl -sS -m 10 -o /dev/null -w '%{http_code}' --resolve "$DOMAIN:443:127.0.0.1" -H 'Accept: application/json' \
        -H 'Content-Type: application/json' -d '{"username":"x","password":"y"}' "https://$DOMAIN/api/login" 2>/dev/null || true)"
  [ "$WEB" = 200 ] && [ "$API" = 401 ] && break
  sleep 3
done
if [ "$WEB" = 200 ] && [ "$API" = 401 ]; then
  echo "OK: web => 200, /api/login (salah password) => 401."
  echo "Buka: https://$DOMAIN"
else
  echo "PERINGATAN: web=$WEB api=$API"
  echo "  AppArmor: journalctl -k --since '-5 min' | grep -i denied"
  echo "  Caddy   : journalctl -u caddy -n 50 --no-pager"
  echo "  PHP     : journalctl -u php$PHPV-fpm -n 50 --no-pager ; tail $BACKEND/storage/logs/laravel.log"
fi
