import 'package:aplikasi_restoran_ahmadyusuf/models/detail_pesanan.dart';
import 'package:aplikasi_restoran_ahmadyusuf/models/meja.dart';
import 'package:aplikasi_restoran_ahmadyusuf/models/menu.dart';
import 'package:aplikasi_restoran_ahmadyusuf/models/pesanan.dart';
import 'package:aplikasi_restoran_ahmadyusuf/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DetailPesanan', () {
    test('hitungSubtotal: jumlah 2, harga 15000 -> 30000', () {
      const d = DetailPesanan(menuId: 1, jumlah: 2, hargaSatuan: 15000, subtotal: 0);
      expect(d.hitungSubtotal(), 30000);
    });
  });

  group('Pesanan', () {
    const detail = [
      DetailPesanan(menuId: 1, jumlah: 3, hargaSatuan: 10000, subtotal: 30000),
      DetailPesanan(menuId: 2, jumlah: 1, hargaSatuan: 10000, subtotal: 10000),
      DetailPesanan(menuId: 3, jumlah: 1, hargaSatuan: 5000, subtotal: 5000),
    ];

    test('hitungTotal: 3 item subtotal 30000, 10000, 5000 -> 45000', () {
      expect(const Pesanan(id: 1, detail: detail).hitungTotal(), 45000);
    });

    test('hitungKembalian: total 45000, bayar 50000 -> 5000', () {
      const p = Pesanan(id: 1, total: 45000, bayar: 50000);
      expect(p.hitungKembalian(), 5000);
      expect(p.hitungKembalian(100000), 55000); // simulasi uang lain
    });

    test('bisaDiubah: hanya sebelum divalidasi waitress; lunas tidak bisa diubah (NF-02)', () {
      expect(const Pesanan(id: 1, status: 'menunggu_konfirmasi').bisaDiubah(), isTrue);
      for (final st in ['menunggu_pembayaran', 'lunas', 'disajikan', 'batal']) {
        expect(Pesanan(id: 1, status: st).bisaDiubah(), isFalse, reason: st);
      }
    });

    test('belumDitugaskan & aktif', () {
      expect(const Pesanan(id: 1, status: 'menunggu_konfirmasi').belumDitugaskan, isTrue);
      expect(const Pesanan(id: 1, status: 'menunggu_konfirmasi', waiterId: 2).belumDitugaskan, isFalse);
      expect(const Pesanan(id: 1, status: 'lunas').aktif, isTrue);
      expect(const Pesanan(id: 1, status: 'disajikan').aktif, isFalse);
    });

    test('fromJson membaca relasi dan angka dengan benar', () {
      final p = Pesanan.fromJson({
        'id': 7,
        'kode_pesanan': 'ORD-20261124-001',
        'meja_id': 3,
        'waiter_id': 2,
        'kasir_id': null,
        'status': 'menunggu_konfirmasi',
        'kode_bayar': 'abc',
        'total': '60000', // server bisa mengirim string
        'tanggal': '2026-11-24T08:00:00.000000Z',
        'meja': {'id': 3, 'nomor_meja': '3', 'kapasitas': 4, 'status': 'terisi'},
        'waiter': {'id': 2, 'nama': 'Rina', 'username': 'rina', 'role': 'waitress', 'aktif': true},
        'detail': [
          {'id': 1, 'pesanan_id': 7, 'menu_id': 1, 'jumlah': 2, 'harga_satuan': 25000, 'subtotal': 50000, 'menu': {'nama_menu': 'Nasi Goreng'}},
        ],
      });
      expect(p.total, 60000);
      expect(p.kasirId, isNull);
      expect(p.kodeBayar, 'abc');
      expect(p.meja!.isKosong(), isFalse);
      expect(p.waiter!.nama, 'Rina');
      expect(p.detail.single.namaMenu, 'Nasi Goreng');
      expect(p.tanggal, isNotNull);
    });
  });

  group('Meja', () {
    test('isKosong: status terisi -> false', () {
      expect(const Meja(id: 1, nomorMeja: '1', status: 'terisi').isKosong(), isFalse);
      expect(const Meja(id: 1, nomorMeja: '1').isKosong(), isTrue);
    });
  });

  group('User', () {
    test('isKasir: role waitress -> false', () {
      const u = User(id: 1, nama: 'Rina', username: 'rina', role: 'waitress');
      expect(u.isKasir(), isFalse);
      expect(u.isWaitress(), isTrue);
      expect(u.isAdmin(), isFalse);
    });

    test('fromJson / toJson', () {
      final u = User.fromJson({'id': 1, 'nama': 'A', 'username': 'a', 'role': 'admin', 'aktif': 1});
      expect(u.aktif, isTrue);
      expect(u.toJson()['role'], 'admin');
    });
  });

  group('Menu', () {
    test('fromJson membaca nama kategori', () {
      final m = Menu.fromJson({
        'id': 1, 'kategori_id': 2, 'nama_menu': 'Es Teh', 'harga': 5000, 'tersedia': false,
        'kategori': {'id': 2, 'nama_kategori': 'Minuman'},
      });
      expect(m.namaKategori, 'Minuman');
      expect(m.tersedia, isFalse);
    });
  });
}
