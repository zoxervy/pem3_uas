<?php

declare(strict_types=1);

// Test API:  php tests/uji_api.php
// Semua data uji dibuat di dalam satu transaksi lalu di-ROLLBACK, jadi database tidak berubah.

putenv('RATE_LIMIT=0');
require __DIR__ . '/../src/bootstrap.php';

$app = buatApp();
Db::pdo()->beginTransaction();
$lulus = 0;
$gagal = [];

function uji(string $nama, callable $f): void
{
    global $lulus, $gagal;
    try {
        Db::transaksi($f);
        $lulus++;
        echo "  ✓ $nama\n";
    } catch (Throwable $e) {
        $gagal[] = $nama;
        echo "  ✗ $nama\n      " . $e->getMessage() . "\n";
    }
}

/** Panggil API seperti dari aplikasi; hasil [status, data JSON]. */
function api(string $method, string $url, array $body = [], ?string $token = null): array
{
    global $app;
    [$path, $qs] = array_pad(explode('?', $url, 2), 2, '');
    parse_str($qs, $query);
    [$status, $data] = $app->tangani(new Req($method, $path, $query, $body, $token, '127.0.0.1'));

    return [$status, json_decode((string) json_encode($data), true)];
}

function harus(bool $kondisi, string $pesan): void
{
    if (!$kondisi) {
        throw new RuntimeException($pesan);
    }
}

function status(array $res, int $harus, string $ket): array
{
    harus($res[0] === $harus, "$ket: status {$res[0]}, seharusnya $harus. " . json_encode($res[1], JSON_UNESCAPED_UNICODE));

    return $res[1];
}

function userBaru(string $role, string $nama = 'Uji', array $lain = []): array
{
    $username = 'uji_' . acak(8);
    $id = Db::sisip('users', [
        'nama' => $nama, 'username' => $username, 'password' => password_hash('rahasia1', PASSWORD_BCRYPT, ['cost' => 4]),
        'role' => $role, 'aktif' => $lain['aktif'] ?? 1, 'created_at' => sekarang(), 'updated_at' => sekarang(),
    ]);

    return ['id' => $id, 'username' => $username, 'nama' => $nama, 'token' => Auth::buatToken($id)];
}

/** Kategori, 2 menu (nasi 25.000, teh 5.000), dan 1 meja baru. */
function siapkan(): array
{
    $k = Db::sisip('kategori', ['nama_kategori' => 'Uji ' . acak(4)]);
    $nasi = Db::sisip('menu', ['kategori_id' => $k, 'nama_menu' => 'Nasi Uji', 'harga' => 25000]);
    $teh = Db::sisip('menu', ['kategori_id' => $k, 'nama_menu' => 'Teh Uji', 'harga' => 5000]);
    $kode = acak(32);
    $meja = Db::sisip('meja', ['nomor_meja' => 'U' . acak(5), 'kapasitas' => 4, 'kode_qr' => $kode]);

    return [$nasi, $teh, $meja, $kode];
}

function pelangganPesan(string $kode, array $items): array
{
    $p = status(api('POST', "/publik/meja/$kode/pesanan", ['nama_pelanggan' => 'Andi', 'items' => $items]), 201, 'pesan');
    harus($p['status'] === 'menunggu_konfirmasi' && strlen($p['token']) === 40, 'pesanan baru harus menunggu_konfirmasi + token');

    return $p;
}

echo "API restoran (PHP native)\n";

uji('login benar, salah, nonaktif, input kosong', function () {
    $u = userBaru('kasir');
    $off = userBaru('kasir', 'Off', ['aktif' => 0]);
    status(api('POST', '/login', ['username' => $u['username'], 'password' => 'salah']), 401, 'password salah');
    status(api('POST', '/login', ['username' => $off['username'], 'password' => 'rahasia1']), 403, 'akun nonaktif');
    status(api('POST', '/login', []), 422, 'input kosong');
    $d = status(api('POST', '/login', ['username' => $u['username'], 'password' => 'rahasia1']), 200, 'login benar');
    harus($d['user']['role'] === 'kasir' && $d['user']['aktif'] === true && !isset($d['user']['password']), 'data user benar, tanpa password');
    $me = status(api('GET', '/me', [], $d['token']), 200, 'token baru bisa dipakai');
    harus($me['id'] === $u['id'], '/me mengembalikan user yang login');
    status(api('POST', '/logout', [], $d['token']), 200, 'logout');
    status(api('GET', '/me', [], $d['token']), 401, 'token setelah logout ditolak');
});

uji('akses dibatasi per role', function () {
    status(api('GET', '/menu'), 401, 'tanpa token');
    status(api('GET', '/menu', [], '999|palsu'), 401, 'token palsu');
    $w = userBaru('waitress');
    foreach (['/users', '/waitress', '/laporan/penjualan', '/log-aktivitas', '/riwayat'] as $url) {
        status(api('GET', $url, [], $w['token']), 403, "waitress ke $url");
    }
    status(api('POST', '/menu', [], $w['token']), 403, 'waitress tambah menu');
    status(api('GET', '/tidak-ada', [], $w['token']), 404, 'endpoint tidak ada');
});

uji('QR meja tidak dikenal; kode QR hanya untuk admin', function () {
    [, , , $kode] = siapkan();
    status(api('GET', '/publik/meja/ngawur'), 404, 'QR salah');
    $d = status(api('GET', "/publik/meja/$kode"), 200, 'menu publik');
    harus(!isset($d['meja']['kode_qr']) && count($d['menu']) >= 2, 'menu tampil, kode QR tidak bocor');
    harus(is_bool($d['menu'][0]['tersedia']) && isset($d['menu'][0]['kategori']['nama_kategori']), 'format menu sama seperti sebelumnya');
    $w = userBaru('waitress');
    $meja = status(api('GET', '/meja', [], $w['token']), 200, 'meja waitress');
    harus(!isset($meja[0]['kode_qr']), 'waitress tidak melihat kode QR');
    $a = userBaru('admin');
    $meja = status(api('GET', '/meja', [], $a['token']), 200, 'meja admin');
    harus(isset($meja[0]['kode_qr']), 'admin melihat kode QR');
});

uji('alur lengkap: QR -> tugaskan -> validasi -> bayar -> antar', function () {
    [$nasi, $teh, $mejaId, $kode] = siapkan();
    $rina = userBaru('waitress', 'Rina Uji');
    $budi = userBaru('waitress', 'Budi Uji');
    $kasir = userBaru('kasir', 'Kasir Uji');
    $admin = userBaru('admin');
    $sebelum = status(api('GET', '/laporan/penjualan', [], $admin['token']), 200, 'laporan awal');

    $p = pelangganPesan($kode, [['menu_id' => $nasi, 'jumlah' => 2], ['menu_id' => $teh, 'jumlah' => 1, 'catatan' => 'tanpa es']]);
    $id = $p['id'];
    harus($p['total'] === 55000 && $p['detail'][1]['catatan'] === 'tanpa es', 'total dihitung server: 55.000');
    harus(Db::nilai('SELECT status FROM meja WHERE id = ?', [$mejaId]) === 'terisi', 'meja jadi terisi');
    $s = status(api('GET', "/publik/pesanan/{$p['token']}"), 200, 'status pelanggan');
    harus(!isset($s['kode_bayar']) && !isset($s['token']), 'status pelanggan tidak membocorkan kode bayar');

    status(api('POST', "/pesanan/$id/tugaskan", ['waiter_id' => $kasir['id']], $kasir['token']), 422, 'tugaskan ke bukan waitress');
    $t = status(api('POST', "/pesanan/$id/tugaskan", ['waiter_id' => $rina['id']], $kasir['token']), 200, 'tugaskan ke Rina');
    harus($t['waiter']['nama'] === 'Rina Uji', 'waiter tercatat');

    $daftarBudi = status(api('GET', '/pesanan', [], $budi['token']), 200, 'daftar Budi');
    harus(!in_array($id, array_column($daftarBudi, 'id'), true), 'pesanan Rina tidak muncul di daftar Budi');
    status(api('POST', "/pesanan/$id/konfirmasi", [], $budi['token']), 403, 'Budi validasi tugas Rina');
    status(api('POST', "/pesanan/$id/ambil", [], $budi['token']), 422, 'Budi ambil tugas Rina');

    $u = status(api('PUT', "/pesanan/$id/items", ['items' => [['menu_id' => $nasi, 'jumlah' => 3]]], $rina['token']), 200, 'Rina ubah item');
    harus($u['total'] === 75000, 'total dihitung ulang: 75.000');
    status(api('POST', '/publik/bayar/apasaja'), 404, 'kode bayar ngawur');
    $k = status(api('POST', "/pesanan/$id/konfirmasi", [], $rina['token']), 200, 'Rina validasi');
    harus($k['status'] === 'menunggu_pembayaran' && strlen($k['kode_bayar']) === 40, 'QR bayar dibuat');
    status(api('PUT', "/pesanan/$id/items", ['items' => [['menu_id' => $teh, 'jumlah' => 1]]], $rina['token']), 422, 'ubah item setelah validasi (NF-02)');
    status(api('POST', "/pesanan/$id/antar", [], $rina['token']), 422, 'antar sebelum bayar');

    $info = status(api('GET', "/publik/bayar/{$k['kode_bayar']}"), 200, 'info tagihan');
    harus($info['total'] === 75000, 'tagihan 75.000');
    $b = status(api('POST', "/publik/bayar/{$k['kode_bayar']}"), 200, 'bayar QR');
    harus($b['status'] === 'lunas' && $b['metode_bayar'] === 'qris' && $b['waktu_bayar'] !== null, 'lunas lewat QRIS');
    status(api('POST', "/publik/bayar/{$k['kode_bayar']}"), 422, 'bayar dua kali');
    status(api('POST', "/pesanan/$id/batal", [], $kasir['token']), 422, 'batal setelah dibayar');

    $a = status(api('POST', "/pesanan/$id/antar", [], $rina['token']), 200, 'antar');
    harus($a['status'] === 'disajikan' && $a['waktu_antar'] !== null, 'disajikan');
    harus(Db::nilai('SELECT status FROM meja WHERE id = ?', [$mejaId]) === 'kosong', 'meja kosong lagi');

    $log = array_column(Db::semua('SELECT aksi, user_id FROM log_aktivitas WHERE pesanan_id = ?', [$id]), 'user_id', 'aksi');
    foreach (['pesan_qr', 'tugaskan', 'ubah_pesanan', 'konfirmasi_pesanan', 'bayar_online', 'antar_pesanan'] as $aksi) {
        harus(array_key_exists($aksi, $log), "log $aksi tercatat");
    }
    harus($log['pesan_qr'] === null, 'aksi pelanggan tercatat tanpa user');

    $sesudah = status(api('GET', '/laporan/penjualan', [], $admin['token']), 200, 'laporan akhir');
    harus($sesudah['total_pendapatan'] - $sebelum['total_pendapatan'] === 75000, 'laporan bertambah 75.000');
    harus(is_int($sesudah['per_waitress'][0]['total']), 'angka laporan berupa angka, bukan teks');
    $dash = status(api('GET', '/dashboard', [], $admin['token']), 200, 'dashboard admin');
    harus(is_int($dash['performa_waitress'][0]['total']), 'angka dashboard berupa angka (penyebab layar abu-abu dulu)');
    $riwayat = status(api('GET', '/riwayat', [], $kasir['token']), 200, 'riwayat kasir');
    harus(in_array($id, array_column($riwayat, 'id'), true), 'masuk riwayat');
});

uji('waitress ambil sendiri, kasir terima tunai', function () {
    [$nasi, , , $kode] = siapkan();
    $rina = userBaru('waitress');
    $kasir = userBaru('kasir');
    $id = pelangganPesan($kode, [['menu_id' => $nasi, 'jumlah' => 2]])['id'];
    harus(in_array($id, array_column(status(api('GET', '/pesanan', [], $rina['token']), 200, 'daftar'), 'id'), true), 'pesanan baru terlihat');
    status(api('POST', "/pesanan/$id/ambil", [], $rina['token']), 200, 'ambil');
    status(api('POST', "/pesanan/$id/konfirmasi", [], $rina['token']), 200, 'validasi');
    status(api('POST', "/pesanan/$id/bayar", ['bayar' => 40000], $kasir['token']), 422, 'uang kurang');
    $b = status(api('POST', "/pesanan/$id/bayar", ['bayar' => 60000], $kasir['token']), 200, 'bayar tunai');
    harus($b['kembalian'] === 10000 && $b['metode_bayar'] === 'tunai' && $b['kasir_id'] === $kasir['id'], 'kembalian & kasir tercatat');
});

uji('batal sebelum bayar mengosongkan meja', function () {
    [$nasi, , $mejaId, $kode] = siapkan();
    $kasir = userBaru('kasir');
    $id = pelangganPesan($kode, [['menu_id' => $nasi, 'jumlah' => 1]])['id'];
    $b = status(api('POST', "/pesanan/$id/batal", [], $kasir['token']), 200, 'batal');
    harus($b['status'] === 'batal' && Db::nilai('SELECT status FROM meja WHERE id = ?', [$mejaId]) === 'kosong', 'batal + meja kosong');
});

uji('menu habis ditolak, input pesanan divalidasi', function () {
    [$nasi, , , $kode] = siapkan();
    Db::ubah('menu', ['tersedia' => 0], $nasi);
    status(api('POST', "/publik/meja/$kode/pesanan", ['items' => [['menu_id' => $nasi, 'jumlah' => 1]]]), 422, 'menu habis');
    status(api('POST', "/publik/meja/$kode/pesanan", ['items' => []]), 422, 'tanpa item');
    status(api('POST', "/publik/meja/$kode/pesanan", ['items' => [['menu_id' => 999999, 'jumlah' => 1]]]), 422, 'menu tidak ada');
    status(api('POST', "/publik/meja/$kode/pesanan", ['items' => [['menu_id' => $nasi, 'jumlah' => 0]]]), 422, 'jumlah 0');
    $d = api('POST', "/publik/meja/$kode/pesanan", ['items' => [['menu_id' => "1 OR 1=1", 'jumlah' => 1]]]);
    status($d, 422, 'menu_id berisi SQL ditolak');
});

uji('admin: kelola user, kategori, menu, meja, QR baru', function () {
    [$nasi, , $mejaId, $kode] = siapkan();
    $a = userBaru('admin');
    $u = status(api('POST', '/users', ['nama' => 'Dewi', 'username' => 'uji_dewi', 'password' => '123456', 'role' => 'kasir'], $a['token']), 201, 'tambah user');
    harus(password_verify('123456', Db::nilai('SELECT password FROM users WHERE id = ?', [$u['id']])), 'password di-hash');
    status(api('POST', '/users', ['nama' => 'X', 'username' => 'uji_dewi', 'password' => '123456', 'role' => 'kasir'], $a['token']), 422, 'username kembar');
    status(api('POST', '/users', ['nama' => 'X', 'username' => 'uji_x', 'password' => '123', 'role' => 'kasir'], $a['token']), 422, 'password pendek');
    status(api('PUT', "/users/{$a['id']}", ['nama' => 'A', 'username' => $a['username'], 'role' => 'admin', 'aktif' => false], $a['token']), 422, 'nonaktifkan diri sendiri');
    status(api('DELETE', "/users/{$a['id']}", [], $a['token']), 422, 'hapus diri sendiri');

    $dewiToken = Auth::buatToken($u['id']);
    status(api('PUT', "/users/{$u['id']}", ['nama' => 'Dewi', 'username' => 'uji_dewi', 'role' => 'kasir', 'aktif' => false], $a['token']), 200, 'nonaktifkan Dewi');
    status(api('GET', '/me', [], $dewiToken), 401, 'sesi Dewi otomatis logout');

    $k = status(api('POST', '/kategori', ['nama_kategori' => 'Dessert'], $a['token']), 201, 'tambah kategori');
    status(api('PUT', "/kategori/{$k['id']}", ['nama_kategori' => 'Penutup'], $a['token']), 200, 'ubah kategori');
    status(api('POST', '/menu', ['kategori_id' => 999999, 'nama_menu' => 'X', 'harga' => 1], $a['token']), 422, 'kategori tidak ada');
    status(api('POST', '/menu', ['kategori_id' => $k['id'], 'nama_menu' => 'X'], $a['token']), 422, 'harga kosong');
    $m = status(api('POST', '/menu', ['kategori_id' => $k['id'], 'nama_menu' => 'Puding', 'harga' => 9000], $a['token']), 201, 'tambah menu');
    harus($m['kategori']['nama_kategori'] === 'Penutup' && $m['tersedia'] === true, 'menu baru dengan kategori');
    status(api('DELETE', "/kategori/{$k['id']}", [], $a['token']), 409, 'hapus kategori yang masih dipakai');
    status(api('DELETE', "/menu/{$m['id']}", [], $a['token']), 200, 'hapus menu');

    status(api('POST', '/meja', ['nomor_meja' => Db::nilai('SELECT nomor_meja FROM meja WHERE id = ?', [$mejaId])], $a['token']), 422, 'nomor meja kembar');
    $baru = status(api('POST', "/meja/$mejaId/qr-baru", [], $a['token']), 200, 'QR baru')['kode_qr'];
    harus($baru !== $kode, 'kode QR berubah');
    status(api('GET', "/publik/meja/$kode"), 404, 'QR lama tidak berlaku');
});

uji('log aktivitas: paginasi & filter', function () {
    $a = userBaru('admin');
    $d = status(api('GET', "/log-aktivitas?user_id={$a['id']}", [], $a['token']), 200, 'log');
    harus(isset($d['current_page'], $d['last_page'], $d['data']), 'format paginasi');
    status(api('GET', '/log-aktivitas?dari=bukan-tanggal', [], $a['token']), 422, 'tanggal salah');
});

Db::pdo()->rollBack();
$total = $lulus + count($gagal);
echo "\n" . ($gagal ? "GAGAL: " . count($gagal) . " dari $total test" : "Semua $total test lulus") . " (data uji di-rollback)\n";
exit($gagal ? 1 : 0);
