# aplikasi_restoran_ahmadyusuf

Aplikasi pemesanan restoran: pelanggan memesan lewat QR meja, kasir menugaskan waitress,
waitress memvalidasi pesanan dan menampilkan QR pembayaran, lalu mengantar pesanan.

| Folder | Isi |
|---|---|
| `aplikasi_restoran_ahmadyusuf/` | Flutter web (MVC + provider): pelanggan, waitress, kasir, admin |
| `backend/` | REST API Laravel 13 + Sanctum, database MariaDB/MySQL |
| `deploy/` | `setup-server.sh` (sekali, butuh sudo) dan `redeploy.sh` (deploy ulang) |

## Menjalankan

```bash
# backend
cd backend && cp .env.example .env && composer install && php artisan key:generate
bash setup-db.sh                 # buat database & user dari nilai di .env (butuh sudo)
php artisan migrate --seed && php artisan test

# flutter (arahkan ke API lokal)
cd aplikasi_restoran_ahmadyusuf && flutter test
flutter run -d chrome --dart-define=API_BASE=http://127.0.0.1:8000/api
```

Mode pembayaran diatur `PEMBAYARAN_MODE` di `backend/.env` (`simulasi` untuk demo).
Akun demo dibuat oleh seeder; ganti passwordnya sebelum dipakai sungguhan.
