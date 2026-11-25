import '../models/pesanan.dart';
import '../ui.dart';
import 'format.dart';
import 'status_chip.dart';

/// Kartu satu pesanan berjalan (dipakai layar waitress dan kasir).
class KartuPesanan extends StatelessWidget {
  const KartuPesanan({super.key, required this.pesanan, required this.aksi, this.info});

  final Pesanan pesanan;
  final List<Widget> aksi;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final p = pesanan;
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Meja ${p.meja?.nomorMeja ?? '-'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            StatusChip(p.status),
          ]),
          Text(
            [p.kodePesanan, if ((p.namaPelanggan ?? '').isNotEmpty) p.namaPelanggan!, tanggalJam(p.tanggal)].join(' · '),
            style: TextStyle(fontSize: 12, color: tema.hintColor),
          ),
          if (info != null) ...[
            const SizedBox(height: 2),
            Text(info!, style: TextStyle(fontSize: 13, color: tema.colorScheme.primary)),
          ],
          const SizedBox(height: 6),
          for (final d in p.detail)
            Text('• ${d.jumlah}× ${d.namaMenu}${(d.catatan ?? '').isEmpty ? '' : ' (${d.catatan})'}',
                style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text(rupiah(p.total),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: tema.colorScheme.primary)),
          if (aksi.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: aksi),
          ],
        ]),
      ),
    );
  }
}
