#!/usr/bin/env bash
# Deploy ulang TANPA sudo: test API, build Flutter web -> ~/www/resto.
#   bash redeploy.sh            (build + deploy)
#   SKIP_BUILD=1 bash redeploy.sh   (pakai build/web yang sudah ada)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/aplikasi_restoran_ahmadyusuf"
BACKEND="$ROOT/backend"
WEBROOT="$HOME/www/resto"
export PATH="$HOME/flutter/bin:$PATH" CI=true FLUTTER_SUPPRESS_ANALYTICS=true

echo "==> Backend: cek sintaks PHP + test API (data uji di-rollback)"
find "$BACKEND/src" "$BACKEND/public" -name '*.php' -print0 | xargs -0 -n1 php -l | grep -v '^No syntax' || true
(cd "$BACKEND" && php tests/uji_api.php | tail -1)

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
