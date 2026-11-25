import 'package:provider/provider.dart';

import '../../controllers/laporan_controller.dart';
import '../../models/json_util.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/format.dart';
import '../../widgets/state_views.dart';
import '../../widgets/stat_card.dart';

/// Halaman 7: laporan penjualan per periode, per waitress, dan per menu.
class LaporanView extends StatefulWidget {
  const LaporanView({super.key});

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  late DateTimeRange _periode = DateTimeRange(start: _hariIni(), end: _hariIni());

  static DateTime _hariIni() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    setelahBuild(() => _muat());
  }

  Future<void> _muat() =>
      context.read<LaporanController>().muat(dari: _periode.start, sampai: _periode.end);

  Future<void> _pilihPeriode() async {
    final hasil = await pilihPeriode(context, _periode);
    if (hasil == null) return;
    setState(() => _periode = hasil);
    _muat();
  }

  void _pintas(int hari) {
    final akhir = _hariIni();
    setState(() => _periode = DateTimeRange(start: akhir.subtract(Duration(days: hari)), end: akhir));
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LaporanController>();
    final waitress = c.daftar('per_waitress');
    final menu = c.daftar('per_menu');
    return HalamanScaffold(
      judul: 'Laporan Penjualan',
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: _muat,
        isEmpty: c.data.isEmpty,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: _pilihPeriode,
              icon: const Icon(Icons.date_range),
              label: Text(_periode.start == _periode.end
                  ? tanggalSaja(_periode.start)
                  : '${tanggalSaja(_periode.start)} - ${tanggalSaja(_periode.end)}'),
            ),
            ActionChip(label: const Text('Hari ini'), onPressed: () => _pintas(0)),
            ActionChip(label: const Text('7 hari'), onPressed: () => _pintas(6)),
            ActionChip(label: const Text('30 hari'), onPressed: () => _pintas(29)),
          ]),
          const SizedBox(height: 16),
          StatGrid(children: [
            StatCard(
                ikon: Icons.payments_outlined,
                label: 'Total pendapatan',
                nilai: rupiah(c.totalPendapatan),
                warna: const Color(0xFF2E7D32)),
            StatCard(
                ikon: Icons.receipt_long_outlined,
                label: 'Jumlah transaksi',
                nilai: '${c.jumlahTransaksi}',
                warna: const Color(0xFF1565C0)),
          ]),
          const SectionTitle('Penjualan per waitress'),
          Card(
            child: waitress.isEmpty
                ? const ListTile(title: Text('Tidak ada transaksi pada periode ini.'))
                : Column(children: [
                    for (final w in waitress)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text('${w['nama']}'),
                        subtitle: Text('${w['jumlah_transaksi']} transaksi'),
                        trailing: Text(rupiah(toInt(w['total'])),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ]),
          ),
          const SectionTitle('Penjualan per menu'),
          Card(
            child: menu.isEmpty
                ? const ListTile(title: Text('Tidak ada penjualan pada periode ini.'))
                : Column(children: [
                    for (final m in menu)
                      ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text('${m['nama_menu']}'),
                        subtitle: Text('${m['terjual']} porsi terjual'),
                        trailing: Text(rupiah(toInt(m['total'])),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}
