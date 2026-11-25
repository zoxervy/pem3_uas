import '../ui.dart';

/// Label berwarna untuk status pesanan / meja.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String status;

  static Color warna(String status) => switch (status) {
        'menunggu_konfirmasi' => const Color(0xFFB26A00),
        'menunggu_pembayaran' => const Color(0xFF7B1FA2),
        'lunas' => const Color(0xFF1565C0),
        'disajikan' || 'kosong' => const Color(0xFF2E7D32),
        'batal' || 'terisi' => const Color(0xFFC62828),
        _ => const Color(0xFF546E7A),
      };

  /// Warna teks: 30% lebih gelap dari warna status supaya kontras >= 4.5:1 di latar tint.
  static Color warnaTeks(String status) => Color.lerp(warna(status), const Color(0xFF000000), 0.3)!;

  static String label(String status) => switch (status) {
        'menunggu_konfirmasi' => 'Perlu validasi',
        'menunggu_pembayaran' => 'Menunggu bayar',
        'lunas' => 'Siap diantar',
        'disajikan' => 'Sudah diantar',
        'batal' => 'Batal',
        'kosong' => 'Kosong',
        'terisi' => 'Terisi',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    final c = warna(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Text(label(status),
          style: TextStyle(color: warnaTeks(status), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
