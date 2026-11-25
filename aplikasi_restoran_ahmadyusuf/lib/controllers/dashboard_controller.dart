import '../models/json_util.dart';
import 'base_controller.dart';

/// F-02: isi dashboard (bentuknya beda per role, jadi disimpan sebagai Map).
class DashboardController extends BaseController {
  DashboardController(super.api);

  Map<String, dynamic> data = {};

  Future<void> muat() => jalankan(() async {
        final res = await api.get('/dashboard');
        data = Map<String, dynamic>.from(res as Map);
      });

  /// Angka dari server (bisa berupa teks untuk hasil SUM di MariaDB).
  int angka(String kunci) => toInt(data[kunci]);

  List<Map<String, dynamic>> daftar(String kunci) => (data[kunci] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}
