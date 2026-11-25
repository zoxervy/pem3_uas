import 'package:provider/provider.dart';

import '../../controllers/pesanan_controller.dart';
import '../../models/pesanan.dart';
import '../../routes.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/kartu_pesanan.dart';
import '../../widgets/qr_bayar_dialog.dart';
import '../../widgets/state_views.dart';
import 'pesanan_form_view.dart';

/// Tugas waitress: ambil pesanan, validasi di meja, tampilkan QR bayar, antar.
class TugasView extends StatefulWidget {
  const TugasView({super.key});

  @override
  State<TugasView> createState() => _TugasViewState();
}

class _TugasViewState extends State<TugasView> with PollingMixin {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => _muat());
    mulaiPolling(const Duration(seconds: 10), _muat);
  }

  Future<void> _muat() => context.read<PesananController>().muatAktif();

  /// Urutan prioritas: antar dulu, lalu validasi, tugas baru, menunggu bayar.
  static int _urutan(Pesanan p) => switch (p.status) {
        'lunas' => 0,
        'menunggu_konfirmasi' => p.belumDitugaskan ? 2 : 1,
        _ => 3,
      };

  Future<void> _jalankan(Future<bool> Function() aksi, String pesanSukses) async {
    final c = context.read<PesananController>();
    final ok = await aksi();
    if (!mounted) return;
    snack(context, ok ? pesanSukses : (c.error ?? 'Gagal.'), error: !ok);
  }

  Future<void> _validasi(Pesanan p) async {
    final ya = await konfirmasi(context,
        judul: 'Validasi pesanan meja ${p.meja?.nomorMeja ?? ''}',
        isi: 'Pesanan sudah dicek dan sesuai dengan pelanggan? QR pembayaran akan ditampilkan.',
        tombol: 'Sesuai');
    if (!ya || !mounted) return;
    final c = context.read<PesananController>();
    final hasil = await c.konfirmasi(p.id);
    if (!mounted) return;
    if (hasil == null) {
      snack(context, c.error ?? 'Gagal memvalidasi.', error: true);
      return;
    }
    await tampilkanQrBayar(context, hasil);
    if (mounted) _muat();
  }

  Future<void> _ubahItem(Pesanan p) async {
    if (p.meja == null) return;
    await Navigator.pushNamed(context, AppRoutes.pesananForm, arguments: PesananFormArgs(meja: p.meja!, pesanan: p));
    if (mounted) _muat();
  }

  Future<void> _batal(Pesanan p) async {
    final ya = await konfirmasi(context,
        judul: 'Batalkan pesanan', isi: 'Batalkan ${p.kodePesanan} (meja ${p.meja?.nomorMeja ?? ''})?', tombol: 'Batalkan');
    if (ya && mounted) _jalankan(() => context.read<PesananController>().batal(p.id), 'Pesanan dibatalkan.');
  }

  List<Widget> _aksi(Pesanan p) {
    final c = context.read<PesananController>();
    if (p.belumDitugaskan) {
      return [
        FilledButton.icon(
            onPressed: () => _jalankan(() => c.ambil(p.id), 'Tugas diambil.'),
            icon: const Icon(Icons.pan_tool_alt_outlined),
            label: const Text('Ambil tugas')),
      ];
    }
    return switch (p.status) {
      'menunggu_konfirmasi' => [
          FilledButton.icon(
              onPressed: () => _validasi(p), icon: const Icon(Icons.fact_check_outlined), label: const Text('Sesuai, tampilkan QR bayar')),
          OutlinedButton.icon(onPressed: () => _ubahItem(p), icon: const Icon(Icons.edit_outlined), label: const Text('Ubah item')),
          TextButton.icon(onPressed: () => _batal(p), icon: const Icon(Icons.cancel_outlined), label: const Text('Batal')),
        ],
      'menunggu_pembayaran' => [
          FilledButton.icon(
              onPressed: () => tampilkanQrBayar(context, p).then((_) => _muat()),
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Tampilkan QR bayar')),
        ],
      'lunas' => [
          FilledButton.icon(
              onPressed: () => _jalankan(() => c.antar(p.id), 'Pesanan ditandai sudah diantar.'),
              icon: const Icon(Icons.room_service_outlined),
              label: const Text('Sudah diantar')),
        ],
      _ => const [],
    };
  }

  String? _info(Pesanan p) => switch (p.status) {
        'menunggu_konfirmasi' => p.belumDitugaskan ? 'Belum ditugaskan kasir' : 'Datangi meja dan cek pesanan',
        'menunggu_pembayaran' => 'Pelanggan bayar tunai? Arahkan ke kasir.',
        'lunas' => 'Sudah dibayar, antar ke meja',
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<PesananController>();
    final daftar = [...c.aktif]..sort((a, b) => _urutan(a).compareTo(_urutan(b)));
    return HalamanScaffold(
      judul: 'Tugas Saya',
      aksi: [IconButton(onPressed: _muat, icon: const Icon(Icons.refresh), tooltip: 'Muat ulang')],
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: _muat,
        isEmpty: daftar.isEmpty,
        emptyText: 'Belum ada tugas. Pesanan baru dari pelanggan akan muncul di sini.',
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => KartuPesanan(pesanan: daftar[i], info: _info(daftar[i]), aksi: _aksi(daftar[i])),
          ),
        ),
      ),
    );
  }
}
