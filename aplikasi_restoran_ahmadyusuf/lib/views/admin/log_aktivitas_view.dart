import 'package:provider/provider.dart';

import '../../controllers/log_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/log_aktivitas.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/format.dart';
import '../../widgets/state_views.dart';

/// Halaman 8: timeline log aktivitas dengan filter user & tanggal.
class LogAktivitasView extends StatefulWidget {
  const LogAktivitasView({super.key});

  @override
  State<LogAktivitasView> createState() => _LogAktivitasViewState();
}

class _LogAktivitasViewState extends State<LogAktivitasView> {
  int? _userId;
  DateTimeRange? _periode;

  @override
  void initState() {
    super.initState();
    setelahBuild(() {
      context.read<UserController>().muat();
      _terapkan();
    });
  }

  Future<void> _terapkan() {
    final c = context.read<LogController>();
    c.setFilter(user: _userId, tglDari: _periode?.start, tglSampai: _periode?.end);
    return c.muat();
  }

  Future<void> _pilihPeriode() async {
    final hasil = await pilihPeriode(context, _periode);
    if (hasil == null) return;
    setState(() => _periode = hasil);
    _terapkan();
  }

  static (IconData, Color) _gaya(String aksi) => switch (aksi) {
        'login' => (Icons.login, const Color(0xFF546E7A)),
        'buat_pesanan' => (Icons.add_shopping_cart, const Color(0xFF1565C0)),
        'ubah_pesanan' => (Icons.edit_note, const Color(0xFFB26A00)),
        'ubah_status' => (Icons.swap_horiz, const Color(0xFF7B1FA2)),
        'konfirmasi_bayar' => (Icons.payments_outlined, const Color(0xFF2E7D32)),
        'batal' => (Icons.cancel_outlined, const Color(0xFFC62828)),
        _ => (Icons.info_outline, const Color(0xFF546E7A)),
      };

  @override
  Widget build(BuildContext context) {
    final c = context.watch<LogController>();
    final users = context.watch<UserController>().daftar;
    return HalamanScaffold(
      judul: 'Log Aktivitas',
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                initialValue: _userId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Karyawan', isDense: true),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Semua karyawan')),
                  for (final u in users) DropdownMenuItem<int?>(value: u.id, child: Text(u.nama)),
                ],
                onChanged: (v) {
                  setState(() => _userId = v);
                  _terapkan();
                },
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pilihPeriode,
              icon: const Icon(Icons.date_range),
              label: Text(_periode == null
                  ? 'Semua tanggal'
                  : '${tanggalSaja(_periode!.start)} - ${tanggalSaja(_periode!.end)}'),
            ),
            if (_periode != null || _userId != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _periode = null;
                    _userId = null;
                  });
                  _terapkan();
                },
                child: const Text('Reset filter'),
              ),
          ]),
        ),
        Expanded(
          child: AsyncBody(
            loading: c.loading,
            error: c.error,
            onRetry: _terapkan,
            isEmpty: c.items.isEmpty,
            emptyText: 'Tidak ada aktivitas yang cocok dengan filter.',
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: c.items.length + (c.adaLagi ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == c.items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                        child: OutlinedButton(onPressed: c.muatLagi, child: const Text('Muat lebih banyak'))),
                  );
                }
                final LogAktivitas l = c.items[i];
                final (ikon, warna) = _gaya(l.aksi);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: warna.withValues(alpha: 0.12), child: Icon(ikon, color: warna)),
                    title: Text(l.keterangan.isEmpty ? l.aksi : l.keterangan),
                    subtitle: Text('${l.namaUser} (${l.roleUser}) · ${tanggalJam(l.waktu)}'),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
