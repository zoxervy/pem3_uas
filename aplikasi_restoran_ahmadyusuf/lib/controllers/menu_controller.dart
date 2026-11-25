import '../models/menu.dart';
import 'base_controller.dart';

/// F-04: kelola menu (CRUD, admin) + daftar menu untuk waitress.
class MenuController extends BaseController {
  MenuController(super.api);

  List<Menu> daftar = [];

  Future<void> muat({int? kategoriId}) => jalankan(() async {
        final res = await api.get('/menu', query: {'kategori_id': kategoriId}) as List;
        daftar = res
            .map((e) => Menu.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  /// Validasi input form; hasilnya pesan error atau null kalau valid.
  String? validasi({
    required int? kategoriId,
    required String nama,
    required String harga,
  }) {
    if (nama.trim().isEmpty) return 'Nama menu wajib diisi.';
    if (kategoriId == null) return 'Pilih kategori terlebih dahulu.';
    if (harga.trim().isEmpty) return 'Harga wajib diisi.';
    final nilai = int.tryParse(harga.trim());
    if (nilai == null || nilai <= 0) return 'Harga harus berupa angka lebih dari 0.';
    return null;
  }

  Future<bool> tambah({
    int? kategoriId,
    String nama = '',
    String harga = '',
    String deskripsi = '',
    String foto = '',
    bool tersedia = true,
  }) =>
      _simpan(null, kategoriId, nama, harga, deskripsi, foto, tersedia);

  Future<bool> ubah(
    int id, {
    int? kategoriId,
    String nama = '',
    String harga = '',
    String deskripsi = '',
    String foto = '',
    bool tersedia = true,
  }) =>
      _simpan(id, kategoriId, nama, harga, deskripsi, foto, tersedia);

  Future<bool> _simpan(int? id, int? kategoriId, String nama, String harga,
      String deskripsi, String foto, bool tersedia) async {
    final salah = validasi(kategoriId: kategoriId, nama: nama, harga: harga);
    if (salah != null) return tolak(salah);

    final body = {
      'kategori_id': kategoriId,
      'nama_menu': nama.trim(),
      'harga': int.parse(harga.trim()),
      'deskripsi': deskripsi.trim().isEmpty ? null : deskripsi.trim(),
      'foto': foto.trim().isEmpty ? null : foto.trim(),
      'tersedia': tersedia,
    };
    final ok = await jalankan(() async {
      if (id == null) {
        await api.post('/menu', body);
      } else {
        await api.put('/menu/$id', body);
      }
    });
    if (ok) await muat();
    return ok;
  }

  Future<bool> hapus(int id) async {
    final ok = await jalankan(() async => api.delete('/menu/$id'));
    if (ok) await muat();
    return ok;
  }
}
