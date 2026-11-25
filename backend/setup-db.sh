#!/usr/bin/env bash
# Bikin database + user MariaDB/MySQL buat backend, pakai nilai dari .env.
# Jalankan:  bash setup-db.sh      (akan minta sudo; aman diulang)
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
[ -f .env ] || { echo "ERROR: .env nggak ada di $(pwd)"; exit 1; }

env_get() { grep -E "^$1=" .env | head -1 | cut -d= -f2- | tr -d '\r"'"'"; }
DB="$(env_get DB_DATABASE)"; USR="$(env_get DB_USERNAME)"; PW="$(env_get DB_PASSWORD)"
SOCK="$(env_get DB_SOCKET)"
[ -n "$DB" ] && [ -n "$USR" ] && [ -n "$PW" ] || { echo "ERROR: DB_DATABASE/DB_USERNAME/DB_PASSWORD kosong di .env"; exit 1; }
# nama dipakai di SQL, jadi batasi karakternya
[[ "$DB$USR" =~ ^[A-Za-z0-9_]+$ ]] || { echo "ERROR: nama database/user cuma boleh huruf, angka, underscore"; exit 1; }
[[ "$PW" =~ ^[A-Za-z0-9]+$ ]] || { echo "ERROR: password di .env harus alfanumerik"; exit 1; }

echo "==> Membuat database '$DB' dan user '$USR' (hak hanya di database itu)"
sudo mariadb <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$USR'@'localhost' IDENTIFIED BY '$PW';
ALTER USER '$USR'@'localhost' IDENTIFIED BY '$PW';
GRANT ALL PRIVILEGES ON \`$DB\`.* TO '$USR'@'localhost';
FLUSH PRIVILEGES;
SQL

echo "==> Tes login sebagai '$USR'"
if MYSQL_PWD="$PW" mariadb -u "$USR" ${SOCK:+--socket="$SOCK"} -e "SELECT CURRENT_USER() AS user, DATABASE() AS db;" "$DB"; then
  echo "OK: database siap dipakai."
else
  echo "GAGAL: user nggak bisa login, cek pesan di atas." >&2; exit 1
fi
