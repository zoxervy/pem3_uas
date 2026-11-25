import 'json_util.dart';

class Meja {
  const Meja({
    required this.id,
    required this.nomorMeja,
    this.kapasitas,
    this.status = 'kosong',
    this.kodeQr,
  });

  final int id;
  final String nomorMeja;
  final int? kapasitas;
  final String status;

  /// Isi QR meja (hanya dikirim server ke admin).
  final String? kodeQr;

  factory Meja.fromJson(Map<String, dynamic> j) => Meja(
        id: toInt(j['id']),
        nomorMeja: toStr(j['nomor_meja']),
        kapasitas: toIntOrNull(j['kapasitas']),
        status: j['status'] == null ? 'kosong' : toStr(j['status']),
        kodeQr: j['kode_qr'] == null ? null : toStr(j['kode_qr']),
      );

  bool isKosong() => status == 'kosong';
}
