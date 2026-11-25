/// Alamat server API.
///
/// Di web, aplikasi dan API ada di domain yang sama (Caddy meneruskan /api ke
/// Laravel), jadi cukup memakai origin halaman. Untuk development lokal bisa
/// diganti: flutter run -d chrome --dart-define=API_BASE=http://127.0.0.1:8123/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE');

  static String get baseUrl =>
      _override.isNotEmpty ? _override : '${Uri.base.origin}/api';
}
