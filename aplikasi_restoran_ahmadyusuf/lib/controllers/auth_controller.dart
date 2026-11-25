import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import 'base_controller.dart';

/// F-01: login, logout, dan memulihkan sesi (token disimpan di browser).
class AuthController extends BaseController {
  AuthController(super.api) {
    api.onUnauthorized = _sesiBerakhir;
  }

  static const _kunciToken = 'token';

  User? user;
  bool sudahCekSesi = false;

  bool get sudahLogin => user != null;

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return tolak('Username dan password wajib diisi.');
    }
    return jalankan(() async {
      final res = await api.post('/login', {
        'username': username.trim(),
        'password': password,
      });
      api.token = res['token'] as String;
      user = User.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      await _simpanToken(api.token);
    });
  }

  /// Dipanggil saat aplikasi dibuka: kalau ada token tersimpan, cek ke server.
  Future<void> pulihkanSesi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kunciToken);
      if (token != null) {
        api.token = token;
        final res = await api.get('/me');
        user = User.fromJson(Map<String, dynamic>.from(res as Map));
        if (!user!.aktif) await _hapusSesi();
      }
    } catch (_) {
      await _hapusSesi();
    }
    sudahCekSesi = true;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.post('/logout');
    } on ApiException {
      // tetap logout di sisi aplikasi walau server tidak terjangkau
    }
    await _hapusSesi();
    notifyListeners();
  }

  void _sesiBerakhir() {
    _hapusSesi();
    error = 'Sesi Anda berakhir, silakan login lagi.';
    notifyListeners();
  }

  Future<void> _hapusSesi() async {
    api.token = null;
    user = null;
    await _simpanToken(null);
  }

  Future<void> _simpanToken(String? token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token == null) {
        await prefs.remove(_kunciToken);
      } else {
        await prefs.setString(_kunciToken, token);
      }
    } catch (_) {
      // penyimpanan browser bisa diblokir; aplikasi tetap jalan tanpa ingat sesi
    }
  }
}
