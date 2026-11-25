import 'dart:convert';

import 'package:aplikasi_restoran_ahmadyusuf/controllers/auth_controller.dart';
import 'package:aplikasi_restoran_ahmadyusuf/controllers/menu_controller.dart';
import 'package:aplikasi_restoran_ahmadyusuf/controllers/pelanggan_controller.dart';
import 'package:aplikasi_restoran_ahmadyusuf/controllers/pembayaran_controller.dart';
import 'package:aplikasi_restoran_ahmadyusuf/controllers/pesanan_controller.dart';
import 'package:aplikasi_restoran_ahmadyusuf/models/menu.dart';
import 'package:aplikasi_restoran_ahmadyusuf/models/pesanan.dart';
import 'package:aplikasi_restoran_ahmadyusuf/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server palsu: mencatat request dan menjawab sesuai [handler].
class _Server {
  _Server(this.handler);

  final http.Response Function(http.Request) handler;
  final List<http.Request> requests = [];

  ApiService get api => ApiService(
        baseUrl: 'http://test/api',
        client: MockClient((req) async {
          requests.add(req);
          return handler(req);
        }),
      );
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthController.login', () {
    test('password salah -> gagal dan muncul pesan error', () async {
      final s = _Server((r) => _json({'message': 'Username atau password salah.'}, 401));
      final auth = AuthController(s.api);

      final ok = await auth.login('admin', 'salah');

      expect(ok, isFalse);
      expect(auth.sudahLogin, isFalse);
      expect(auth.error, 'Username atau password salah.');
    });

    test('input kosong ditolak tanpa menghubungi server', () async {
      final s = _Server((r) => _json({}));
      final auth = AuthController(s.api);

      expect(await auth.login('', ''), isFalse);
      expect(auth.error, isNotNull);
      expect(s.requests, isEmpty);
    });

    test('login benar -> user & token tersimpan', () async {
      final s = _Server((r) => _json({
            'token': 'abc123',
            'user': {'id': 1, 'nama': 'Sari', 'username': 'sari', 'role': 'kasir', 'aktif': true},
          }));
      final api = s.api;
      final auth = AuthController(api);

      expect(await auth.login('sari', 'kasir123'), isTrue);
      expect(auth.user!.isKasir(), isTrue);
      expect(api.token, 'abc123');
      expect((await SharedPreferences.getInstance()).getString('token'), 'abc123');
    });

    test('logout membersihkan sesi walau server error', () async {
      final s = _Server((r) => r.url.path.endsWith('/login')
          ? _json({'token': 't', 'user': {'id': 1, 'nama': 'A', 'username': 'a', 'role': 'admin'}})
          : _json({'message': 'x'}, 500));
      final api = s.api;
      final auth = AuthController(api);
      await auth.login('a', 'secret');

      await auth.logout();

      expect(auth.sudahLogin, isFalse);
      expect(api.token, isNull);
    });
  });

  group('PembayaranController.konfirmasi', () {
    const pesanan = Pesanan(id: 5, kodePesanan: 'ORD-1', total: 45000, status: 'menunggu_pembayaran');

    test('bayar < total -> ditolak, muncul pesan error, server tidak dipanggil', () async {
      final s = _Server((r) => _json({}));
      final c = PembayaranController(s.api);

      final hasil = await c.konfirmasi(pesanan, 40000);

      expect(hasil, isNull);
      expect(c.error, contains('kurang'));
      expect(s.requests, isEmpty);
    });

    test('bayar cukup -> lunas + kembalian dari server', () async {
      final s = _Server((r) => _json({
            'id': 5, 'kode_pesanan': 'ORD-1', 'status': 'lunas', 'total': 45000, 'bayar': 50000, 'kembalian': 5000,
          }));
      final c = PembayaranController(s.api);

      final hasil = await c.konfirmasi(pesanan, 50000);

      expect(hasil!.status, 'lunas');
      expect(hasil.kembalian, 5000);
      expect(jsonDecode(s.requests.single.body), {'bayar': 50000});
    });
  });

  group('MenuController.tambah', () {
    test('harga kosong -> ditolak validasi', () async {
      final s = _Server((r) => _json({}));
      final c = MenuController(s.api);

      final ok = await c.tambah(kategoriId: 1, nama: 'Nasi Goreng', harga: '');

      expect(ok, isFalse);
      expect(c.error, 'Harga wajib diisi.');
      expect(s.requests, isEmpty);
    });

    test('nama kosong / kategori belum dipilih / harga bukan angka ditolak', () async {
      final c = MenuController(_Server((r) => _json({})).api);
      expect(await c.tambah(kategoriId: 1, nama: ' ', harga: '1000'), isFalse);
      expect(await c.tambah(kategoriId: null, nama: 'A', harga: '1000'), isFalse);
      expect(await c.tambah(kategoriId: 1, nama: 'A', harga: 'abc'), isFalse);
      expect(await c.tambah(kategoriId: 1, nama: 'A', harga: '0'), isFalse);
    });

    test('input valid -> POST /menu lalu daftar dimuat ulang', () async {
      final s = _Server((r) => r.method == 'POST'
          ? _json({'id': 1}, 201)
          : _json([
              {'id': 1, 'kategori_id': 1, 'nama_menu': 'Nasi Goreng', 'harga': 25000, 'tersedia': true},
            ]));
      final c = MenuController(s.api);

      final ok = await c.tambah(kategoriId: 1, nama: 'Nasi Goreng', harga: '25000');

      expect(ok, isTrue);
      expect(s.requests.first.method, 'POST');
      expect(jsonDecode(s.requests.first.body)['harga'], 25000);
      expect(c.daftar.single.namaMenu, 'Nasi Goreng');
    });
  });

  const nasi = Menu(id: 1, kategoriId: 1, namaMenu: 'Nasi Goreng', harga: 25000);
  const teh = Menu(id: 2, kategoriId: 2, namaMenu: 'Es Teh', harga: 5000);
  const habis = Menu(id: 3, kategoriId: 1, namaMenu: 'Soto', harga: 20000, tersedia: false);

  group('Keranjang (dipakai pelanggan & waitress)', () {
    test('total dihitung dari jumlah x harga', () {
      final c = PelangganController(_Server((r) => _json({})).api);
      c.tambahKeKeranjang(nasi);
      c.tambahKeKeranjang(nasi);
      c.tambahKeKeranjang(teh);
      expect(c.jumlahItemKeranjang, 3);
      expect(c.jumlahMenu(nasi.id), 2);
      expect(c.totalKeranjang, 55000);
    });

    test('kurangiMenu (tombol minus di kartu menu) mengurangi lalu menghapus', () {
      final c = PelangganController(_Server((r) => _json({})).api);
      c.tambahKeKeranjang(nasi);
      c.tambahKeKeranjang(nasi);
      c.kurangiMenu(nasi);
      expect(c.jumlahMenu(nasi.id), 1);
      c.kurangiMenu(nasi);
      expect(c.keranjang, isEmpty);
      c.kurangiMenu(teh);            // menu yang tidak ada di keranjang: tidak error
      expect(c.keranjang, isEmpty);
    });

    test('menu habis tidak masuk; kurangi sampai 0 menghapus item', () {
      final c = PelangganController(_Server((r) => _json({})).api);
      c.tambahKeKeranjang(habis);
      expect(c.keranjang, isEmpty);
      c.tambahKeKeranjang(teh);
      c.kurangi(c.keranjang.first);
      expect(c.keranjang, isEmpty);
    });

    test('isiKeranjangDari memakai menu yang ada, atau membuat dari detail', () {
      final c = PesananController(_Server((r) => _json({})).api);
      final p = Pesanan.fromJson({
        'id': 1,
        'detail': [
          {'menu_id': 1, 'jumlah': 2, 'harga_satuan': 25000, 'subtotal': 50000, 'catatan': 'pedas', 'menu': {'nama_menu': 'Nasi Goreng'}},
          {'menu_id': 99, 'jumlah': 1, 'harga_satuan': 7000, 'subtotal': 7000, 'menu': {'nama_menu': 'Menu Lama'}},
        ],
      });
      c.isiKeranjangDari(p, [nasi]);
      expect(c.keranjang, hasLength(2));
      expect(c.keranjang.first.catatan, 'pedas');
      expect(c.totalKeranjang, 57000);
    });
  });

  group('PelangganController (pesan lewat QR)', () {
    test('muatMenu membaca nomor meja, kategori, dan menu', () async {
      final s = _Server((r) => _json({
            'meja': {'nomor_meja': '2'},
            'kategori': [{'id': 1, 'nama_kategori': 'Makanan'}],
            'menu': [{'id': 1, 'kategori_id': 1, 'nama_menu': 'Nasi Goreng', 'harga': 25000}],
          }));
      final c = PelangganController(s.api);
      await c.muatMenu('KODEMEJA');
      expect(s.requests.single.url.path, '/api/publik/meja/KODEMEJA');
      expect(c.nomorMeja, '2');
      expect(c.menu.single.namaMenu, 'Nasi Goreng');
    });

    test('kirim dengan keranjang kosong ditolak tanpa ke server', () async {
      final s = _Server((r) => _json({}));
      final c = PelangganController(s.api);
      expect(await c.kirim('KODE'), isNull);
      expect(c.error, 'Pilih minimal satu menu.');
      expect(s.requests, isEmpty);
    });

    test('kirim mengirim item, menyimpan token, dan mengosongkan keranjang', () async {
      final s = _Server((r) => _json({'id': 9, 'kode_pesanan': 'ORD-9', 'status': 'menunggu_konfirmasi', 'total': 30000, 'token': 'tok123'}, 201));
      final c = PelangganController(s.api);
      c.tambahKeKeranjang(nasi);
      c.tambahKeKeranjang(teh);
      c.setCatatan(c.keranjang.first, 'pedas');

      final p = await c.kirim('KODE', nama: 'Andi');

      expect(p!.token, 'tok123');
      expect(c.keranjang, isEmpty);
      expect(await c.tokenTersimpan(), 'tok123');
      final body = jsonDecode(s.requests.single.body) as Map<String, dynamic>;
      expect(body['nama_pelanggan'], 'Andi');
      expect((body['items'] as List).first, {'menu_id': 1, 'jumlah': 1, 'catatan': 'pedas'});
    });

    test('error 422 dari server ditampilkan, keranjang tetap', () async {
      final s = _Server((r) => _json({'message': 'x', 'errors': {'items': ['Menu Soto sedang habis.']}}, 422));
      final c = PelangganController(s.api);
      c.tambahKeKeranjang(nasi);
      expect(await c.kirim('KODE'), isNull);
      expect(c.error, 'Menu Soto sedang habis.');
      expect(c.keranjang, hasLength(1));
    });

    test('bayar (simulasi) mengubah tagihan jadi lunas', () async {
      final s = _Server((r) => _json({'id': 9, 'status': 'lunas', 'total': 30000, 'metode_bayar': 'qris'}));
      final c = PelangganController(s.api);
      expect(await c.bayar('KODEBAYAR'), isTrue);
      expect(s.requests.single.method, 'POST');
      expect(s.requests.single.url.path, '/api/publik/bayar/KODEBAYAR');
      expect(c.tagihan!.status, 'lunas');
    });
  });

  group('PesananController (staf)', () {
    test('konfirmasi mengembalikan kode bayar lalu memuat ulang daftar', () async {
      final s = _Server((r) => r.method == 'POST'
          ? _json({'id': 5, 'status': 'menunggu_pembayaran', 'kode_bayar': 'QRBAYAR', 'total': 30000})
          : _json([]));
      final c = PesananController(s.api);

      final p = await c.konfirmasi(5);

      expect(p!.kodeBayar, 'QRBAYAR');
      expect(s.requests.first.url.path, '/api/pesanan/5/konfirmasi');
      expect(s.requests.last.url.path, '/api/pesanan');   // daftar dimuat ulang
    });

    test('tugaskan mengirim waiter_id; ditolak server -> pesan error', () async {
      final s = _Server((r) => _json({'message': 'x', 'errors': {'waiter_id': ['Waitress tidak valid.']}}, 422));
      final c = PesananController(s.api);
      expect(await c.tugaskan(5, 7), isFalse);
      expect(jsonDecode(s.requests.single.body), {'waiter_id': 7});
      expect(c.error, 'Waitress tidak valid.');
    });

    test('ubahItems dengan keranjang kosong ditolak', () async {
      final s = _Server((r) => _json({}));
      final c = PesananController(s.api);
      expect(await c.ubahItems(5), isNull);
      expect(s.requests, isEmpty);
    });
  });

  group('ApiService', () {
    test('jaringan putus -> pesan ramah, bukan exception mentah', () async {
      final api = ApiService(baseUrl: 'http://test/api', client: MockClient((_) async => throw Exception('socket')));
      expect(() => api.get('/menu'), throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('terhubung'))));
    });

    test('401 saat punya token memanggil onUnauthorized', () async {
      var dipanggil = false;
      final s = _Server((r) => _json({'message': 'Unauthenticated.'}, 401));
      final api = s.api
        ..token = 'kadaluarsa'
        ..onUnauthorized = () => dipanggil = true;

      await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
      expect(dipanggil, isTrue);
    });

    test('header Authorization terkirim dan query kosong dibuang', () async {
      final s = _Server((r) => _json([]));
      final api = s.api..token = 'tok';

      await api.get('/menu', query: {'kategori_id': null, 'x': ''});

      expect(s.requests.single.headers['Authorization'], 'Bearer tok');
      expect(s.requests.single.url.toString(), 'http://test/api/menu');
    });
  });
}
