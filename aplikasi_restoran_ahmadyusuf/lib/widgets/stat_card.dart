import 'dart:math';

import '../ui.dart';

/// Kartu angka ringkas di dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.ikon,
    required this.label,
    required this.nilai,
    this.warna,
  });

  final IconData ikon;
  final String label;
  final String nilai;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final c = warna ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: c.withValues(alpha: 0.12),
            child: Icon(ikon, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              Text(nilai,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Susun beberapa [StatCard] sejajar; otomatis turun baris di layar sempit.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final kolom = box.maxWidth >= 640 ? min(children.length, 3) : (box.maxWidth >= 380 ? 2 : 1);
      final lebar = (box.maxWidth - (kolom - 1) * 12) / kolom;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [for (final c in children) SizedBox(width: lebar, child: c)],
      );
    });
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.teks, {super.key});

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(teks,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}
