import 'package:provider/provider.dart';

import '../../controllers/kategori_controller.dart';
import '../../controllers/menu_controller.dart';
import '../../models/menu.dart';
import '../../routes.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/state_views.dart';

/// Halaman 4: daftar menu + filter kategori. Tambah/ubah lewat MenuFormView.
class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  int? _kategoriId;

  @override
  void initState() {
    super.initState();
    setelahBuild(() {
      context.read<KategoriController>().muat();
      _muat();
    });
  }

  Future<void> _muat() => context.read<MenuController>().muat(kategoriId: _kategoriId);

  Future<void> _buka([Menu? menu]) async {
    await Navigator.pushNamed(context, AppRoutes.menuForm, arguments: menu);
    if (mounted) _muat();
  }

  Future<void> _hapus(Menu m) async {
    final ya = await konfirmasi(context,
        judul: 'Hapus menu', isi: 'Hapus menu "${m.namaMenu}"?', tombol: 'Hapus');
    if (!ya || !mounted) return;
    final ctrl = context.read<MenuController>();
    final ok = await ctrl.hapus(m.id);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Menu dihapus.', ctrl.error, 'Gagal menghapus.');
    if (ok) _muat();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MenuController>();
    final kategori = context.watch<KategoriController>().daftar;
    return HalamanScaffold(
      judul: 'Kelola Menu',
      fab: FloatingActionButton.extended(
          onPressed: _buka, icon: const Icon(Icons.add), label: const Text('Tambah Menu')),
      body: Column(children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Semua'),
                  selected: _kategoriId == null,
                  onSelected: (_) {
                    setState(() => _kategoriId = null);
                    _muat();
                  },
                ),
              ),
              for (final k in kategori)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(k.namaKategori),
                    selected: _kategoriId == k.id,
                    onSelected: (_) {
                      setState(() => _kategoriId = k.id);
                      _muat();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: AsyncBody(
            loading: c.loading,
            error: c.error,
            onRetry: _muat,
            isEmpty: c.daftar.isEmpty,
            emptyText: 'Belum ada menu.',
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              itemCount: c.daftar.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = c.daftar[i];
                return MenuCard(
                  menu: m,
                  onTap: () => _buka(m),
                  trailing: IconButton(
                      icon: const Icon(Icons.delete_outline), tooltip: 'Hapus', onPressed: () => _hapus(m)),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
