import 'package:intl/intl.dart';

import '../models/json_util.dart';
import 'base_controller.dart';

/// F-13: laporan penjualan per periode, per waitress, dan per menu.
class LaporanController extends BaseController {
  LaporanController(super.api);

  Map<String, dynamic> data = {};

  static final _tgl = DateFormat('yyyy-MM-dd');

  Future<void> muat({DateTime? dari, DateTime? sampai}) => jalankan(() async {
        final res = await api.get('/laporan/penjualan', query: {
          'dari': dari == null ? null : _tgl.format(dari),
          'sampai': sampai == null ? null : _tgl.format(sampai),
        });
        data = Map<String, dynamic>.from(res as Map);
      });

  int get totalPendapatan => toInt(data['total_pendapatan']);
  int get jumlahTransaksi => toInt(data['jumlah_transaksi']);

  List<Map<String, dynamic>> daftar(String kunci) => (data[kunci] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}
