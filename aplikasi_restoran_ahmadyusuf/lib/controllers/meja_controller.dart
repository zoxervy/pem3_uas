import '../models/meja.dart';
import 'base_controller.dart';

/// F-05: kelola meja (admin) + melihat status meja (admin & waitress).
class MejaController extends BaseController {
  MejaController(super.api);

  List<Meja> daftar = [];

  Future<void> muat() => jalankan(() async {
        final res = await api.get('/meja') as List;
        daftar = res
            .map((e) => Meja.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  Future<bool> simpan({int? id, required String nomor, String kapasitas = ''}) async {
    if (nomor.trim().isEmpty) return tolak('Nomor meja wajib diisi.');
    final kap = kapasitas.trim().isEmpty ? null : int.tryParse(kapasitas.trim());
    if (kapasitas.trim().isNotEmpty && (kap == null || kap < 1)) {
      return tolak('Kapasitas harus berupa angka minimal 1.');
    }
    final ok = await jalankan(() async {
      final body = {'nomor_meja': nomor.trim(), 'kapasitas': kap};
      if (id == null) {
        await api.post('/meja', body);
      } else {
        await api.put('/meja/$id', body);
      }
    });
    if (ok) await muat();
    return ok;
  }

  /// Admin: buat kode QR baru (QR lama tidak berlaku).
  Future<bool> qrBaru(int id) async {
    final ok = await jalankan(() async => api.post('/meja/$id/qr-baru'));
    if (ok) await muat();
    return ok;
  }

  Future<bool> hapus(int id) async {
    final ok = await jalankan(() async => api.delete('/meja/$id'));
    if (ok) await muat();
    return ok;
  }
}
