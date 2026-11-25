import '../models/menu.dart';
import '../ui.dart';
import 'format.dart';

/// Satu baris menu: nama, kategori, harga, tombol di kanan.
/// Sengaja dibuat ringan (tanpa bayangan / transparansi) supaya scroll lancar di HP.
class MenuCard extends StatelessWidget {
  const MenuCard({super.key, required this.menu, this.onTap, this.trailing});

  final Menu menu;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final habis = !menu.tersedia;
    final adaFoto = menu.foto != null && menu.foto!.isNotEmpty;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 12, right: 4),
      leading: adaFoto
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(menu.foto!, width: 48, height: 48, fit: BoxFit.cover,
                  cacheWidth: 96, errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48)),
            )
          : null,
      title: Text(menu.namaMenu,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, color: habis ? tema.disabledColor : null)),
      subtitle: Text.rich(TextSpan(children: [
        TextSpan(
            text: rupiah(menu.harga),
            style: TextStyle(color: habis ? tema.disabledColor : tema.colorScheme.primary, fontWeight: FontWeight.bold)),
        if (menu.namaKategori != null) TextSpan(text: '  ·  ${menu.namaKategori}'),
        if (habis) TextSpan(text: '  ·  Habis', style: TextStyle(color: tema.colorScheme.error, fontWeight: FontWeight.w600)),
      ])),
      trailing: trailing,
    );
  }
}
