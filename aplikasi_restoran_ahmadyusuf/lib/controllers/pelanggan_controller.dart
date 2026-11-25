import 'package:shared_preferences/shared_preferences.dart';

import '../models/kategori.dart';
import '../models/menu.dart';
import '../models/pesanan.dart';
import '../services/api_service.dart';
import 'base_controller.dart';
import 'keranjang.dart';

export 'keranjang.dart' show ItemKeranjang;

/// Sisi pelanggan (tanpa login): menu dari QR meja, kirim pesanan,
/// pantau status, dan halaman bayar dari QR pembayaran.
class PelangganController extends BaseController with KeranjangMixin {
  PelangganController(super.api);

  static const _kunciToken = 'pesanan_token';

  String? nomorMeja;
  List<Kategori> kategori = [];
  List<Menu> menu = [];

  /// Pesanan yang sedang dipantau di HP pelanggan.
  Pesanan? pesanan;

  /// Tagihan yang dibuka dari QR pembayaran.
  Pesanan? tagihan;

  Pesanan _pesanan(dynamic res) => Pesanan.fromJson(Map<String, dynamic>.from(res as Map));

  Future<void> muatMenu(String kodeMeja) => jalankan(() async {
        final res = Map<String, dynamic>.from(await api.get('/publik/meja/$kodeMeja') as Map);
        nomorMeja = '${(res['meja'] as Map)['nomor_meja']}';
        kategori = (res['kategori'] as List)
            .map((e) => Kategori.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        menu = (res['menu'] as List).map((e) => Menu.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      });

  /// Kirim pesanan; token disimpan supaya status bisa dibuka lagi setelah halaman dimuat ulang.
  Future<Pesanan?> kirim(String kodeMeja, {String? nama}) async {
    if (keranjang.isEmpty) {
      tolak('Pilih minimal satu menu.');
      return null;
    }
    Pesanan? hasil;
    final ok = await jalankan(() async {
      hasil = _pesanan(await api.post('/publik/meja/$kodeMeja/pesanan', {
        'nama_pelanggan': (nama == null || nama.trim().isEmpty) ? null : nama.trim(),
        'items': payloadItems,
      }));
    });
    if (!ok) return null;
    pesanan = hasil;
    kosongkanKeranjang();
    await _simpanToken(hasil!.token);
    return hasil;
  }

  /// Ambil status terbaru tanpa mengubah [loading] (dipakai polling tiap beberapa detik).
  Future<void> segarkanStatus(String token) async {
    try {
      pesanan = _pesanan(await api.get('/publik/pesanan/$token'));
      error = null;
    } on ApiException catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  Future<String?> tokenTersimpan() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_kunciToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> _simpanToken(String? token) async {
    if (token == null) return;
    try {
      await (await SharedPreferences.getInstance()).setString(_kunciToken, token);
    } catch (_) {}
  }

  Future<void> muatTagihan(String kodeBayar) => jalankan(() async {
        tagihan = _pesanan(await api.get('/publik/bayar/$kodeBayar'));
      });

  /// Bayar (mode simulasi QRIS).
  Future<bool> bayar(String kodeBayar) => jalankan(() async {
        tagihan = _pesanan(await api.post('/publik/bayar/$kodeBayar'));
      });
}
