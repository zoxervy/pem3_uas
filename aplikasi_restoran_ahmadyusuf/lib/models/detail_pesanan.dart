import 'json_util.dart';

/// Satu baris item dalam pesanan.
class DetailPesanan {
  const DetailPesanan({
    this.id = 0,
    this.pesananId = 0,
    required this.menuId,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
    this.catatan,
    this.namaMenu = '',
  });

  final int id;
  final int pesananId;
  final int menuId;
  final int jumlah;
  final int hargaSatuan;
  final int subtotal;
  final String? catatan;
  final String namaMenu;

  factory DetailPesanan.fromJson(Map<String, dynamic> j) {
    final menu = j['menu'];
    return DetailPesanan(
      id: toInt(j['id']),
      pesananId: toInt(j['pesanan_id']),
      menuId: toInt(j['menu_id']),
      jumlah: toInt(j['jumlah']),
      hargaSatuan: toInt(j['harga_satuan']),
      subtotal: toInt(j['subtotal']),
      catatan: j['catatan'] == null ? null : toStr(j['catatan']),
      namaMenu: menu is Map ? toStr(menu['nama_menu']) : '',
    );
  }

  /// jumlah x harga satuan.
  int hitungSubtotal() => jumlah * hargaSatuan;
}
