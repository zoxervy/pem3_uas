# aplikasi_restoran_ahmadyusuf

Aplikasi pemesanan restoran: pelanggan memesan lewat QR meja, kasir menugaskan waitress,
waitress memvalidasi pesanan dan menampilkan QR pembayaran, lalu mengantar pesanan.

| Folder | Isi |
|---|---|
| `aplikasi_restoran_ahmadyusuf/` | Flutter web (MVC + provider): pelanggan, waitress, kasir, admin |
| `backend/` | REST API PHP native (tanpa framework), database MySQL/MariaDB. Panduan Laragon: `backend/README.md` |
| `deploy/` | `setup-server.sh` (sekali, butuh sudo) dan `redeploy.sh` (deploy ulang) |

## Menjalankan di komputer sendiri (Laragon + `flutter run`)

```bash
# 1. Backend: salin folder backend ke C:\laragon\www\resto-api, Start All di Laragon, lalu di Terminal Laragon:
cd C:\laragon\www\resto-api
php setup.php                 # buat .env, database "resto", tabel, dan data demo
php tests/uji_api.php         # opsional: 9 test API

# 2. Flutter (debug otomatis memakai http://localhost/resto-api/api)
cd aplikasi_restoran_ahmadyusuf
flutter pub get
flutter run -d chrome --web-port 8080
```

Panduan lengkap (termasuk tes dari HP): `backend/README.md`.
Di server, build rilis memakai API di domain yang sama, jadi tidak perlu pengaturan apa pun.

Mode pembayaran diatur `PEMBAYARAN_MODE` di `backend/.env` (`simulasi` untuk demo).
Akun demo dibuat oleh `seed.sql`; ganti passwordnya sebelum dipakai sungguhan.
