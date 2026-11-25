import 'package:provider/provider.dart';

import '../../controllers/pelanggan_controller.dart';
import '../../ui.dart';
import '../../widgets/format.dart';
import '../../widgets/state_views.dart';

/// Halaman yang terbuka saat pelanggan memindai QR pembayaran di tablet waitress.
/// Mode simulasi: tidak ada uang sungguhan (nanti diganti Midtrans/QRIS).
class BayarView extends StatefulWidget {
  const BayarView({super.key, required this.kodeBayar});

  final String kodeBayar;

  @override
  State<BayarView> createState() => _BayarViewState();
}

class _BayarViewState extends State<BayarView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<PelangganController>().muatTagihan(widget.kodeBayar));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PelangganController>();
    final t = c.tagihan;
    final tema = Theme.of(context);
    final sudahBayar = t != null && (t.status == 'lunas' || t.status == 'disajikan');
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AsyncBody(
            loading: c.loading && t == null,
            error: t == null ? c.error : null,
            onRetry: () => c.muatTagihan(widget.kodeBayar),
            isEmpty: t == null,
            child: t == null
                ? const SizedBox.shrink()
                : ListView(padding: const EdgeInsets.all(16), children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Meja ${t.meja?.nomorMeja ?? '-'} · ${t.kodePesanan}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(height: 24),
                          for (final d in t.detail)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Expanded(child: Text('${d.jumlah}× ${d.namaMenu}')),
                                Text(rupiah(d.subtotal)),
                              ]),
                            ),
                          const Divider(height: 24),
                          Row(children: [
                            const Text('Total bayar', style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text(rupiah(t.total),
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold, color: tema.colorScheme.primary)),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (sudahBayar)
                      const Column(children: [
                        Icon(Icons.check_circle, size: 88, color: Color(0xFF2E7D32)),
                        SizedBox(height: 8),
                        Text('Pembayaran berhasil',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('Pesanan Anda segera diantar ke meja.', textAlign: TextAlign.center),
                      ])
                    else if (t.status == 'menunggu_pembayaran') ...[
                      ErrorBanner(c.error),
                      FilledButton.icon(
                        onPressed: c.loading ? null : () => c.bayar(widget.kodeBayar),
                        icon: c.loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.qr_code_2),
                        label: Text('Bayar ${rupiah(t.total)}'),
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                      ),
                      const SizedBox(height: 8),
                      Text('Mode simulasi QRIS: tidak ada uang sungguhan yang ditarik.',
                          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: tema.hintColor)),
                    ] else
                      Text(t.status == 'batal' ? 'Pesanan ini sudah dibatalkan.' : 'Pesanan ini belum bisa dibayar.',
                          textAlign: TextAlign.center),
                  ]),
          ),
        ),
      ),
    );
  }
}
