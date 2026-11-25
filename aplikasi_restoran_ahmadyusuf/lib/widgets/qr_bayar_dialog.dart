import 'dart:async';

import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controllers/pesanan_controller.dart';
import '../models/pesanan.dart';
import '../ui.dart';
import 'format.dart';

/// Alamat yang dibuka HP pelanggan saat memindai QR pembayaran.
String urlBayar(String kodeBayar) => '${Uri.base.origin}/?bayar=$kodeBayar';

/// Dialog di tablet waitress: QR pembayaran besar + menunggu sampai pelanggan membayar.
Future<void> tampilkanQrBayar(BuildContext context, Pesanan pesanan) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _QrBayarDialog(pesanan: pesanan),
  );
}

class _QrBayarDialog extends StatefulWidget {
  const _QrBayarDialog({required this.pesanan});

  final Pesanan pesanan;

  @override
  State<_QrBayarDialog> createState() => _QrBayarDialogState();
}

class _QrBayarDialogState extends State<_QrBayarDialog> {
  Timer? _timer;
  bool _lunas = false;

  @override
  void initState() {
    super.initState();
    // cek status tiap 3 detik sampai pelanggan selesai membayar
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _cek());
  }

  Future<void> _cek() async {
    final p = await context.read<PesananController>().ambilDetail(widget.pesanan.id, segarkan: true);
    if (!mounted || p == null) return;
    if (p.status == 'lunas' || p.status == 'disajikan') {
      _timer?.cancel();
      setState(() => _lunas = true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pesanan;
    final kode = p.kodeBayar;
    return AlertDialog(
      title: Text('Meja ${p.meja?.nomorMeja ?? '-'} · ${rupiah(p.total)}'),
      content: SizedBox(
        width: 300,
        child: _lunas
            ? const Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle, size: 96, color: Color(0xFF2E7D32)),
                SizedBox(height: 8),
                Text('Pembayaran diterima', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Pesanan siap diantar ke meja.', textAlign: TextAlign.center),
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                if (kode == null)
                  const Text('Kode pembayaran belum tersedia.')
                else
                  Semantics(
                    label: 'QR pembayaran meja ${p.meja?.nomorMeja ?? ''}',
                    child: QrImageView(data: urlBayar(kode), size: 240, backgroundColor: Colors.white),
                  ),
                const SizedBox(height: 8),
                const Text('Minta pelanggan memindai QR ini untuk membayar.', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Menunggu pembayaran...', style: TextStyle(fontSize: 13)),
                ]),
              ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(_lunas ? 'Selesai' : 'Tutup')),
      ],
    );
  }
}
