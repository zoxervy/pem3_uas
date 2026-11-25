import 'package:provider/provider.dart';

import '../../controllers/pelanggan_controller.dart';
import '../../ui.dart';
import '../../widgets/format.dart';
import '../../widgets/jumlah_stepper.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';
import 'status_pesanan_view.dart';

/// Halaman yang terbuka saat pelanggan memindai QR meja (tanpa login).
class MenuPelangganView extends StatefulWidget {
  const MenuPelangganView({super.key, required this.kodeMeja});

  final String kodeMeja;

  @override
  State<MenuPelangganView> createState() => _MenuPelangganViewState();
}

class _MenuPelangganViewState extends State<MenuPelangganView> {
  int? _kategoriId;
  String? _tokenLama;

  @override
  void initState() {
    super.initState();
    setelahBuild(() async {
      final c = context.read<PelangganController>();
      await c.muatMenu(widget.kodeMeja);
      final token = await c.tokenTersimpan();
      if (token != null) {
        await c.segarkanStatus(token);
        if (mounted) setState(() => _tokenLama = token);
      }
    });
  }

  void _bukaStatus(String token) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => StatusPesananView(token: token, kodeMeja: widget.kodeMeja)));

  Future<void> _bukaKeranjang() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _KeranjangSheet(kodeMeja: widget.kodeMeja, onTerkirim: (token) {
        Navigator.pop(context);
        _bukaStatus(token);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PelangganController>();
    final lama = c.pesanan;
    final tampil = c.menu.where((m) => _kategoriId == null || m.kategoriId == _kategoriId).toList();
    return Scaffold(
      appBar: AppBar(title: Text(c.nomorMeja == null ? 'Menu' : 'Meja ${c.nomorMeja} · Menu')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: AsyncBody(
            loading: c.loading,
            error: c.error,
            onRetry: () => c.muatMenu(widget.kodeMeja),
            isEmpty: c.menu.isEmpty,
            emptyText: 'Menu belum tersedia.',
            child: Column(children: [
              if (_tokenLama != null && lama != null && lama.aktif)
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Anda punya pesanan berjalan'),
                    subtitle: Text('${lama.kodePesanan} · ${rupiah(lama.total)}'),
                    trailing: StatusChip(lama.status),
                    onTap: () => _bukaStatus(_tokenLama!),
                  ),
                ),
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
                    for (final k in c.kategori)
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
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                  itemCount: tampil.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final m = tampil[i];
                    return MenuCard(
                      menu: m,
                      onTap: () => c.tambahKeKeranjang(m),
                      trailing: JumlahStepper(
                        namaMenu: m.namaMenu,
                        jumlah: c.jumlahMenu(m.id),
                        aktif: m.tersedia,
                        onTambah: () => c.tambahKeKeranjang(m),
                        onKurang: () => c.kurangiMenu(m),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: c.keranjang.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _bukaKeranjang,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: Text('Lihat pesanan (${c.jumlahItemKeranjang}) · ${rupiah(c.totalKeranjang)}'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
            ),
    );
  }
}

class _KeranjangSheet extends StatefulWidget {
  const _KeranjangSheet({required this.kodeMeja, required this.onTerkirim});

  final String kodeMeja;
  final void Function(String token) onTerkirim;

  @override
  State<_KeranjangSheet> createState() => _KeranjangSheetState();
}

class _KeranjangSheetState extends State<_KeranjangSheet> {
  final _nama = TextEditingController();

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
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
            decoration: const InputDecoration(hintText: 'mis. tidak pedas, tanpa es')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true && mounted) context.read<PelangganController>().setCatatan(item, teks.text);
  }

  Future<void> _kirim() async {
    final c = context.read<PelangganController>();
    final p = await c.kirim(widget.kodeMeja, nama: _nama.text);
    if (p?.token != null) widget.onTerkirim(p!.token!);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PelangganController>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Pesanan Anda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Flexible(
            child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
              for (final item in c.keranjang)
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                          alignment: Alignment.centerLeft),
                    ),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        tooltip: 'Kurangi ${item.menu.namaMenu}',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => c.kurangi(item)),
                    Text('${item.jumlah}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                        tooltip: 'Tambah ${item.menu.namaMenu}',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => c.tambahKeKeranjang(item.menu)),
                  ]),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _nama,
                decoration: const InputDecoration(
                    labelText: 'Nama Anda (opsional)', prefixIcon: Icon(Icons.person_outline)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              ErrorBanner(c.error),
              Row(children: [
                const Text('Total', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text(rupiah(c.totalKeranjang),
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ]),
              const SizedBox(height: 4),
              Text('Waitress akan datang memeriksa pesanan sebelum Anda membayar.',
                  style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor)),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: (c.loading || c.keranjang.isEmpty) ? null : _kirim,
                icon: c.loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Kirim Pesanan'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
