import '../models/pesanan.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'base_controller.dart';
import 'keranjang.dart';

export 'keranjang.dart' show ItemKeranjang;

/// Pesanan dari sisi staf.
/// Kasir: menugaskan waitress, membatalkan. Waitress: ambil tugas, ubah item,
/// validasi (QR bayar dibuat), antar.
class PesananController extends BaseController with KeranjangMixin {
  PesananController(super.api);

  /// Pesanan yang masih berjalan (waitress: tugasnya + yang belum ditugaskan).
  List<Pesanan> aktif = [];

  /// Daftar waitress aktif (untuk pilihan penugasan di layar kasir).
  List<User> waitress = [];

  /// Detail pesanan yang sudah pernah diambil, per id.
  final Map<int, Pesanan> detailCache = {};

  Pesanan _pesanan(dynamic res) => Pesanan.fromJson(Map<String, dynamic>.from(res as Map));

  Future<void> muatAktif() => jalankan(() async {
        aktif = (await api.get('/pesanan') as List).map(_pesanan).toList();
      });

  Future<void> muatWaitress() => jalankan(() async {
        waitress = (await api.get('/waitress') as List)
            .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  /// Ambil detail satu pesanan tanpa mengubah [loading] (aman dipanggil dari widget / polling).
  Future<Pesanan?> ambilDetail(int id, {bool segarkan = false}) async {
    if (!segarkan && detailCache.containsKey(id)) return detailCache[id];
    try {
      final p = _pesanan(await api.get('/pesanan/$id'));
      detailCache[id] = p;
      notifyListeners();
      return p;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// Jalankan satu aksi pada pesanan lalu muat ulang daftar.
  Future<Pesanan?> _aksi(int id, String aksi, [Object? body]) async {
    Pesanan? hasil;
    final ok = await jalankan(() async {
      hasil = _pesanan(await api.post('/pesanan/$id/$aksi', body));
    });
    if (!ok) return null;
    detailCache[id] = hasil!;
    await muatAktif();
    return hasil;
  }

  /// Kasir: tugaskan pesanan ke waitress.
  Future<bool> tugaskan(int id, int waiterId) async =>
      await _aksi(id, 'tugaskan', {'waiter_id': waiterId}) != null;

  /// Waitress: ambil sendiri pesanan yang belum ditugaskan.
  Future<bool> ambil(int id) async => await _aksi(id, 'ambil') != null;

  /// Waitress: pesanan sudah sesuai -> QR pembayaran dibuat (hasil berisi kodeBayar).
  Future<Pesanan?> konfirmasi(int id) => _aksi(id, 'konfirmasi');

  /// Waitress: pesanan lunas sudah diantar ke meja.
  Future<bool> antar(int id) async => await _aksi(id, 'antar') != null;

  /// Kasir / waitress bertugas: batalkan pesanan yang belum dibayar.
  Future<bool> batal(int id) async => await _aksi(id, 'batal') != null;

  /// Waitress: simpan perubahan item saat validasi (isi keranjang).
  Future<Pesanan?> ubahItems(int id) async {
    if (keranjang.isEmpty) {
      tolak('Pesanan harus punya minimal satu menu. Gunakan "Batal" untuk membatalkan.');
      return null;
    }
    Pesanan? hasil;
    final ok = await jalankan(() async {
      hasil = _pesanan(await api.put('/pesanan/$id/items', {'items': payloadItems}));
    });
    if (ok) {
      detailCache[id] = hasil!;
      kosongkanKeranjang();
    }
    return ok ? hasil : null;
  }
}
