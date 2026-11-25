import 'json_util.dart';

class Menu {
  const Menu({
    required this.id,
    required this.kategoriId,
    required this.namaMenu,
    required this.harga,
    this.deskripsi,
    this.foto,
    this.tersedia = true,
    this.namaKategori,
  });

  final int id;
  final int kategoriId;
  final String namaMenu;
  final int harga;
  final String? deskripsi;
  final String? foto;
  final bool tersedia;
  final String? namaKategori;

  factory Menu.fromJson(Map<String, dynamic> j) {
    final kat = j['kategori'];
    return Menu(
      id: toInt(j['id']),
      kategoriId: toInt(j['kategori_id']),
      namaMenu: toStr(j['nama_menu']),
      harga: toInt(j['harga']),
      deskripsi: j['deskripsi'] == null ? null : toStr(j['deskripsi']),
      foto: j['foto'] == null ? null : toStr(j['foto']),
      tersedia: j['tersedia'] == null ? true : toBool(j['tersedia']),
      namaKategori: kat is Map ? toStr(kat['nama_kategori']) : null,
    );
  }
}
