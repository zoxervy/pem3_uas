import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../routes.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/format.dart';
import '../../widgets/refresh_on_return.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';

/// Dashboard kasir: pesanan masuk yang perlu ditugaskan + ringkasan pembayaran.
class KasirDashboardView extends StatefulWidget {
  const KasirDashboardView({super.key});

  @override
  State<KasirDashboardView> createState() => _KasirDashboardViewState();
}

class _KasirDashboardViewState extends State<KasirDashboardView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<DashboardController>().muat());
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DashboardController>();
    final masuk = d.angka('pesanan_masuk');
    return RefreshOnReturn(
      onRefresh: () => context.read<DashboardController>().muat(),
      child: HalamanScaffold(
        judul: 'Dashboard Kasir',
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
                StatCard(ikon: Icons.inbox_outlined, label: 'Pesanan baru', nilai: '$masuk', warna: const Color(0xFFB26A00)),
                StatCard(ikon: Icons.qr_code_2, label: 'Menunggu bayar', nilai: '${d.angka('menunggu_bayar')}', warna: const Color(0xFF7B1FA2)),
                StatCard(ikon: Icons.payments_outlined, label: 'Pendapatan hari ini', nilai: rupiah(d.angka('pendapatan_hari_ini')), warna: const Color(0xFF2E7D32)),
                StatCard(ikon: Icons.point_of_sale, label: 'Tunai diterima saya', nilai: rupiah(d.angka('tunai_shift')), warna: const Color(0xFF1565C0)),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.pesananMasuk),
                icon: const Icon(Icons.assignment_ind_outlined),
                label: Text(masuk == 0 ? 'Buka pesanan masuk' : 'Tugaskan $masuk pesanan baru'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.riwayat),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Riwayat transaksi'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
