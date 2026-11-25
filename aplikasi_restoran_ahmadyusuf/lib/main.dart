import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/kategori_controller.dart';
import 'controllers/laporan_controller.dart';
import 'controllers/log_controller.dart';
import 'controllers/meja_controller.dart';
import 'controllers/menu_controller.dart';
import 'controllers/pelanggan_controller.dart';
import 'controllers/pembayaran_controller.dart';
import 'controllers/pesanan_controller.dart';
import 'controllers/user_controller.dart';
import 'routes.dart';
import 'services/api_service.dart';
import 'ui.dart';
import 'views/auth/login_view.dart';
import 'views/dashboard/admin_dashboard_view.dart';
import 'views/dashboard/kasir_dashboard_view.dart';
import 'views/dashboard/waitress_dashboard_view.dart';
import 'views/pelanggan/bayar_view.dart';
import 'views/pelanggan/menu_pelanggan_view.dart';

// Catatan performa: pohon aksesibilitas TIDAK dipaksa aktif (berat saat scroll di HP).
// Flutter web tetap menyediakan tombol "Enable accessibility" untuk pembaca layar.
void main() => runApp(const AplikasiRestoran());

class AplikasiRestoran extends StatefulWidget {
  const AplikasiRestoran({super.key, this.api});

  /// Boleh diganti saat testing (mis. ApiService dengan MockClient).
  final ApiService? api;

  @override
  State<AplikasiRestoran> createState() => _AplikasiRestoranState();
}

class _AplikasiRestoranState extends State<AplikasiRestoran> {
  late final ApiService _api = widget.api ?? ApiService();
  late final AuthController _auth = AuthController(_api);
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _adaUser = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_pantauSesi);
    _auth.pulihkanSesi();
  }

  /// Kalau sesi berakhir / logout, tutup semua halaman dan kembali ke login.
  void _pantauSesi() {
    final ada = _auth.sudahLogin;
    if (_adaUser && !ada) _navKey.currentState?.popUntil((r) => r.isFirst);
    _adaUser = ada;
  }

  @override
  void dispose() {
    _auth.removeListener(_pantauSesi);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _auth),
        ChangeNotifierProvider(create: (_) => DashboardController(_api)),
        ChangeNotifierProvider(create: (_) => KategoriController(_api)),
        ChangeNotifierProvider(create: (_) => MenuController(_api)),
        ChangeNotifierProvider(create: (_) => MejaController(_api)),
        ChangeNotifierProvider(create: (_) => UserController(_api)),
        ChangeNotifierProvider(create: (_) => PesananController(_api)),
        ChangeNotifierProvider(create: (_) => PembayaranController(_api)),
        ChangeNotifierProvider(create: (_) => LaporanController(_api)),
        ChangeNotifierProvider(create: (_) => LogController(_api)),
        ChangeNotifierProvider(create: (_) => PelangganController(_api)),
      ],
      child: MaterialApp(
        title: 'Aplikasi Restoran',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navKey,
        navigatorObservers: [routeObserver],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD35400)),
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
          // tanpa bayangan: lebih ringan digambar di HP
          cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
          // AppBar tidak berubah warna saat konten di-scroll (hemat gambar ulang)
          appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
        ),
        home: _halamanAwal(),
        onGenerateRoute: (settings) => AppRoutes.generate(settings, _auth),
      ),
    );
  }
}

/// Link dari QR: ?meja=KODE (menu pelanggan) atau ?bayar=KODE (halaman bayar). Selain itu: staf.
Widget _halamanAwal() {
  final q = Uri.base.queryParameters;
  if ((q['bayar'] ?? '').isNotEmpty) return BayarView(kodeBayar: q['bayar']!);
  if ((q['meja'] ?? '').isNotEmpty) return MenuPelangganView(kodeMeja: q['meja']!);
  return const AuthGate();
}

/// Penentu halaman awal: cek sesi -> login, atau dashboard sesuai role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.sudahCekSesi) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.sudahLogin) return const LoginView();
    return switch (auth.user!.role) {
      'admin' => const AdminDashboardView(),
      'waitress' => const WaitressDashboardView(),
      _ => const KasirDashboardView(),
    };
  }
}
