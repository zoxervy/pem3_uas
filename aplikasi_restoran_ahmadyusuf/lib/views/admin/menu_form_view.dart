import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/kategori_controller.dart';
import '../../controllers/menu_controller.dart';
import '../../models/menu.dart';
import '../../ui.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/state_views.dart';

/// Form tambah / ubah menu (F-04). Kalau [menu] diisi berarti mode ubah.
class MenuFormView extends StatefulWidget {
  const MenuFormView({super.key, this.menu});

  final Menu? menu;

  @override
  State<MenuFormView> createState() => _MenuFormViewState();
}

class _MenuFormViewState extends State<MenuFormView> {
  late final _nama = TextEditingController(text: widget.menu?.namaMenu ?? '');
  late final _harga = TextEditingController(text: widget.menu == null ? '' : '${widget.menu!.harga}');
  late final _deskripsi = TextEditingController(text: widget.menu?.deskripsi ?? '');
  late final _foto = TextEditingController(text: widget.menu?.foto ?? '');
  late int? _kategoriId = widget.menu?.kategoriId;
  late bool _tersedia = widget.menu?.tersedia ?? true;

  @override
  void initState() {
    super.initState();
    setelahBuild(() {
      context.read<KategoriController>().muat();
      context.read<MenuController>().bersihkanError();
    });
  }

  @override
  void dispose() {
    for (final c in [_nama, _harga, _deskripsi, _foto]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    final ctrl = context.read<MenuController>();
    final bool ok;
    if (widget.menu == null) {
      ok = await ctrl.tambah(
          kategoriId: _kategoriId, nama: _nama.text, harga: _harga.text,
          deskripsi: _deskripsi.text, foto: _foto.text, tersedia: _tersedia);
    } else {
      ok = await ctrl.ubah(widget.menu!.id,
          kategoriId: _kategoriId, nama: _nama.text, harga: _harga.text,
          deskripsi: _deskripsi.text, foto: _foto.text, tersedia: _tersedia);
    }
    if (!mounted) return;
    if (ok) {
      snack(context, 'Menu disimpan.');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuCtrl = context.watch<MenuController>();
    final kategori = context.watch<KategoriController>();
    final adaKategori = kategori.daftar.any((k) => k.id == _kategoriId);
    return Scaffold(
      appBar: AppBar(title: Text(widget.menu == null ? 'Tambah Menu' : 'Ubah Menu')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            ErrorBanner(menuCtrl.error),
            TextField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama menu'),
            ),
            const SizedBox(height: 12),
            if (kategori.daftar.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Memuat kategori... (tambahkan kategori dulu jika kosong)'),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: adaKategori ? _kategoriId : null,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final k in kategori.daftar)
                    DropdownMenuItem(value: k.id, child: Text(k.namaKategori)),
                ],
                onChanged: (v) => setState(() => _kategoriId = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _harga,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Harga (Rp)', prefixText: 'Rp '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deskripsi,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _foto,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Link foto (opsional)', hintText: 'https://...'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tersedia'),
              subtitle: const Text('Matikan jika menu sedang habis'),
              value: _tersedia,
              onChanged: (v) => setState(() => _tersedia = v),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: menuCtrl.loading ? null : _simpan,
              icon: menuCtrl.loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: const Text('Simpan'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ]),
        ),
      ),
    );
  }
}
