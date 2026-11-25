import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/pembayaran_controller.dart';
import '../../controllers/pesanan_controller.dart';
import '../../models/pesanan.dart';
import '../../ui.dart';
import '../../widgets/format.dart';
import '../../widgets/state_views.dart';

/// Halaman 13: rincian pesanan, input uang bayar, kembalian, konfirmasi.
class PembayaranView extends StatefulWidget {
  const PembayaranView({super.key, required this.pesanan});

  final Pesanan pesanan;

  @override
  State<PembayaranView> createState() => _PembayaranViewState();
}

class _PembayaranViewState extends State<PembayaranView> {
  final _bayar = TextEditingController();

  int get _nilaiBayar => int.tryParse(_bayar.text) ?? 0;

  @override
  void initState() {
    super.initState();
    setelahBuild(() {
      context.read<PembayaranController>().bersihkanError();
      context.read<PesananController>().ambilDetail(widget.pesanan.id, segarkan: true);
    });
  }

  @override
  void dispose() {
    _bayar.dispose();
    super.dispose();
  }

  void _isi(int nilai) => setState(() => _bayar.text = '$nilai');

  Future<void> _konfirmasi(Pesanan p) async {
    final c = context.read<PembayaranController>();
    final hasil = await c.konfirmasi(p, _nilaiBayar);
    if (!mounted) return;
    if (hasil == null) return; // pesan error tampil di banner
    await _tampilkanStruk(hasil);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _tampilkanStruk(Pesanan p) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Color(0xFF2E7D32)), SizedBox(width: 8), Text('Pembayaran Lunas')]),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.kodePesanan} · Meja ${p.meja?.nomorMeja ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Waitress: ${p.waiter?.nama ?? '-'} · Kasir: ${p.kasir?.nama ?? '-'}', style: const TextStyle(fontSize: 12)),
            const Divider(),
            for (final d in p.detail)
              Row(children: [
                Expanded(child: Text('${d.jumlah}× ${d.namaMenu}')),
                Text(rupiah(d.subtotal)),
              ]),
            const Divider(),
            _baris('Total', rupiah(p.total)),
            _baris('Bayar', rupiah(p.bayar ?? 0)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                const Text('KEMBALIAN'),
                Text(rupiah(p.kembalian ?? 0),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ]),
            ),
          ]),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Selesai'))],
      ),
    );
  }

  Widget _baris(String a, String b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Text(a), const Spacer(), Text(b, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );

  @override
  Widget build(BuildContext context) {
    final pay = context.watch<PembayaranController>();
    // pakai detail terbaru (dengan item) kalau sudah dimuat
    final p = context.watch<PesananController>().detailCache[widget.pesanan.id] ?? widget.pesanan;
    final kembalian = _nilaiBayar - p.total;
    final cukup = _nilaiBayar >= p.total && p.total > 0;
    final cepat = <int>{p.total, 50000, 100000, 150000, 200000}.where((n) => n >= p.total).toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Pembayaran · Meja ${p.meja?.nomorMeja ?? '-'}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.kodePesanan, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Waitress: ${p.waiter?.nama ?? '-'} · ${tanggalJam(p.tanggal)}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  if ((p.namaPelanggan ?? '').isNotEmpty) Text('Pelanggan: ${p.namaPelanggan}'),
                  const Divider(height: 24),
                  if (p.detail.isEmpty)
                    const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()))
                  else
                    for (final d in p.detail)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${d.jumlah}× ${d.namaMenu}'),
                              if ((d.catatan ?? '').isNotEmpty)
                                Text(d.catatan!, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                            ]),
                          ),
                          Text(rupiah(d.subtotal)),
                        ]),
                      ),
                  const Divider(height: 24),
                  Row(children: [
                    const Text('Total tagihan', style: TextStyle(fontSize: 16)),
                    const Spacer(),
                    Text(rupiah(p.total),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            ErrorBanner(pay.error),
            TextField(
              controller: _bayar,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'Uang bayar', prefixText: 'Rp '),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final n in cepat)
                ActionChip(label: Text(n == p.total ? 'Uang pas' : rupiah(n)), onPressed: () => _isi(n)),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (cukup ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.outline).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Text(_nilaiBayar == 0 ? 'Kembalian' : (cukup ? 'Kembalian' : 'Kurang')),
                const Spacer(),
                Text(_nilaiBayar == 0 ? '-' : rupiah(kembalian.abs()),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _nilaiBayar == 0 ? null : (cukup ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.error))),
              ]),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (pay.loading || !cukup) ? null : () => _konfirmasi(p),
              icon: pay.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Konfirmasi Pembayaran'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ]),
        ),
      ),
    );
  }
}
