import 'controllers/auth_controller.dart';
import 'models/menu.dart';
import 'models/pesanan.dart';
import 'ui.dart';
import 'views/admin/kategori_view.dart';
import 'views/admin/laporan_view.dart';
import 'views/admin/log_aktivitas_view.dart';
import 'views/admin/meja_view.dart';
import 'views/admin/menu_form_view.dart';
import 'views/admin/menu_view.dart';
import 'views/admin/qr_meja_view.dart';
import 'views/admin/user_view.dart';
import 'views/kasir/pembayaran_view.dart';
import 'views/kasir/pesanan_masuk_view.dart';
import 'views/kasir/riwayat_view.dart';
import 'views/waitress/pesanan_form_view.dart';
import 'views/waitress/tugas_view.dart';

/// Pengamat navigasi: dipakai [RefreshOnReturn] untuk memuat ulang dashboard.
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

/// Daftar route + pengecekan role. Halaman utama (dashboard) = home "/" di AuthGate.
class AppRoutes {
  static const dashboard = '/';
  static const kategori = '/kategori';
  static const menu = '/menu';
  static const menuForm = '/menu/form';
  static const meja = '/meja';
  static const qrMeja = '/qr-meja';
  static const user = '/user';
  static const laporan = '/laporan';
  static const log = '/log';
  static const tugas = '/tugas';
  static const pesananForm = '/pesanan/form';
  static const pesananMasuk = '/pesanan-masuk';
  static const pembayaran = '/pembayaran';
  static const riwayat = '/riwayat';

  /// Route -> role yang boleh membukanya.
  static const Map<String, Set<String>> akses = {
    kategori: {'admin'},
    menu: {'admin'},
    menuForm: {'admin'},
    meja: {'admin'},
    qrMeja: {'admin'},
    user: {'admin'},
    laporan: {'admin'},
    log: {'admin'},
    tugas: {'waitress'},
    pesananForm: {'waitress'},
    pesananMasuk: {'kasir'},
    pembayaran: {'kasir'},
    riwayat: {'admin', 'kasir'},
  };

  static bool boleh(String route, String? role) =>
      role != null && (akses[route]?.contains(role) ?? false);

  static Route<dynamic> generate(RouteSettings settings, AuthController auth) {
    final nama = settings.name ?? '';
    if (!boleh(nama, auth.user?.role)) {
      return MaterialPageRoute(settings: settings, builder: (_) => const AksesDitolakView());
    }
    final Widget halaman = switch (nama) {
      kategori => const KategoriView(),
      menu => const MenuView(),
      menuForm => MenuFormView(menu: settings.arguments as Menu?),
      meja => const MejaView(),
      qrMeja => const QrMejaView(),
      user => const UserView(),
      laporan => const LaporanView(),
      log => const LogAktivitasView(),
      tugas => const TugasView(),
      pesananForm => settings.arguments is PesananFormArgs
          ? PesananFormView(args: settings.arguments as PesananFormArgs)
          : const HalamanTidakLangsungView(),
      pesananMasuk => const PesananMasukView(),
      pembayaran => settings.arguments is Pesanan
          ? PembayaranView(pesanan: settings.arguments as Pesanan)
          : const HalamanTidakLangsungView(),
      riwayat => const RiwayatView(),
      _ => const AksesDitolakView(),
    };
    return MaterialPageRoute(settings: settings, builder: (_) => halaman);
  }
}

/// Halaman yang perlu data dari halaman sebelumnya tapi dibuka langsung (mis. setelah refresh).
class HalamanTidakLangsungView extends StatelessWidget {
  const HalamanTidakLangsungView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Halaman tidak tersedia')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Halaman ini harus dibuka dari daftar pesanan.', textAlign: TextAlign.center),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Kembali ke dashboard'),
            ),
          ]),
        ),
      );
}

class AksesDitolakView extends StatelessWidget {
  const AksesDitolakView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Akses ditolak')),
        body: const Center(child: Text('Anda tidak punya akses ke halaman ini.')),
      );
}
