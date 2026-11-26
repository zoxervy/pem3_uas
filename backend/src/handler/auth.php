<?php

declare(strict_types=1);

/** F-01: login, mengembalikan token + data user (role dipakai Flutter untuk routing). */
function login(Req $r): array
{
    $d = V::cek($r->body, ['username' => 'wajib|teks:50', 'password' => 'wajib|teks:255']);
    $user = Db::satu('SELECT * FROM users WHERE username = ?', [$d['username']]);
    if ($user === null || !password_verify((string) $r->body['password'], $user['password'])) {
        gagal(401, 'Username atau password salah.');
    }
    if (!$user['aktif']) {
        gagal(403, 'Akun Anda dinonaktifkan. Hubungi admin.');
    }
    $token = Auth::buatToken((int) $user['id']);
    catatLog((int) $user['id'], 'login', "{$user['nama']} ({$user['role']}) login");

    return ['token' => $token, 'user' => fmtUser($user)];
}

function logout(Req $r): array
{
    Db::jalankan('DELETE FROM personal_access_tokens WHERE id = ?', [$r->user['id_token']]);

    return ['message' => 'Berhasil logout.'];
}

function me(Req $r): array
{
    return fmtUser($r->user);
}

function catatLog(?int $userId, string $aksi, string $keterangan, ?int $pesananId = null): void
{
    Db::sisip('log_aktivitas', [
        'user_id' => $userId, 'pesanan_id' => $pesananId, 'aksi' => $aksi, 'keterangan' => $keterangan, 'waktu' => sekarang(),
    ]);
}
