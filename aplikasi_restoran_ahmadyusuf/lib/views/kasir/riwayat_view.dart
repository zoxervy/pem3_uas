import 'package:provider/provider.dart';

import '../../controllers/pembayaran_controller.dart';
import '../../controllers/pesanan_controller.dart';
import '../../models/pesanan.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/format.dart';
import '../../widgets/state_views.dart';

/// Halaman 14: riwayat transaksi lunas (admin & kasir), filter tanggal.
class RiwayatView extends StatefulWidget {
  const RiwayatView({super.key});

  @override
  State<RiwayatView> createState() => _RiwayatViewState();
}

class _RiwayatViewState extends State<RiwayatView> {
  DateTimeRange? _periode;

  @override
  void initState() {
    super.initState();
    setelahBuild(() => _muat());
  }

  Future<void> _muat() =>
      context.read<PembayaranController>().muatRiwayat(dari: _periode?.start, sampai: _periode?.end);

  Future<void> _pilihPeriode() async {
    final hasil = await pilihPeriode(context, _periode);
    if (hasil == null) return;
    setState(() => _periode = hasil);
    _muat();
  }

  Future<void> _detail(Pesanan p) async {
    final ctrl = context.read<PesananController>();
    final d = await ctrl.ambilDetail(p.id);
    if (!mounted) return;
    if (d == null) {
      snack(context, ctrl.error ?? 'Gagal memuat detail.', error: true);
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(d.kodePesanan),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Meja ${d.meja?.nomorMeja ?? '-'} · ${tanggalJam(d.waktuBayar)}'),
              Text('Waitress: ${d.waiter?.nama ?? '-'}'),
              Text('Kasir: ${d.kasir?.nama ?? '-'}'),
              if ((d.namaPelanggan ?? '').isNotEmpty) Text('Pelanggan: ${d.namaPelanggan}'),
              const Divider(),
              for (final i in d.detail)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Expanded(child: Text('${i.jumlah}× ${i.namaMenu}${(i.catatan ?? '').isEmpty ? '' : ' (${i.catatan})'}')),
                    Text(rupiah(i.subtotal)),
                  ]),
                ),
              const Divider(),
              _baris('Total', rupiah(d.total)),
              _baris('Bayar', rupiah(d.bayar ?? 0)),
              _baris('Kembalian', rupiah(d.kembalian ?? 0)),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))],
      ),
    );
  }

  Widget _baris(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Text(a), const Spacer(), Text(b, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PembayaranController>();
    final total = c.riwayat.fold(0, (s, p) => s + p.total);
    return HalamanScaffold(
      judul: 'Riwayat Transaksi',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            OutlinedButton.icon(
              onPressed: _pilihPeriode,
              icon: const Icon(Icons.date_range),
              label: Text(_periode == null
                  ? 'Semua tanggal'
                  : '${tanggalSaja(_periode!.start)} - ${tanggalSaja(_periode!.end)}'),
            ),
            if (_periode != null)
              TextButton(
                  onPressed: () {
                    setState(() => _periode = null);
                    _muat();
                  },
                  child: const Text('Reset')),
            Text('${c.riwayat.length} transaksi · ${rupiah(total)}',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ]),
        ),
        Expanded(
          child: AsyncBody(
            loading: c.loading,
            error: c.error,
            onRetry: _muat,
            isEmpty: c.riwayat.isEmpty,
            emptyText: 'Belum ada transaksi lunas.',
            child: RefreshIndicator(
              onRefresh: _muat,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: c.riwayat.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = c.riwayat[i];
                  return Card(
                    child: ListTile(
                      onTap: () => _detail(p),
                      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                      title: Text('${p.kodePesanan} · Meja ${p.meja?.nomorMeja ?? '-'}'),
                      subtitle: Text('${tanggalJam(p.waktuBayar)}\nWaitress ${p.waiter?.nama ?? '-'} · Kasir ${p.kasir?.nama ?? '-'}'),
                      isThreeLine: true,
                      trailing: Text(rupiah(p.total), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
