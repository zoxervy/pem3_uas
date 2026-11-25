import '../models/kategori.dart';
import 'base_controller.dart';

/// F-03: kelola kategori menu (CRUD, admin).
class KategoriController extends BaseController {
  KategoriController(super.api);

  List<Kategori> daftar = [];

  Future<void> muat() => jalankan(() async {
        final res = await api.get('/kategori') as List;
        daftar = res
            .map((e) => Kategori.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  Future<bool> simpan({int? id, required String nama}) async {
    if (nama.trim().isEmpty) return tolak('Nama kategori wajib diisi.');
    final ok = await jalankan(() async {
      final body = {'nama_kategori': nama.trim()};
      if (id == null) {
        await api.post('/kategori', body);
      } else {
        await api.put('/kategori/$id', body);
      }
    });
    if (ok) await muat();
    return ok;
  }

  Future<bool> hapus(int id) async {
    final ok = await jalankan(() async => api.delete('/kategori/$id'));
    if (ok) await muat();
    return ok;
  }
}
