import '../ui.dart';

/// Tombol "+" (belum dipilih) atau "− jumlah +" (sudah ada di keranjang) pada kartu menu.
class JumlahStepper extends StatelessWidget {
  const JumlahStepper({
    super.key,
    required this.namaMenu,
    required this.jumlah,
    required this.onTambah,
    required this.onKurang,
    this.aktif = true,
  });

  final String namaMenu;
  final int jumlah;
  final VoidCallback onTambah;
  final VoidCallback onKurang;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    if (!aktif) return const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.block));
    final warna = Theme.of(context).colorScheme.primary;
    if (jumlah == 0) {
      return IconButton(
        tooltip: 'Tambah $namaMenu',
        icon: Icon(Icons.add_circle_outline, color: warna),
        onPressed: onTambah,
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(tooltip: 'Kurangi $namaMenu', icon: Icon(Icons.remove_circle_outline, color: warna), onPressed: onKurang),
      Semantics(
        label: '$jumlah porsi $namaMenu',
        excludeSemantics: true,
        child: SizedBox(
          width: 22,
          child: Text('$jumlah', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
      IconButton(tooltip: 'Tambah $namaMenu', icon: Icon(Icons.add_circle, color: warna), onPressed: onTambah),
    ]);
  }
}
