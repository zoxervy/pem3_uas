import 'package:intl/intl.dart';

import '../models/pesanan.dart';
import 'base_controller.dart';

/// F-11, F-12: kasir menerima bayar tunai (cadangan) dan melihat riwayat transaksi.
class PembayaranController extends BaseController {
  PembayaranController(super.api);

  List<Pesanan> riwayat = [];

  static final _tgl = DateFormat('yyyy-MM-dd');

  List<Pesanan> _daftar(dynamic res) => (res as List)
      .map((e) => Pesanan.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  Future<void> muatRiwayat({DateTime? dari, DateTime? sampai}) => jalankan(() async {
        riwayat = _daftar(await api.get('/riwayat', query: {
          'dari': dari == null ? null : _tgl.format(dari),
          'sampai': sampai == null ? null : _tgl.format(sampai),
        }));
      });

  /// F-11: konfirmasi pembayaran. Ditolak (tanpa ke server) kalau uang kurang.
  Future<Pesanan?> konfirmasi(Pesanan pesanan, int bayar) async {
    if (bayar < pesanan.total) {
      tolak('Uang bayar kurang dari total tagihan.');
      return null;
    }
    Pesanan? hasil;
    final ok = await jalankan(() async {
      final res = await api.post('/pesanan/${pesanan.id}/bayar', {'bayar': bayar});
      hasil = Pesanan.fromJson(Map<String, dynamic>.from(res as Map));
    });
    return ok ? hasil : null;
  }
}
