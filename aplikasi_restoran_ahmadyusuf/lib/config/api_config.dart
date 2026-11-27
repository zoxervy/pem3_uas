import 'package:flutter/foundation.dart';

/// Alamat server API.
///
/// - Build rilis di web: API ada di domain yang sama (Caddy meneruskan /api ke PHP).
/// - `flutter run` (debug) atau aplikasi non-web: API Laragon di komputer sendiri.
/// - Alamat lain: flutter run -d chrome --dart-define=API_BASE=http://alamat-lain/api
class ApiConfig {
  static const String _override = String.fromEnvironment('API_BASE');
  static const String lokal = 'http://localhost/resto-api/api';

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb && kReleaseMode) return '${Uri.base.origin}/api';
    return lokal;
  }
}
