<?php

declare(strict_types=1);

// Alur: pelanggan pesan (menunggu_konfirmasi) -> kasir menugaskan waitress -> waitress memvalidasi
// (menunggu_pembayaran, QR bayar dibuat) -> pelanggan bayar (lunas) -> waitress antar (disajikan).

const STATUS_AKTIF = ['menunggu_konfirmasi', 'menunggu_pembayaran', 'lunas'];
const STATUS_DIBAYAR = ['lunas', 'disajikan'];
const TRANSISI = [
    'menunggu_konfirmasi' => ['menunggu_pembayaran', 'batal'],
    'menunggu_pembayaran' => ['lunas', 'batal'],
    'lunas' => ['disajikan'],
];

/** Hitung baris detail dari input; harga selalu diambil dari tabel menu, bukan dari aplikasi. */
function bangunItems(array $items): array
{
    $ids = array_values(array_unique(array_column($items, 'menu_id')));
    $tanda = implode(',', array_fill(0, count($ids), '?'));
    $menu = array_column(Db::semua("SELECT * FROM menu WHERE id IN ($tanda)", $ids), null, 'id');
    $baris = [];
    $total = 0;
    foreach ($items as $i) {
        $m = $menu[$i['menu_id']];
        if (!$m['tersedia']) {
            salahInput('items', "Menu {$m['nama_menu']} sedang habis.");
        }
        $subtotal = $i['jumlah'] * (int) $m['harga'];
        $baris[] = ['menu_id' => $m['id'], 'jumlah' => $i['jumlah'], 'harga_satuan' => (int) $m['harga'],
            'subtotal' => $subtotal, 'catatan' => $i['catatan'] ?? null];
        $total += $subtotal;
    }

    return [$baris, $total];
}

function simpanDetail(int $pesananId, array $baris): void
{
    foreach ($baris as $b) {
        Db::sisip('detail_pesanan', $b + ['pesanan_id' => $pesananId]);
    }
}

function kodePesananBaru(): string
{
    $awalan = 'ORD-' . date('Ymd') . '-';
    $terakhir = Db::nilai('SELECT MAX(kode_pesanan) FROM pesanan WHERE kode_pesanan LIKE ?', [$awalan . '%']);

    return $awalan . str_pad((string) ($terakhir ? (int) substr($terakhir, -3) + 1 : 1), 3, '0', STR_PAD_LEFT);
}

/** Meja terisi selama masih ada pesanan yang belum diantar / belum batal. */
function perbaruiStatusMeja(int $mejaId): void
{
    $aktif = Db::nilai("SELECT 1 FROM pesanan WHERE meja_id = ? AND status IN ('menunggu_konfirmasi','menunggu_pembayaran','lunas') LIMIT 1", [$mejaId]);
    Db::ubah('meja', ['status' => $aktif ? 'terisi' : 'kosong'], $mejaId);
}

function pindahStatus(array $p, string $baru): void
{
    if (!in_array($baru, TRANSISI[$p['status']] ?? [], true)) {
        salahInput('status', "Status tidak bisa berubah dari {$p['status']} ke $baru.");
    }
    Db::ubah('pesanan', ['status' => $baru], $p['id']);
}

function nomorMeja(array $p): string
{
    return (string) Db::nilai('SELECT nomor_meja FROM meja WHERE id = ?', [$p['meja_id']]);
}

/** Ubah satu pesanan dalam transaksi dengan barisnya dikunci, lalu kembalikan versi terbarunya. */
function ubahPesanan(int $id, callable $aksi, bool $kodeBayar = false): array
{
    Db::transaksi(fn () => $aksi(Db::cari('pesanan', $id, kunci: true)));

    return pesananJson($id, $kodeBayar);
}

function pastikanTugasSaya(Req $r, array $p): void
{
    if ((int) $p['waiter_id'] !== (int) $r->user['id']) {
        gagal(403, 'Pesanan ini bukan tugas Anda.');
    }
}

// Endpoint staf

/** Pesanan yang masih berjalan. Waitress hanya melihat tugasnya + yang belum ditugaskan. */
function pesananIndex(Req $r): array
{
    $sql = "SELECT * FROM pesanan WHERE status IN ('menunggu_konfirmasi','menunggu_pembayaran','lunas')";
    $param = [];
    if ($r->user['role'] === 'waitress') {
        $sql .= " AND (waiter_id = ? OR (waiter_id IS NULL AND status = 'menunggu_konfirmasi'))";
        $param[] = $r->user['id'];
    }

    return fmtPesanan(Db::semua("$sql ORDER BY tanggal", $param), kodeBayar: $r->user['role'] !== 'kasir');
}

function pesananShow(Req $r): array
{
    return pesananJson(Db::cari('pesanan', $r->id())['id'], kodeBayar: $r->user['role'] !== 'kasir');
}

/** Daftar waitress aktif (pilihan penugasan di layar kasir). */
function daftarWaitress(): array
{
    return array_map(fn ($u) => ['id' => (int) $u['id'], 'nama' => $u['nama']],
        Db::semua("SELECT id, nama FROM users WHERE role = 'waitress' AND aktif = 1 ORDER BY nama"));
}

/** Kasir menugaskan pesanan ke waitress tertentu. */
function pesananTugaskan(Req $r): array
{
    $waiterId = V::cek($r->body, ['waiter_id' => 'wajib|bulat:1'], ['waiter_id' => 'waitress'])['waiter_id'];
    $nama = Db::nilai("SELECT nama FROM users WHERE id = ? AND role = 'waitress' AND aktif = 1", [$waiterId])
        ?? salahInput('waiter_id', 'Waitress tidak valid.');

    return ubahPesanan($r->id(), function (array $p) use ($r, $waiterId, $nama) {
        if ($p['status'] !== 'menunggu_konfirmasi') {
            salahInput('status', 'Pesanan ini sudah divalidasi, tidak bisa dipindah tugas.');
        }
        Db::ubah('pesanan', ['waiter_id' => $waiterId], $p['id']);
        catatLog($r->user['id'], 'tugaskan', "Kasir {$r->user['nama']} menugaskan {$p['kode_pesanan']} (meja " . nomorMeja($p) . ") ke $nama", $p['id']);
    });
}

/** Waitress mengambil sendiri pesanan yang belum ditugaskan kasir. */
function pesananAmbil(Req $r): array
{
    return ubahPesanan($r->id(), function (array $p) use ($r) {
        if ($p['status'] !== 'menunggu_konfirmasi' || $p['waiter_id'] !== null) {
            salahInput('status', 'Pesanan ini sudah ditangani waitress lain.');
        }
        Db::ubah('pesanan', ['waiter_id' => $r->user['id']], $p['id']);
        catatLog($r->user['id'], 'ambil_tugas', "{$r->user['nama']} mengambil pesanan {$p['kode_pesanan']} (meja " . nomorMeja($p) . ')', $p['id']);
    });
}

/** Waitress mengubah item saat memvalidasi di meja (sebelum QR bayar muncul). */
function pesananUbahItems(Req $r): array
{
    $items = validasiItems($r->body);

    return ubahPesanan($r->id(), function (array $p) use ($r, $items) {
        pastikanTugasSaya($r, $p);
        if ($p['status'] !== 'menunggu_konfirmasi') {          // NF-02
            salahInput('status', 'Pesanan yang sudah divalidasi tidak bisa diubah.');
        }
        [$baris, $total] = bangunItems($items);
        Db::jalankan('DELETE FROM detail_pesanan WHERE pesanan_id = ?', [$p['id']]);
        simpanDetail($p['id'], $baris);
        Db::ubah('pesanan', ['total' => $total], $p['id']);
        catatLog($r->user['id'], 'ubah_pesanan', "{$r->user['nama']} mengubah item pesanan {$p['kode_pesanan']}", $p['id']);
    });
}

/** Waitress memvalidasi pesanan di meja: QR pembayaran dibuat. */
function pesananKonfirmasi(Req $r): array
{
    return ubahPesanan($r->id(), function (array $p) use ($r) {
        pastikanTugasSaya($r, $p);
        pindahStatus($p, 'menunggu_pembayaran');
        Db::ubah('pesanan', ['waktu_konfirmasi' => sekarang(), 'kode_bayar' => acak(40)], $p['id']);
        catatLog($r->user['id'], 'konfirmasi_pesanan', "{$r->user['nama']} memvalidasi pesanan {$p['kode_pesanan']}, menunggu pembayaran", $p['id']);
    }, kodeBayar: true);
}

/** Waitress mengantar pesanan yang sudah lunas. */
function pesananAntar(Req $r): array
{
    return ubahPesanan($r->id(), function (array $p) use ($r) {
        pastikanTugasSaya($r, $p);
        pindahStatus($p, 'disajikan');
        Db::ubah('pesanan', ['waktu_antar' => sekarang()], $p['id']);
        perbaruiStatusMeja($p['meja_id']);
        catatLog($r->user['id'], 'antar_pesanan', "{$r->user['nama']} mengantar pesanan {$p['kode_pesanan']} ke meja " . nomorMeja($p), $p['id']);
    });
}

/** Kasir (atau waitress yang bertugas) membatalkan pesanan yang belum dibayar. */
function pesananBatal(Req $r): array
{
    return ubahPesanan($r->id(), function (array $p) use ($r) {
        if ($r->user['role'] === 'waitress') {
            pastikanTugasSaya($r, $p);
        }
        pindahStatus($p, 'batal');
        perbaruiStatusMeja($p['meja_id']);
        catatLog($r->user['id'], 'batal', "{$r->user['nama']} membatalkan pesanan {$p['kode_pesanan']}", $p['id']);
    });
}
