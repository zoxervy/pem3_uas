import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// Dasar semua controller: menyimpan status loading + pesan error, dan
/// membungkus pemanggilan API supaya error tampil rapi.
abstract class BaseController extends ChangeNotifier {
  BaseController(this.api);

  final ApiService api;
  bool loading = false;
  String? error;

  /// Jalankan [aksi]; true kalau sukses, false kalau gagal (pesan ada di [error]).
  Future<bool> jalankan(Future<void> Function() aksi) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await aksi();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } catch (e) {
      error = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Tandai gagal validasi lokal (tanpa memanggil server).
  bool tolak(String pesan) {
    error = pesan;
    notifyListeners();
    return false;
  }

  void bersihkanError() {
    if (error == null) return;
    error = null;
    notifyListeners();
  }
}
