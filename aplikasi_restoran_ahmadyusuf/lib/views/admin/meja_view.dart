import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/meja_controller.dart';
import '../../models/meja.dart';
import '../../routes.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Halaman 5: kelola meja (nomor, kapasitas) + lihat status.
class MejaView extends StatefulWidget {
  const MejaView({super.key});

  @override
  State<MejaView> createState() => _MejaViewState();
}

class _MejaViewState extends State<MejaView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<MejaController>().muat());
  }

  Future<void> _form({Meja? edit}) async {
    final ctrl = context.read<MejaController>();
    final nomor = TextEditingController(text: edit?.nomorMeja ?? '');
    final kapasitas = TextEditingController(text: edit?.kapasitas?.toString() ?? '');
    final simpan = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(edit == null ? 'Tambah Meja' : 'Ubah Meja'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nomor,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nomor meja')),
          const SizedBox(height: 12),
          TextField(
            controller: kapasitas,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Kapasitas (kursi)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (simpan != true) return;
    final ok = await ctrl.simpan(id: edit?.id, nomor: nomor.text, kapasitas: kapasitas.text);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Meja disimpan.', ctrl.error, 'Gagal menyimpan.');
  }

  Future<void> _hapus(Meja m) async {
    final ya = await konfirmasi(context,
        judul: 'Hapus meja', isi: 'Hapus meja ${m.nomorMeja}?', tombol: 'Hapus');
    if (!ya || !mounted) return;
    final ctrl = context.read<MejaController>();
    final ok = await ctrl.hapus(m.id);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'Meja dihapus.', ctrl.error, 'Gagal menghapus.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MejaController>();
    return HalamanScaffold(
      judul: 'Kelola Meja',
      aksi: [
        IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.qrMeja),
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'QR meja'),
      ],
      fab: FloatingActionButton.extended(
          onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Tambah')),
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: c.muat,
        isEmpty: c.daftar.isEmpty,
        emptyText: 'Belum ada meja.',
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 170),
          itemCount: c.daftar.length,
          itemBuilder: (_, i) {
            final m = c.daftar[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Meja ${m.nomorMeja}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(m.kapasitas == null ? '-' : '${m.kapasitas} kursi',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 6),
                  StatusChip(m.status),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Ubah', onPressed: () => _form(edit: m)),
                    IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Hapus', onPressed: () => _hapus(m)),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
