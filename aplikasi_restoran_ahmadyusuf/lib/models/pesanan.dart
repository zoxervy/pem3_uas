import 'detail_pesanan.dart';
import 'json_util.dart';
import 'meja.dart';
import 'user.dart';

class Pesanan {
  const Pesanan({
    required this.id,
    this.kodePesanan = '',
    this.mejaId = 0,
    this.waiterId,
    this.token,
    this.kodeBayar,
    this.metodeBayar,
    this.waktuKonfirmasi,
    this.waktuAntar,
    this.kasirId,
    this.namaPelanggan,
    this.tanggal,
    this.status = 'menunggu_konfirmasi',
    this.total = 0,
    this.bayar,
    this.kembalian,
    this.waktuBayar,
    this.meja,
    this.waiter,
    this.kasir,
    this.detail = const [],
  });

  final int id;
  final String kodePesanan;
  final int mejaId;

  /// Waitress yang bertugas (null = belum ditugaskan kasir).
  final int? waiterId;

  /// Kunci pelanggan untuk melihat status pesanannya.
  final String? token;

  /// Isi QR pembayaran (muncul setelah waitress memvalidasi).
  final String? kodeBayar;
  final String? metodeBayar;
  final DateTime? waktuKonfirmasi;
  final DateTime? waktuAntar;
  final int? kasirId;
  final String? namaPelanggan;
  final DateTime? tanggal;
  final String status;
  final int total;
  final int? bayar;
  final int? kembalian;
  final DateTime? waktuBayar;
  final Meja? meja;
  final User? waiter;
  final User? kasir;
  final List<DetailPesanan> detail;

  factory Pesanan.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? peta(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;
    final meja = peta(j['meja']);
    final waiter = peta(j['waiter']);
    final kasir = peta(j['kasir']);
    return Pesanan(
      id: toInt(j['id']),
      kodePesanan: toStr(j['kode_pesanan']),
      mejaId: toInt(j['meja_id']),
      waiterId: toIntOrNull(j['waiter_id']),
      token: j['token'] == null ? null : toStr(j['token']),
      kodeBayar: j['kode_bayar'] == null ? null : toStr(j['kode_bayar']),
      metodeBayar: j['metode_bayar'] == null ? null : toStr(j['metode_bayar']),
      waktuKonfirmasi: toDate(j['waktu_konfirmasi']),
      waktuAntar: toDate(j['waktu_antar']),
      kasirId: toIntOrNull(j['kasir_id']),
      namaPelanggan: j['nama_pelanggan'] == null ? null : toStr(j['nama_pelanggan']),
      tanggal: toDate(j['tanggal']),
      status: j['status'] == null ? 'menunggu_konfirmasi' : toStr(j['status']),
      total: toInt(j['total']),
      bayar: toIntOrNull(j['bayar']),
      kembalian: toIntOrNull(j['kembalian']),
      waktuBayar: toDate(j['waktu_bayar']),
      meja: meja == null ? null : Meja.fromJson(meja),
      waiter: waiter == null ? null : User.fromJson(waiter),
      kasir: kasir == null ? null : User.fromJson(kasir),
      detail: (j['detail'] is List)
          ? (j['detail'] as List)
              .map((e) => DetailPesanan.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  /// Jumlah seluruh subtotal item.
  int hitungTotal() => detail.fold(0, (jumlah, d) => jumlah + d.subtotal);

  /// Kembalian = uang bayar - total. [uangBayar] boleh diisi untuk simulasi
  /// sebelum pembayaran dikonfirmasi; kalau kosong dipakai nilai [bayar].
  int hitungKembalian([int? uangBayar]) => (uangBayar ?? bayar ?? 0) - total;

  /// Item hanya boleh diubah sebelum waitress memvalidasi (NF-02).
  bool bisaDiubah() => status == 'menunggu_konfirmasi';

  bool get belumDitugaskan => waiterId == null && status == 'menunggu_konfirmasi';

  /// Masih berjalan (belum diantar / belum batal).
  bool get aktif => const ['menunggu_konfirmasi', 'menunggu_pembayaran', 'lunas'].contains(status);

}
