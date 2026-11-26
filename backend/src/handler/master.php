<?php

declare(strict_types=1);

// F-03 s.d. F-06: data master (kategori, menu, meja, user). Tambah dan ubah memakai satu fungsi:
// kalau URL punya {id} berarti ubah, kalau tidak berarti tambah.

function kategoriIndex(): array
{
    return array_map('fmtKategori', Db::semua('SELECT * FROM kategori ORDER BY nama_kategori'));
}

function kategoriSimpan(Req $r): array|Respon
{
    $d = V::cek($r->body, ['nama_kategori' => 'wajib|teks:50'], ['nama_kategori' => 'nama kategori']);
    if (isset($r->param['id'])) {
        Db::ubah('kategori', $d, Db::cari('kategori', $r->id())['id']);

        return fmtKategori(Db::cari('kategori', $r->id()));
    }

    return new Respon(fmtKategori(Db::cari('kategori', Db::sisip('kategori', $d))), 201);
}

function kategoriHapus(Req $r): array
{
    Db::hapus('kategori', Db::cari('kategori', $r->id())['id'], 'Kategori masih dipakai oleh menu, tidak bisa dihapus.');

    return ['message' => 'Kategori dihapus.'];
}

function menuDenganKategori(string $where = '', array $param = []): array
{
    return Db::semua("SELECT m.*, k.nama_kategori FROM menu m JOIN kategori k ON k.id = m.kategori_id $where ORDER BY m.nama_menu", $param);
}

function menuIndex(Req $r): array
{
    $kategori = (int) ($r->query['kategori_id'] ?? 0);

    return array_map('fmtMenu', $kategori ? menuDenganKategori('WHERE m.kategori_id = ?', [$kategori]) : menuDenganKategori());
}

function menuSimpan(Req $r): array|Respon
{
    $d = V::cek($r->body, [
        'kategori_id' => 'wajib|bulat:1', 'nama_menu' => 'wajib|teks:100', 'harga' => 'wajib|bulat:0',
        'deskripsi' => 'opsional|teks:5000', 'foto' => 'opsional|teks:255', 'tersedia' => 'boolean',
    ], ['kategori_id' => 'kategori', 'nama_menu' => 'nama menu']);
    if (Db::nilai('SELECT id FROM kategori WHERE id = ?', [$d['kategori_id']]) === null) {
        salahInput('kategori_id', 'Kategori tidak ditemukan.');
    }
    if (isset($r->param['id'])) {
        $id = Db::cari('menu', $r->id())['id'];
        Db::ubah('menu', $d, $id);
    } else {
        $id = Db::sisip('menu', $d);
    }
    $hasil = fmtMenu(menuDenganKategori('WHERE m.id = ?', [$id])[0]);

    return isset($r->param['id']) ? $hasil : new Respon($hasil, 201);
}

function menuHapus(Req $r): array
{
    Db::hapus('menu', Db::cari('menu', $r->id())['id'], 'Menu sudah pernah dipesan, tandai "habis" saja.');

    return ['message' => 'Menu dihapus.'];
}

/** Meja; kode QR hanya dikirim ke admin (dipakai untuk mencetak QR). */
function mejaIndex(Req $r): array
{
    $admin = $r->user['role'] === 'admin';

    return array_map(fn ($m) => fmtMeja($m, $admin), Db::semua('SELECT * FROM meja ORDER BY CAST(nomor_meja AS UNSIGNED), nomor_meja'));
}

function mejaSimpan(Req $r): array|Respon
{
    $d = V::cek($r->body, ['nomor_meja' => 'wajib|teks:10', 'kapasitas' => 'opsional|bulat:1'], ['nomor_meja' => 'nomor meja']);
    $id = isset($r->param['id']) ? Db::cari('meja', $r->id())['id'] : 0;
    if (Db::nilai('SELECT id FROM meja WHERE nomor_meja = ? AND id <> ?', [$d['nomor_meja'], $id]) !== null) {
        salahInput('nomor_meja', 'Nomor meja sudah dipakai.');
    }
    if ($id) {
        Db::ubah('meja', $d, $id);

        return fmtMeja(Db::cari('meja', $id), true);
    }

    return new Respon(fmtMeja(Db::cari('meja', Db::sisip('meja', $d + ['kode_qr' => acak(32)])), true), 201);
}

/** Ganti kode QR meja (QR lama tidak berlaku lagi), mis. kalau QR tercetak hilang/disalahgunakan. */
function mejaQrBaru(Req $r): array
{
    $id = Db::cari('meja', $r->id())['id'];
    Db::ubah('meja', ['kode_qr' => acak(32)], $id);

    return fmtMeja(Db::cari('meja', $id), true);
}

function mejaHapus(Req $r): array
{
    Db::hapus('meja', Db::cari('meja', $r->id())['id'], 'Meja sudah punya riwayat pesanan, tidak bisa dihapus.');

    return ['message' => 'Meja dihapus.'];
}

function userIndex(): array
{
    return array_map('fmtUser', Db::semua('SELECT * FROM users ORDER BY role, nama'));
}

function userSimpan(Req $r): array|Respon
{
    $ubah = isset($r->param['id']);
    $d = V::cek($r->body, [
        'nama' => 'wajib|teks:100', 'username' => 'wajib|teks:50',
        'password' => ($ubah ? 'opsional' : 'wajib') . '|teks:255|minteks:6',
        'role' => 'wajib|pilihan:admin,waitress,kasir', 'no_hp' => 'opsional|teks:20', 'aktif' => 'boolean',
    ], ['no_hp' => 'no. HP']);
    $id = $ubah ? Db::cari('users', $r->id())['id'] : 0;
    if (Db::nilai('SELECT id FROM users WHERE username = ? AND id <> ?', [$d['username'], $id]) !== null) {
        salahInput('username', 'Username sudah dipakai.');
    }
    if (($d['password'] ?? null) === null) {
        unset($d['password']);           // kosong saat ubah = password tidak diganti
    } else {
        $d['password'] = password_hash($d['password'], PASSWORD_BCRYPT);
    }
    $d['updated_at'] = sekarang();

    if (!$ubah) {
        return new Respon(fmtUser(Db::cari('users', Db::sisip('users', $d + ['created_at' => sekarang()]))), 201);
    }
    if ($id === (int) $r->user['id'] && (($d['aktif'] ?? 1) === 0 || $d['role'] !== 'admin')) {
        salahInput('aktif', 'Anda tidak bisa menonaktifkan atau mengubah role akun sendiri.');
    }
    Db::ubah('users', $d, $id);
    if (($d['aktif'] ?? 1) === 0) {
        Auth::hapusSemua($id);           // paksa logout semua sesi akun yang dinonaktifkan
    }

    return fmtUser(Db::cari('users', $id));
}

function userHapus(Req $r): array
{
    $id = Db::cari('users', $r->id())['id'];
    if ($id === (int) $r->user['id']) {
        salahInput('id', 'Tidak bisa menghapus akun sendiri.');
    }
    Db::hapus('users', $id, 'User punya riwayat transaksi, nonaktifkan saja.');

    return ['message' => 'User dihapus.'];
}
