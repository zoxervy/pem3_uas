import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../routes.dart';
import '../ui.dart';
import 'dialogs.dart';

class _Item {
  const _Item(this.ikon, this.label, this.route);
  final IconData ikon;
  final String label;
  final String route;
}

/// Menu samping; isinya menyesuaikan role pengguna yang login.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  List<_Item> _itemUntuk(String role) {
    const dashboard = _Item(Icons.dashboard_outlined, 'Dashboard', AppRoutes.dashboard);
    return switch (role) {
      'admin' => const [
          dashboard,
          _Item(Icons.category_outlined, 'Kategori', AppRoutes.kategori),
          _Item(Icons.restaurant_menu, 'Menu', AppRoutes.menu),
          _Item(Icons.table_restaurant_outlined, 'Meja', AppRoutes.meja),
          _Item(Icons.qr_code_2, 'QR Meja', AppRoutes.qrMeja),
          _Item(Icons.people_outline, 'User', AppRoutes.user),
          _Item(Icons.receipt_long_outlined, 'Riwayat Transaksi', AppRoutes.riwayat),
          _Item(Icons.bar_chart, 'Laporan Penjualan', AppRoutes.laporan),
          _Item(Icons.history, 'Log Aktivitas', AppRoutes.log),
        ],
      'waitress' => const [
          dashboard,
          _Item(Icons.assignment_outlined, 'Tugas Saya', AppRoutes.tugas),
        ],
      _ => const [
          dashboard,
          _Item(Icons.inbox_outlined, 'Pesanan Masuk', AppRoutes.pesananMasuk),
          _Item(Icons.receipt_long_outlined, 'Riwayat Transaksi', AppRoutes.riwayat),
        ],
    };
  }

  void _buka(BuildContext context, String route) {
    final nav = Navigator.of(context);
    nav.pop(); // tutup drawer
    if (route == AppRoutes.dashboard) {
      nav.popUntil((r) => r.isFirst);
    } else {
      nav.pushNamedAndRemoveUntil(route, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    final saatIni = ModalRoute.of(context)?.settings.name;
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.nama ?? '-'),
            accountEmail: Text('${user?.labelRole ?? ''} · @${user?.username ?? ''}'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text((user?.nama ?? '?').characters.first.toUpperCase(),
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          Expanded(
            child: ListView(children: [
              for (final item in _itemUntuk(user?.role ?? ''))
                ListTile(
                  leading: Icon(item.ikon),
                  title: Text(item.label),
                  selected: (saatIni ?? AppRoutes.dashboard) == item.route,
                  onTap: () => _buka(context, item.route),
                ),
            ]),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              final ya = await konfirmasi(context,
                  judul: 'Logout', isi: 'Keluar dari akun ini?', tombol: 'Logout');
              if (ya && context.mounted) {
                Navigator.of(context).pop();
                await auth.logout();
              }
            },
          ),
        ]),
      ),
    );
  }
}
