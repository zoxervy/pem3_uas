import 'dart:convert';

import 'package:aplikasi_restoran_ahmadyusuf/main.dart';
import 'package:aplikasi_restoran_ahmadyusuf/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tanpa sesi -> tampil halaman login; login salah menampilkan pesan', (tester) async {
    final api = ApiService(
      baseUrl: 'http://test/api',
      client: MockClient((req) async => _json({'message': 'Username atau password salah.'}, 401)),
    );
    await tester.pumpWidget(AplikasiRestoran(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Aplikasi Restoran'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);

    // kosong -> validasi lokal
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Username dan password wajib diisi.'), findsOneWidget);

    // salah -> pesan dari server
    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.enterText(find.byType(TextField).last, 'salah');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Username atau password salah.'), findsOneWidget);
  });

  testWidgets('login kasir -> masuk dashboard kasir', (tester) async {
    final api = ApiService(
      baseUrl: 'http://test/api',
      client: MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/login')) {
          return _json({
            'token': 't',
            'user': {'id': 4, 'nama': 'Sari', 'username': 'sari', 'role': 'kasir', 'aktif': true},
          });
        }
        if (p.endsWith('/dashboard')) {
          return _json({'role': 'kasir', 'pesanan_masuk': 2, 'menunggu_bayar': 1, 'pendapatan_hari_ini': 120000, 'tunai_shift': 0, 'transaksi_hari_ini': 3});
        }
        return _json({'message': 'x'}, 404);
      }),
    );
    await tester.pumpWidget(AplikasiRestoran(api: api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'sari');
    await tester.enterText(find.byType(TextField).last, 'kasir123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Kasir'), findsOneWidget);
    expect(find.text('Rp 120.000'), findsOneWidget);
    expect(find.textContaining('Tugaskan 2 pesanan baru'), findsOneWidget);
  });

  testWidgets('dashboard admin tetap tampil walau angka dari server berupa teks (MariaDB SUM)', (tester) async {
    final api = ApiService(
      baseUrl: 'http://test/api',
      client: MockClient((req) async {
        final p = req.url.path;
        if (p.endsWith('/login')) {
          return _json({'token': 't', 'user': {'id': 1, 'nama': 'Administrator', 'username': 'admin', 'role': 'admin', 'aktif': true}});
        }
        if (p.endsWith('/dashboard')) {
          return _json({
            'role': 'admin', 'pendapatan_hari_ini': 55000, 'jumlah_transaksi': 1,
            'menu_terlaris': [{'nama_menu': 'Nasi Goreng', 'terjual': '2'}],
            'performa_waitress': [{'nama': 'Rina', 'transaksi': 1, 'total': '55000'}],
          });
        }
        return _json({'message': 'x'}, 404);
      }),
    );
    await tester.pumpWidget(AplikasiRestoran(api: api));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'admin');
    await tester.enterText(find.byType(TextField).last, 'admin123');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard Admin'), findsOneWidget);
    expect(find.text('Rina'), findsOneWidget);
    expect(find.text('Rp 55.000'), findsWidgets);
  });
}
