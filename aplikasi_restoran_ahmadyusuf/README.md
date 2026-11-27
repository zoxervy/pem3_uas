# aplikasi_restoran_ahmadyusuf

Flutter web (MVC + provider) untuk pelanggan, waitress, kasir, dan admin.

```
flutter pub get
flutter test
flutter run -d chrome --web-port 8080      # memakai API Laragon: http://localhost/resto-api/api
```

Alamat API diatur di `lib/config/api_config.dart`:
- `flutter run` (debug): `http://localhost/resto-api/api` (backend di `C:\laragon\www\resto-api`, lihat `../backend/README.md`);
- build rilis web: `/api` di domain yang sama (server);
- alamat lain: `--dart-define=API_BASE=http://alamat/api`.
