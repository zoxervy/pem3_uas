import 'json_util.dart';

class Kategori {
  const Kategori({required this.id, required this.namaKategori});

  final int id;
  final String namaKategori;

  factory Kategori.fromJson(Map<String, dynamic> j) =>
      Kategori(id: toInt(j['id']), namaKategori: toStr(j['nama_kategori']));
}
