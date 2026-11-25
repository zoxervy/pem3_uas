import '../models/user.dart';
import 'base_controller.dart';

/// F-06: kelola user (CRUD, admin).
class UserController extends BaseController {
  UserController(super.api);

  List<User> daftar = [];

  Future<void> muat() => jalankan(() async {
        final res = await api.get('/users') as List;
        daftar = res
            .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      });

  Future<bool> simpan({
    int? id,
    required String nama,
    required String username,
    String password = '',
    required String role,
    String noHp = '',
    bool aktif = true,
  }) async {
    if (nama.trim().isEmpty) return tolak('Nama wajib diisi.');
    if (username.trim().isEmpty) return tolak('Username wajib diisi.');
    if (id == null && password.length < 6) {
      return tolak('Password minimal 6 karakter.');
    }
    if (id != null && password.isNotEmpty && password.length < 6) {
      return tolak('Password baru minimal 6 karakter (kosongkan jika tidak diganti).');
    }
    final ok = await jalankan(() async {
      final body = {
        'nama': nama.trim(),
        'username': username.trim(),
        if (password.isNotEmpty) 'password': password,
        'role': role,
        'no_hp': noHp.trim().isEmpty ? null : noHp.trim(),
        'aktif': aktif,
      };
      if (id == null) {
        await api.post('/users', body);
      } else {
        await api.put('/users/$id', body);
      }
    });
    if (ok) await muat();
    return ok;
  }

  Future<bool> hapus(int id) async {
    final ok = await jalankan(() async => api.delete('/users/$id'));
    if (ok) await muat();
    return ok;
  }
}
