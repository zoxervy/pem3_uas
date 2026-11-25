import 'package:provider/provider.dart';

import '../../controllers/kategori_controller.dart';
import '../../models/kategori.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/state_views.dart';

/// Halaman 3: kelola kategori menu.
class KategoriView extends StatefulWidget {
  const KategoriView({super.key});

  @override
  State<KategoriView> createState() => _KategoriViewState();
}

class _KategoriViewState extends State<KategoriView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<KategoriController>().muat());
  }

  Future<void> _form({Kategori? edit}) async {
    final ctrl = context.read<KategoriController>();
    final teks = TextEditingController(text: edit?.namaKategori ?? '');
    final simpan = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(edit == null ? 'Tambah Kategori' : 'Ubah Kategori'),
        content: TextField(
          controller: teks,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama kategori'),
          onSubmitted: (_) => Navigator.pop(c, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (simpan != true) return;
    final ok = await ctrl.simpan(id: edit?.id, nama: teks.text);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Kategori disimpan.', ctrl.error, 'Gagal menyimpan.');
  }

  Future<void> _hapus(Kategori k) async {
    final ya = await konfirmasi(context,
        judul: 'Hapus kategori', isi: 'Hapus kategori "${k.namaKategori}"?', tombol: 'Hapus');
    if (!ya || !mounted) return;
    final ctrl = context.read<KategoriController>();
    final ok = await ctrl.hapus(k.id);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Kategori dihapus.', ctrl.error, 'Gagal menghapus.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<KategoriController>();
    return HalamanScaffold(
      judul: 'Kelola Kategori',
      fab: FloatingActionButton.extended(
          onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Tambah')),
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: c.muat,
        isEmpty: c.daftar.isEmpty,
        emptyText: 'Belum ada kategori. Tambahkan dengan tombol di bawah.',
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: c.daftar.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final k = c.daftar[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.category_outlined),
                title: Text(k.namaKategori),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Ubah', onPressed: () => _form(edit: k)),
                  IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Hapus', onPressed: () => _hapus(k)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
