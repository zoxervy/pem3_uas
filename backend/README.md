# Backend API (PHP native)

REST API untuk aplikasi restoran. PHP 8.1+ dan MySQL/MariaDB, tanpa framework dan tanpa Composer.

```
public/index.php     satu-satunya pintu masuk (+ .htaccess untuk Apache)
src/App.php          router: cocokkan URL, cek login & role
src/Db.php           koneksi PDO + transaksi (semua query prepared statement)
src/Validasi.php     validasi input
src/Auth.php         token login
src/Format.php       bentuk JSON yang dikirim ke Flutter
src/rute.php         daftar endpoint
src/handler/         isi tiap fitur: auth, master, pesanan, publik, laporan
schema.sql           struktur 7 tabel + tabel token
seed.sql             data demo (akun, menu, 3 meja)
tests/uji_api.php    test API (data uji di-rollback, database tidak berubah)
```

## Menjalankan di Laragon

1. Salin folder `backend` ke `C:\laragon\www\resto-api`.
   Laragon otomatis membuat alamat `http://resto-api.test` dengan folder `public` sebagai root.
2. Buat database `resto`, lalu impor `schema.sql` kemudian `seed.sql`
   (HeidiSQL: *File > Run SQL file*, atau terminal Laragon:
   `mysql -u root -e "CREATE DATABASE resto"`, `mysql -u root resto < schema.sql`, `mysql -u root resto < seed.sql`).
3. Salin `.env.example` menjadi `.env` (bawaan Laragon: user `root`, password kosong).
4. Cek: buka `http://resto-api.test/api/publik/meja/xxx`, harus muncul `{"message":"QR meja tidak dikenali."}`.
5. Jalankan test: `php tests/uji_api.php`.
6. Jalankan Flutter ke API lokal:
   `flutter run -d chrome --dart-define=API_BASE=http://resto-api.test/api`

Akun demo dari `seed.sql`: `admin/admin123`, `rina/waitress123`, `budi/waitress123`, `sari/kasir123`.
Kode QR meja ada di halaman admin **QR Meja**.

## Di server (Caddy + PHP-FPM)

Caddy meneruskan `/api/*` ke `public/index.php`. Konfigurasi database dibaca dari `.env`
(boleh memakai `DB_SOCKET=/run/mysqld/mysqld.sock`). `setup-db.sh` membuat database dan user dari nilai di `.env`.
