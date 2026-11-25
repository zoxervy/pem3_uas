import 'package:provider/provider.dart';

import '../../controllers/pesanan_controller.dart';
import '../../models/pesanan.dart';
import '../../routes.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kartu_pesanan.dart';
import '../../widgets/state_views.dart';

/// Kasir: pesanan dari QR masuk ke sini, lalu ditugaskan ke waitress.
/// Kasir juga menerima bayar tunai (cadangan) dan membatalkan pesanan.
class PesananMasukView extends StatefulWidget {
  const PesananMasukView({super.key});

  @override
  State<PesananMasukView> createState() => _PesananMasukViewState();
}

class _PesananMasukViewState extends State<PesananMasukView> with PollingMixin {
  @override
  void initState() {
    super.initState();
    setelahBuild(() {
      context.read<PesananController>().muatWaitress();
      _muat();
    });
    mulaiPolling(const Duration(seconds: 10), _muat);
  }

  Future<void> _muat() => context.read<PesananController>().muatAktif();

  static int _urutan(Pesanan p) => p.belumDitugaskan ? 0 : (p.status == 'menunggu_pembayaran' ? 1 : 2);

  Future<void> _tugaskan(Pesanan p) async {
    final c = context.read<PesananController>();
    if (c.waitress.isEmpty) await c.muatWaitress();
    if (!mounted) return;
    final pilihan = await showDialog<int>(
      context: context,
      builder: (d) => SimpleDialog(
        title: Text('Tugaskan meja ${p.meja?.nomorMeja ?? ''} ke'),
        children: [
          if (c.waitress.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Tidak ada waitress aktif.')),
          for (final w in c.waitress)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(d, w.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 12),
                  Text(w.nama, style: const TextStyle(fontSize: 16)),
                  if (w.id == p.waiterId) const Text('  (saat ini)', style: TextStyle(fontSize: 13)),
                ]),
              ),
            ),
        ],
      ),
    );
    if (pilihan == null || !mounted) return;
    final ok = await c.tugaskan(p.id, pilihan);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Pesanan ditugaskan.', c.error, 'Gagal menugaskan.');
  }

  Future<void> _batal(Pesanan p) async {
    final ya = await konfirmasi(context,
        judul: 'Batalkan pesanan', isi: 'Batalkan ${p.kodePesanan} (meja ${p.meja?.nomorMeja ?? ''})?', tombol: 'Batalkan');
    if (!ya || !mounted) return;
    final c = context.read<PesananController>();
    final ok = await c.batal(p.id);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Pesanan dibatalkan.', c.error, 'Gagal membatalkan.');
  }

  List<Widget> _aksi(Pesanan p) => switch (p.status) {
        'menunggu_konfirmasi' => [
            p.belumDitugaskan
                ? FilledButton.icon(
                    onPressed: () => _tugaskan(p), icon: const Icon(Icons.assignment_ind_outlined), label: const Text('Tugaskan'))
                : OutlinedButton.icon(
                    onPressed: () => _tugaskan(p), icon: const Icon(Icons.swap_horiz), label: const Text('Ganti waitress')),
            TextButton.icon(onPressed: () => _batal(p), icon: const Icon(Icons.cancel_outlined), label: const Text('Batal')),
          ],
        'menunggu_pembayaran' => [
            FilledButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.pembayaran, arguments: p);
                if (mounted) _muat();
              },
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Terima tunai'),
            ),
            TextButton.icon(onPressed: () => _batal(p), icon: const Icon(Icons.cancel_outlined), label: const Text('Batal')),
          ],
        _ => const [],
      };

  String _info(Pesanan p) => switch (p.status) {
        'menunggu_konfirmasi' => p.belumDitugaskan ? 'Pesanan baru, belum ditugaskan' : 'Ditangani ${p.waiter?.nama ?? '-'}',
        'menunggu_pembayaran' => 'Menunggu pembayaran (dilayani ${p.waiter?.nama ?? '-'})',
        'lunas' => 'Sudah dibayar, menunggu diantar ${p.waiter?.nama ?? ''}',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PesananController>();
    final daftar = [...c.aktif]..sort((a, b) => _urutan(a).compareTo(_urutan(b)));
    final baru = daftar.where((p) => p.belumDitugaskan).length;
    return HalamanScaffold(
      judul: 'Pesanan Masuk',
      aksi: [IconButton(onPressed: _muat, icon: const Icon(Icons.refresh), tooltip: 'Muat ulang')],
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: _muat,
        isEmpty: daftar.isEmpty,
        emptyText: 'Belum ada pesanan. Pesanan dari QR meja akan muncul di sini.',
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (baru > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('$baru pesanan baru perlu ditugaskan',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ),
            for (final p in daftar)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: KartuPesanan(pesanan: p, info: _info(p), aksi: _aksi(p)),
              ),
          ]),
        ),
      ),
    );
  }
}
