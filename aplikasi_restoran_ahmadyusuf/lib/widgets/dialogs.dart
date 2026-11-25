import '../ui.dart';

/// Dialog Ya/Tidak. Hasilnya true kalau pengguna memilih lanjut.
Future<bool> konfirmasi(
  BuildContext context, {
  required String judul,
  required String isi,
  String tombol = 'Ya',
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tombol)),
      ],
    ),
  );
  return hasil ?? false;
}

/// Pesan sukses, atau pesan error dari controller (dengan cadangan kalau kosong).
void tampilkanHasil(BuildContext context, bool ok, String sukses, String? error, [String cadangan = 'Gagal.']) =>
    snack(context, ok ? sukses : (error ?? cadangan), error: !ok);

/// Pemilih rentang tanggal untuk filter laporan, riwayat, dan log.
Future<DateTimeRange?> pilihPeriode(BuildContext context, DateTimeRange? awal) => showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: awal,
    );

void snack(BuildContext context, String pesan, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(pesan),
    backgroundColor: error ? Theme.of(context).colorScheme.error : null,
  ));
}
