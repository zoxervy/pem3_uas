import 'package:provider/provider.dart';

import '../../controllers/pelanggan_controller.dart';
import '../../models/pesanan.dart';
import '../../ui.dart';
import '../../widgets/format.dart';
import 'menu_pelanggan_view.dart';

/// Status pesanan di HP pelanggan, diperbarui otomatis tiap beberapa detik.
class StatusPesananView extends StatefulWidget {
  const StatusPesananView({super.key, required this.token, this.kodeMeja});

  final String token;
  final String? kodeMeja;

  @override
  State<StatusPesananView> createState() => _StatusPesananViewState();
}

class _StatusPesananViewState extends State<StatusPesananView> with PollingMixin {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => _segarkan());
    mulaiPolling(const Duration(seconds: 4), _segarkan);
  }

  Future<void> _segarkan() async {
    final c = context.read<PelangganController>();
    await c.segarkanStatus(widget.token);
    final st = c.pesanan?.status;
    if (st == 'disajikan' || st == 'batal') hentikanPolling();
  }

  static const _langkah = [
    ('menunggu_konfirmasi', 'Pesanan terkirim', 'Waitress akan datang memeriksa pesanan Anda.'),
    ('menunggu_pembayaran', 'Divalidasi waitress', 'Pindai QR pembayaran yang ditunjukkan waitress.'),
    ('lunas', 'Pembayaran diterima', 'Pesanan sedang disiapkan.'),
    ('disajikan', 'Pesanan diantar', 'Selamat menikmati!'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PelangganController>();
    final Pesanan? p = c.pesanan;
    final tema = Theme.of(context);
    final posisi = p == null ? -1 : _langkah.indexWhere((l) => l.$1 == p.status);
    return Scaffold(
      appBar: AppBar(title: Text(p == null ? 'Status pesanan' : 'Meja ${p.meja?.nomorMeja ?? '-'} · ${p.kodePesanan}')),
      body: p == null
          ? Center(child: c.error == null ? const CircularProgressIndicator() : Text(c.error!))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(padding: const EdgeInsets.all(16), children: [
                  if (p.status == 'batal')
                    Card(
                      color: tema.colorScheme.errorContainer,
                      child: const ListTile(
                          leading: Icon(Icons.cancel_outlined),
                          title: Text('Pesanan dibatalkan'),
                          subtitle: Text('Silakan hubungi waitress atau kasir bila ada pertanyaan.')),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(children: [
                          for (var i = 0; i < _langkah.length; i++)
                            ListTile(
                              leading: Icon(
                                i < posisi
                                    ? Icons.check_circle
                                    : (i == posisi ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                                color: i <= posisi ? tema.colorScheme.primary : tema.disabledColor,
                              ),
                              title: Text(_langkah[i].$2,
                                  style: TextStyle(fontWeight: i == posisi ? FontWeight.bold : FontWeight.normal)),
                              subtitle: i == posisi ? Text(_langkah[i].$3) : null,
                            ),
                        ]),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (final d in p.detail)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(children: [
                              Expanded(
                                  child: Text(
                                      '${d.jumlah}× ${d.namaMenu}${(d.catatan ?? '').isEmpty ? '' : ' (${d.catatan})'}')),
                              Text(rupiah(d.subtotal)),
                            ]),
                          ),
                        const Divider(),
                        Row(children: [
                          const Text('Total', style: TextStyle(fontSize: 16)),
                          const Spacer(),
                          Text(rupiah(p.total),
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold, color: tema.colorScheme.primary)),
                        ]),
                      ]),
                    ),
                  ),
                  if (!p.aktif && widget.kodeMeja != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => MenuPelangganView(kodeMeja: widget.kodeMeja!))),
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Pesan lagi'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                  ],
                ]),
              ),
            ),
    );
  }
}
