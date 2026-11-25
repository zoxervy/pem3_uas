import 'package:intl/intl.dart';

import '../models/json_util.dart';
import '../models/log_aktivitas.dart';
import 'base_controller.dart';

/// F-15: log aktivitas karyawan dengan filter user & tanggal (paginasi).
class LogController extends BaseController {
  LogController(super.api);

  final List<LogAktivitas> items = [];
  int _halaman = 0;
  int _halamanTerakhir = 1;

  int? userId;
  DateTime? dari;
  DateTime? sampai;

  bool get adaLagi => _halaman < _halamanTerakhir;

  static final _tgl = DateFormat('yyyy-MM-dd');

  Future<void> muat() {
    items.clear();
    _halaman = 0;
    _halamanTerakhir = 1;
    return muatLagi();
  }

  Future<void> muatLagi() => jalankan(() async {
        final res = await api.get('/log-aktivitas', query: {
          'page': _halaman + 1,
          'user_id': userId,
          'dari': dari == null ? null : _tgl.format(dari!),
          'sampai': sampai == null ? null : _tgl.format(sampai!),
        });
        final peta = Map<String, dynamic>.from(res as Map);
        items.addAll((peta['data'] as List)
            .map((e) => LogAktivitas.fromJson(Map<String, dynamic>.from(e as Map))));
        _halaman = toInt(peta['current_page']);
        _halamanTerakhir = toInt(peta['last_page']);
      });

  void setFilter({int? user, DateTime? tglDari, DateTime? tglSampai}) {
    userId = user;
    dari = tglDari;
    sampai = tglSampai;
  }
}
