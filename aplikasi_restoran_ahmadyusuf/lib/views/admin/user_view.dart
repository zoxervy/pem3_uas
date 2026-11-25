import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user.dart';
import '../../ui.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/state_views.dart';

/// Halaman 6: kelola user (nama, username, password, role, status aktif).
class UserView extends StatefulWidget {
  const UserView({super.key});

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  @override
  void initState() {
    super.initState();
    setelahBuild(() => context.read<UserController>().muat());
  }

  Future<void> _form({User? edit}) async {
    final ctrl = context.read<UserController>();
    final nama = TextEditingController(text: edit?.nama ?? '');
    final username = TextEditingController(text: edit?.username ?? '');
    final password = TextEditingController();
    final noHp = TextEditingController(text: edit?.noHp ?? '');
    var role = edit?.role ?? 'waitress';
    var aktif = edit?.aktif ?? true;

    final simpan = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: Text(edit == null ? 'Tambah User' : 'Ubah User'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama lengkap')),
                const SizedBox(height: 12),
                TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: edit == null ? 'Password' : 'Password baru (kosongkan jika tidak diganti)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'waitress', child: Text('Waitress')),
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  ],
                  onChanged: (v) => setD(() => role = v ?? role),
                ),
                const SizedBox(height: 12),
                TextField(
                    controller: noHp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'No. HP (opsional)')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Akun aktif'),
                  value: aktif,
                  onChanged: (v) => setD(() => aktif = v),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (simpan != true) return;
    final ok = await ctrl.simpan(
      id: edit?.id,
      nama: nama.text,
      username: username.text,
      password: password.text,
      role: role,
      noHp: noHp.text,
      aktif: aktif,
    );
    if (!mounted) return;
    tampilkanHasil(context, ok, 'User disimpan.', ctrl.error, 'Gagal menyimpan.');
  }

  Future<void> _hapus(User u) async {
    final ya = await konfirmasi(context,
        judul: 'Hapus user', isi: 'Hapus user "${u.nama}"?', tombol: 'Hapus');
    if (!ya || !mounted) return;
    final ctrl = context.read<UserController>();
    final ok = await ctrl.hapus(u.id);
    if (!mounted) return;
    tampilkanHasil(context, ok, 'User dihapus.', ctrl.error, 'Gagal menghapus.');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<UserController>();
    final saya = context.watch<AuthController>().user;
    return HalamanScaffold(
      judul: 'Kelola User',
      fab: FloatingActionButton.extended(
          onPressed: () => _form(), icon: const Icon(Icons.person_add_alt), label: const Text('Tambah')),
      body: AsyncBody(
        loading: c.loading,
        error: c.error,
        onRetry: c.muat,
        isEmpty: c.daftar.isEmpty,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: c.daftar.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final u = c.daftar[i];
            final dirisendiri = u.id == saya?.id;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(u.nama.characters.first.toUpperCase())),
                title: Text(u.nama + (dirisendiri ? ' (Anda)' : '')),
                subtitle: Text('@${u.username} · ${u.labelRole}${u.aktif ? '' : ' · NONAKTIF'}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Ubah', onPressed: () => _form(edit: u)),
                  if (!dirisendiri)
                    IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Hapus', onPressed: () => _hapus(u)),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
