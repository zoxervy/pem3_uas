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
setup.php            siapkan .env + database + data demo (php setup.php)
index.php, .htaccess pintu masuk bila root web = folder backend (Laragon)
seed.sql             data demo (akun, menu, 3 meja)
tests/uji_api.php    test API (data uji di-rollback, database tidak berubah)
```

## Menjalankan di Laragon

Butuh Laragon dengan PHP 8.1+ dan MySQL (atau MariaDB), serta Flutter SDK.

1. Salin folder `backend` menjadi `C:\laragon\www\resto-api`, lalu klik **Start All** di Laragon.
2. Buka **Terminal** Laragon:
   ```
   cd C:\laragon\www\resto-api
   php setup.php
   ```
   Perintah ini membuat `.env` dari `.env.example` (user `root`, password kosong), database `resto`,
   8 tabel, data demo, lalu menampilkan link QR ketiga meja.
   Database yang sudah berisi tabel tidak diubah; untuk mengulang dari awal: `php setup.php --reset`.
3. Cek di browser: `http://localhost/resto-api/api/publik/meja/xxx` harus menampilkan
   `{"message":"QR meja tidak dikenali."}`. Opsional: `php tests/uji_api.php` (9 test, data uji di-rollback).
4. Jalankan Flutter dari folder `aplikasi_restoran_ahmadyusuf`:
   ```
   flutter pub get
   flutter run -d chrome --web-port 8080
   ```
   Saat `flutter run`, aplikasi otomatis memanggil `http://localhost/resto-api/api`.
   Port 8080 dipakai supaya link QR meja dari `setup.php` (`http://localhost:8080/?meja=...`) tetap berlaku.

Akun demo: `admin/admin123`, `sari/kasir123` (kasir), `rina/waitress123` dan `budi/waitress123` (waitress).
Untuk mencoba alur pelanggan, buka link QR meja di tab lain (atau dari halaman admin **QR Meja**).

**Nama folder lain atau virtual host** (mis. `http://resto-api.test`):
`flutter run -d chrome --web-port 8080 --dart-define=API_BASE=http://resto-api.test/api`.
Root web boleh folder `backend` maupun `backend/public`; `.env`, `src/`, dan file `.sql` tidak bisa diunduh lewat browser.

**Tes dari HP** (satu Wi-Fi dengan laptop; ganti `192.168.1.10` dengan IP laptop dari `ipconfig`):
```
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --dart-define=API_BASE=http://192.168.1.10/resto-api/api
```
Buka `http://192.168.1.10:8080` di HP. QR yang tampil di aplikasi otomatis memakai alamat itu.
Bila tidak bisa dibuka, izinkan Apache dan Dart di Windows Firewall.

## Di server (Caddy + PHP-FPM)

Caddy meneruskan `/api/*` ke `public/index.php`. Konfigurasi database dibaca dari `.env`
(boleh memakai `DB_SOCKET=/run/mysqld/mysqld.sock`). `setup-db.sh` membuat database dan user dari nilai di `.env`.
