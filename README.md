# aplikasi_restoran_ahmadyusuf

Aplikasi pemesanan restoran: pelanggan memesan lewat QR meja, kasir menugaskan waitress,
waitress memvalidasi pesanan dan menampilkan QR pembayaran, lalu mengantar pesanan.

| Folder | Isi |
|---|---|
| `aplikasi_restoran_ahmadyusuf/` | Flutter web (MVC + provider): pelanggan, waitress, kasir, admin |
| `backend/` | REST API PHP native (tanpa framework), database MySQL/MariaDB. Panduan Laragon: `backend/README.md` |
| `deploy/` | `setup-server.sh` (sekali, butuh sudo) dan `redeploy.sh` (deploy ulang) |

## Menjalankan

```bash
# backend: lihat backend/README.md (Laragon atau server)
cd backend && cp .env.example .env      # isi koneksi database
mysql -u root resto < schema.sql && mysql -u root resto < seed.sql
php tests/uji_api.php

# flutter (arahkan ke API lokal)
cd aplikasi_restoran_ahmadyusuf && flutter test
flutter run -d chrome --dart-define=API_BASE=http://resto-api.test/api
```

Mode pembayaran diatur `PEMBAYARAN_MODE` di `backend/.env` (`simulasi` untuk demo).
Akun demo dibuat oleh seeder; ganti passwordnya sebelum dipakai sungguhan.
