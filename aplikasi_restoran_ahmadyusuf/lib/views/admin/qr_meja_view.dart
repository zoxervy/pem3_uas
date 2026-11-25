import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../controllers/meja_controller.dart';
import '../../models/meja.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/state_views.dart';

/// Alamat yang dibuka saat pelanggan memindai QR meja.
String urlMeja(String kodeQr) => '${Uri.base.origin}/?meja=$kodeQr';

/// Admin: QR tiap meja untuk dicetak dan ditempel di meja.
class QrMejaView extends StatefulWidget {
  const QrMejaView({super.key});

  @override
  State<QrMejaView> createState() => _QrMejaViewState();
}

class _QrMejaViewState extends State<QrMejaView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<MejaController>().muat());
  }

  Future<void> _ganti(Meja m) async {
    final ya = await konfirmasi(context,
        judul: 'Ganti QR meja ${m.nomorMeja}',
        isi: 'QR lama tidak akan berlaku lagi dan harus dicetak ulang. Lanjutkan?',
        tombol: 'Ganti QR');
    if (!ya || !mounted) return;
    final c = context.read<MejaController>();
    final ok = await c.qrBaru(m.id);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'QR meja ${m.nomorMeja} diganti.', c.error, 'Gagal.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MejaController>();
    return HalamanScaffold(
      judul: 'QR Meja',
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: c.muat,
        isEmpty: c.daftar.isEmpty,
        emptyText: 'Belum ada meja.',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Cetak atau tampilkan QR ini di masing-masing meja. Pelanggan memindainya untuk melihat menu dan memesan.',
              style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 16, children: [
            for (final m in c.daftar)
              SizedBox(
                width: 280,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Text('Meja ${m.nomorMeja}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (m.kodeQr == null)
                        const Text('QR belum tersedia.')
                      else
                        Semantics(
                          label: 'QR meja ${m.nomorMeja}',
                          child: QrImageView(data: urlMeja(m.kodeQr!), size: 220, backgroundColor: Colors.white),
                        ),
                      const Text('Scan untuk lihat menu & pesan', textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      TextButton.icon(
                          onPressed: () => _ganti(m), icon: const Icon(Icons.autorenew), label: const Text('Ganti QR')),
                    ]),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}
