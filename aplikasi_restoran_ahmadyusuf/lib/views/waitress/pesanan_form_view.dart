import 'package:provider/provider.dart';

import '../../controllers/kategori_controller.dart';
import '../../controllers/menu_controller.dart';
import '../../controllers/pesanan_controller.dart';
import '../../models/meja.dart';
import '../../models/pesanan.dart';
import '../../ui.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/format.dart';
import '../../widgets/jumlah_stepper.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/state_views.dart';

/// Argumen halaman: pesanan yang sedang divalidasi waitress.
class PesananFormArgs {
  const PesananFormArgs({required this.meja, required this.pesanan});

  final Meja meja;
  final Pesanan pesanan;
}

/// Halaman 10: waitress mengubah item pesanan pelanggan saat validasi di meja.
class PesananFormView extends StatefulWidget {
  const PesananFormView({super.key, required this.args});

  final PesananFormArgs args;

  @override
  State<PesananFormView> createState() => _PesananFormViewState();
}

class _PesananFormViewState extends State<PesananFormView> {
  int? _kategoriId;

  @override
  void initState() {
    super.initState();
    setelahBuild(() async {
      final pesanan = context.read<PesananController>();
      final menu = context.read<MenuController>();
      context.read<KategoriController>().muat();
      pesanan.bersihkanError();
      await menu.muat();
      if (!mounted) return;
      pesanan.isiKeranjangDari(widget.args.pesanan, menu.daftar);
    });
  }

  Future<void> _simpan() async {
    final c = context.read<PesananController>();
    final Pesanan? hasil = await c.ubahItems(widget.args.pesanan.id);
    if (!mounted) return;
    if (hasil != null) {
      snack(context, 'Pesanan ${hasil.kodePesanan} diperbarui.');
      Navigator.pop(context, true);
    } else {
      snack(context, c.error ?? 'Gagal menyimpan pesanan.', error: true);
    }
  }

  Future<void> _catatan(ItemKeranjang item) async {
    final teks = TextEditingController(text: item.catatan);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Catatan: ${item.menu.namaMenu}'),
        content: TextField(
          controller: teks,
          autofocus: true,
          maxLength: 255,
          decoration: const InputDecoration(hintText: 'mis. tidak pedas, tanpa es'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<PesananController>().setCatatan(item, teks.text);
  }

  Widget _panelMenu() {
    final menu = context.watch<MenuController>();
    final kategori = context.watch<KategoriController>().daftar;
    final keranjang = context.watch<PesananController>().keranjang;
    final tampil = menu.daftar.where((m) => _kategoriId == null || m.kategoriId == _kategoriId).toList();
    return Column(children: [
      SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                  label: const Text('Semua'),
                  selected: _kategoriId == null,
                  onSelected: (_) => setState(() => _kategoriId = null)),
            ),
            for (final k in kategori)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                    label: Text(k.namaKategori),
                    selected: _kategoriId == k.id,
                    onSelected: (_) => setState(() => _kategoriId = k.id)),
              ),
          ],
        ),
      ),
      Expanded(
        child: AsyncBody(
          loading: menu.loading,
          error: menu.error,
          onRetry: menu.muat,
          isEmpty: tampil.isEmpty,
          emptyText: 'Tidak ada menu di kategori ini.',
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: tampil.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final m = tampil[i];
              final c = context.read<PesananController>();
              return MenuCard(
                menu: m,
                onTap: m.tersedia ? () => c.tambahKeKeranjang(m) : null,
                trailing: JumlahStepper(
                  namaMenu: m.namaMenu,
                  jumlah: keranjang.where((e) => e.menu.id == m.id).fold(0, (s, e) => s + e.jumlah),
                  aktif: m.tersedia,
                  onTambah: () => c.tambahKeKeranjang(m),
                  onKurang: () => c.kurangiMenu(m),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }

  Widget _panelKeranjang() {
    final c = context.watch<PesananController>();
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Icon(Icons.shopping_cart_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Pesanan Meja ${widget.args.meja.nomorMeja}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Text(widget.args.pesanan.kodePesanan, style: TextStyle(color: Theme.of(context).hintColor)),
          ]),
        ),
        const Divider(),
        Expanded(
          child: c.keranjang.isEmpty
              ? const Center(child: Text('Keranjang kosong.\nKetuk menu untuk menambahkan.', textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: c.keranjang.length,
                  itemBuilder: (_, i) {
                    final item = c.keranjang[i];
                    return ListTile(
                      dense: true,
                      title: Text(item.menu.namaMenu),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${rupiah(item.menu.harga)} × ${item.jumlah} = ${rupiah(item.subtotal)}'),
                        TextButton.icon(
                          onPressed: () => _catatan(item),
                          icon: Icon(item.catatan.isEmpty ? Icons.add : Icons.edit_note, size: 18),
                          label: Text(item.catatan.isEmpty ? 'Tambah catatan' : 'Catatan: ${item.catatan}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline), tooltip: 'Kurangi ${item.menu.namaMenu}', onPressed: () => c.kurangi(item)),
                        Text('${item.jumlah}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Tambah ${item.menu.namaMenu}', onPressed: () => c.tambahKeKeranjang(item.menu)),
                      ]),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            ErrorBanner(c.error),
            Row(children: [
              const Text('Total', style: TextStyle(fontSize: 16)),
              const Spacer(),
              Text(rupiah(c.totalKeranjang),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: (c.loading || c.keranjang.isEmpty) ? null : _simpan,
                icon: c.loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Simpan Perubahan'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ubah Pesanan · Meja ${widget.args.meja.nomorMeja}')),
      body: LayoutBuilder(builder: (context, box) {
        if (box.maxWidth >= 820) {
          return Row(children: [
            Expanded(flex: 3, child: _panelMenu()),
            SizedBox(width: 380, child: _panelKeranjang()),
          ]);
        }
        return Column(children: [
          Expanded(child: _panelMenu()),
          SizedBox(height: box.maxHeight * 0.46, child: _panelKeranjang()),
        ]);
      }),
    );
  }
}
