import 'json_util.dart';

class LogAktivitas {
  const LogAktivitas({
    required this.id,
    required this.userId,
    this.pesananId,
    required this.aksi,
    this.keterangan = '',
    this.waktu,
    this.namaUser = '',
    this.roleUser = '',
    this.kodePesanan,
  });

  final int id;
  final int userId;
  final int? pesananId;
  final String aksi;
  final String keterangan;
  final DateTime? waktu;
  final String namaUser;
  final String roleUser;
  final String? kodePesanan;

  factory LogAktivitas.fromJson(Map<String, dynamic> j) {
    final user = j['user'];
    final pesanan = j['pesanan'];
    return LogAktivitas(
      id: toInt(j['id']),
      userId: toInt(j['user_id']),
      pesananId: toIntOrNull(j['pesanan_id']),
      aksi: toStr(j['aksi']),
      keterangan: toStr(j['keterangan']),
      waktu: toDate(j['waktu']),
      namaUser: user is Map ? toStr(user['nama']) : '',
      roleUser: user is Map ? toStr(user['role']) : '',
      kodePesanan: pesanan is Map ? toStr(pesanan['kode_pesanan']) : null,
    );
  }
}
