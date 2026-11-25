import 'json_util.dart';

/// Pengguna aplikasi (admin / waitress / kasir).
class User {
  const User({
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    this.noHp,
    this.aktif = true,
  });

  final int id;
  final String nama;
  final String username;
  final String role;
  final String? noHp;
  final bool aktif;

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: toInt(j['id']),
        nama: toStr(j['nama']),
        username: toStr(j['username']),
        role: toStr(j['role']),
        noHp: j['no_hp'] == null ? null : toStr(j['no_hp']),
        aktif: j['aktif'] == null ? true : toBool(j['aktif']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'username': username,
        'role': role,
        'no_hp': noHp,
        'aktif': aktif,
      };

  bool isAdmin() => role == 'admin';
  bool isWaitress() => role == 'waitress';
  bool isKasir() => role == 'kasir';

  String get labelRole => switch (role) {
        'admin' => 'Admin',
        'waitress' => 'Waitress',
        'kasir' => 'Kasir',
        _ => role,
      };
}
