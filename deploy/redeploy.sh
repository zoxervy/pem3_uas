#!/usr/bin/env bash
# Deploy ulang TANPA sudo: build Flutter web -> ~/www/resto, migrasi DB Laravel.
#   bash redeploy.sh            (build + deploy)
#   SKIP_BUILD=1 bash redeploy.sh   (pakai build/web yang sudah ada)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/aplikasi_restoran_ahmadyusuf"
BACKEND="$ROOT/backend"
WEBROOT="$HOME/www/resto"
export PATH="$HOME/flutter/bin:$PATH" CI=true FLUTTER_SUPPRESS_ANALYTICS=true

echo "==> Backend: migrasi database + autoload & route cache"
(cd "$BACKEND" && php artisan migrate --force && composer dump-autoload -o -q && php artisan route:cache -q)

if [ "${SKIP_BUILD:-0}" != 1 ]; then
  echo "==> Flutter: build web (release)"
  (cd "$APP" && flutter build web --release --wasm)
fi
[ -f "$APP/build/web/index.html" ] || { echo "build/web nggak ada"; exit 1; }

echo "==> Pasang ke $WEBROOT (ganti sekaligus)"
mkdir -p "$(dirname "$WEBROOT")"
rm -rf "$WEBROOT.new" "$WEBROOT.old"
cp -a "$APP/build/web" "$WEBROOT.new"
chmod -R a+rX "$WEBROOT.new"
[ -d "$WEBROOT" ] && mv "$WEBROOT" "$WEBROOT.old"
mv "$WEBROOT.new" "$WEBROOT"
rm -rf "$WEBROOT.old"
echo "Selesai."
