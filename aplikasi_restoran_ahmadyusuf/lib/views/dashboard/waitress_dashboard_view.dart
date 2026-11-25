import 'package:provider/provider.dart';

import '../../controllers/dashboard_controller.dart';
import '../../models/meja.dart';
import '../../routes.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/refresh_on_return.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart';

/// Dashboard waitress: ringkasan tugas + status meja.
class WaitressDashboardView extends StatefulWidget {
  const WaitressDashboardView({super.key});

  @override
  State<WaitressDashboardView> createState() => _WaitressDashboardViewState();
}

class _WaitressDashboardViewState extends State<WaitressDashboardView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<DashboardController>().muat());
  }

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DashboardController>();
    final meja = d.daftar('meja').map(Meja.fromJson).toList();
    return RefreshOnReturn(
      onRefresh: () => context.read<DashboardController>().muat(),
      child: HalamanScaffold(
        judul: 'Dashboard Waitress',
        aksi: [IconButton(onPressed: d.muat, icon: const Icon(Icons.refresh), tooltip: 'Muat ulang')],
        fab: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.tugas),
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Buka tugas saya'),
        ),
        body: AsyncBody(
          loading: d.loading,
          error: d.error,
          onRetry: d.muat,
          isEmpty: d.data.isEmpty,
          child: RefreshIndicator(
            onRefresh: d.muat,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 88), children: [
              StatGrid(children: [
                StatCard(ikon: Icons.fact_check_outlined, label: 'Perlu validasi', nilai: '${d.angka('perlu_validasi')}', warna: const Color(0xFFB26A00)),
                StatCard(ikon: Icons.qr_code_2, label: 'Menunggu bayar', nilai: '${d.angka('menunggu_bayar')}', warna: const Color(0xFF7B1FA2)),
                StatCard(ikon: Icons.room_service_outlined, label: 'Siap diantar', nilai: '${d.angka('siap_antar')}', warna: const Color(0xFF1565C0)),
                StatCard(ikon: Icons.inbox_outlined, label: 'Belum ditugaskan', nilai: '${d.angka('belum_ditugaskan')}', warna: const Color(0xFF546E7A)),
              ]),
              const SectionTitle('Status meja'),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final m in meja)
                  Semantics(
                    label: 'Meja ${m.nomorMeja}, ${StatusChip.label(m.status)}',
                    excludeSemantics: true,
                    child: Container(
                      width: 96,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: StatusChip.warna(m.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: StatusChip.warna(m.status)),
                      ),
                      child: Column(children: [
                        Text(m.nomorMeja,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: StatusChip.warnaTeks(m.status))),
                        Text(StatusChip.label(m.status), style: TextStyle(fontSize: 12, color: StatusChip.warnaTeks(m.status))),
                      ]),
                    ),
                  ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
