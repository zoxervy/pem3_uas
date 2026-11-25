import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../models/json_util.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/format.dart';
import '../../widgets/refresh_on_return.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';

/// Halaman 2: dashboard admin (pendapatan, transaksi, menu terlaris, performa waitress).
class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<DashboardController>().muat());
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DashboardController>();
    final terlaris = d.daftar('menu_terlaris');
    final performa = d.daftar('performa_waitress');
    return RefreshOnReturn(
      onRefresh: () => context.read<DashboardController>().muat(),
      child: HalamanScaffold(
        judul: 'Dashboard Admin',
        aksi: [IconButton(onPressed: d.muat, icon: const Icon(Icons.refresh), tooltip: 'Muat ulang')],
        body: AsyncBody(
          loading: d.loading,
          error: d.error,
          onRetry: d.muat,
          isEmpty: d.data.isEmpty,
          child: RefreshIndicator(
            onRefresh: d.muat,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              StatGrid(children: [
                StatCard(
                    ikon: Icons.payments_outlined,
                    label: 'Pendapatan hari ini',
                    nilai: rupiah(d.angka('pendapatan_hari_ini')),
                    warna: const Color(0xFF2E7D32)),
                StatCard(
                    ikon: Icons.receipt_long_outlined,
                    label: 'Transaksi hari ini',
                    nilai: '${d.angka('jumlah_transaksi')}',
                    warna: const Color(0xFF1565C0)),
              ]),
              const SectionTitle('Menu terlaris'),
              Card(
                child: terlaris.isEmpty
                    ? const ListTile(title: Text('Belum ada penjualan.'))
                    : Column(children: [
                        for (var i = 0; i < terlaris.length; i++)
                          ListTile(
                            leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                            title: Text('${terlaris[i]['nama_menu']}'),
                            trailing: Text('${terlaris[i]['terjual']} terjual',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ]),
              ),
              const SectionTitle('Performa waitress hari ini'),
              Card(
                child: performa.isEmpty
                    ? const ListTile(title: Text('Belum ada transaksi hari ini.'))
                    : Column(children: [
                        for (final w in performa)
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text('${w['nama']}'),
                            subtitle: Text('${w['transaksi']} transaksi'),
                            trailing: Text(rupiah(toInt(w['total'])),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                      ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
