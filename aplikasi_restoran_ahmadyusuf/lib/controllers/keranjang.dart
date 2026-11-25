import 'package:flutter/foundation.dart';

import '../models/menu.dart';
import '../models/pesanan.dart';

/// Satu baris di keranjang sebelum pesanan dikirim / disimpan.
class ItemKeranjang {
  ItemKeranjang(this.menu, {this.jumlah = 1, this.catatan = ''});

  final Menu menu;
  int jumlah;
  String catatan;

  int get subtotal => jumlah * menu.harga;
}

/// Logika keranjang yang dipakai bersama oleh pelanggan (pesan lewat QR)
/// dan waitress (mengubah item saat validasi).
mixin KeranjangMixin on ChangeNotifier {
  final List<ItemKeranjang> keranjang = [];

  int get totalKeranjang => keranjang.fold(0, (s, i) => s + i.subtotal);
  int get jumlahItemKeranjang => keranjang.fold(0, (s, i) => s + i.jumlah);

  int jumlahMenu(int menuId) =>
      keranjang.where((e) => e.menu.id == menuId).fold(0, (s, e) => s + e.jumlah);

  void tambahKeKeranjang(Menu menu) {
    if (!menu.tersedia) return;
    final i = keranjang.indexWhere((e) => e.menu.id == menu.id);
    if (i >= 0) {
      keranjang[i].jumlah++;
    } else {
      keranjang.add(ItemKeranjang(menu));
    }
    notifyListeners();
  }

  void kurangi(ItemKeranjang item) {
    if (item.jumlah > 1) {
      item.jumlah--;
    } else {
      keranjang.remove(item);
    }
    notifyListeners();
  }

  /// Kurangi satu porsi menu tertentu (tombol "−" di kartu menu).
  void kurangiMenu(Menu menu) {
    final item = keranjang.where((e) => e.menu.id == menu.id).firstOrNull;
    if (item != null) kurangi(item);
  }

  void setCatatan(ItemKeranjang item, String teks) {
    item.catatan = teks;
    notifyListeners();
  }

  void kosongkanKeranjang() {
    keranjang.clear();
    notifyListeners();
  }

  /// Isi keranjang dari pesanan yang sudah ada (untuk mengubah item).
  void isiKeranjangDari(Pesanan pesanan, List<Menu> semuaMenu) {
    keranjang.clear();
    for (final d in pesanan.detail) {
      final menu = semuaMenu.where((m) => m.id == d.menuId).firstOrNull ??
          Menu(id: d.menuId, kategoriId: 0, namaMenu: d.namaMenu, harga: d.hargaSatuan);
      keranjang.add(ItemKeranjang(menu, jumlah: d.jumlah, catatan: d.catatan ?? ''));
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> get payloadItems => keranjang
      .map((i) => {
            'menu_id': i.menu.id,
            'jumlah': i.jumlah,
            'catatan': i.catatan.trim().isEmpty ? null : i.catatan.trim(),
          })
      .toList();
}
