<?php

declare(strict_types=1);

/** Waktu sekarang dalam zona waktu aplikasi, format kolom DATETIME. */
function sekarang(): string
{
    return date('Y-m-d H:i:s');
}

function hariIni(): string
{
    return date('Y-m-d');
}

/** Teks acak huruf+angka (untuk kode QR, token pesanan, kode bayar). */
function acak(int $panjang): string
{
    $abjad = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $s = '';
    for ($i = 0; $i < $panjang; $i++) {
        $s .= $abjad[random_int(0, 61)];
    }

    return $s;
}

/** Waktu dari database (zona aplikasi) ke ISO-8601 UTC, sama seperti format Laravel. */
function waktuIso(?string $v): ?string
{
    if ($v === null) {
        return null;
    }

    return (new DateTimeImmutable($v))->setTimezone(new DateTimeZone('UTC'))->format('Y-m-d\TH:i:s.u\Z');
}

function intAtauNull(mixed $v): ?int
{
    return $v === null ? null : (int) $v;
}

function fmtUser(array $u): array
{
    return [
        'id' => (int) $u['id'], 'nama' => $u['nama'], 'username' => $u['username'], 'role' => $u['role'],
        'no_hp' => $u['no_hp'], 'aktif' => (bool) $u['aktif'],
        'created_at' => waktuIso($u['created_at']), 'updated_at' => waktuIso($u['updated_at']),
    ];
}

function fmtKategori(array $k): array
{
    return ['id' => (int) $k['id'], 'nama_kategori' => $k['nama_kategori']];
}

/** Menu; kalau baris memuat nama_kategori (hasil JOIN), sertakan objek kategori. */
function fmtMenu(array $m): array
{
    $hasil = [
        'id' => (int) $m['id'], 'kategori_id' => (int) $m['kategori_id'], 'nama_menu' => $m['nama_menu'],
        'harga' => (int) $m['harga'], 'deskripsi' => $m['deskripsi'], 'foto' => $m['foto'], 'tersedia' => (bool) $m['tersedia'],
    ];
    if (array_key_exists('nama_kategori', $m)) {
        $hasil['kategori'] = ['id' => (int) $m['kategori_id'], 'nama_kategori' => $m['nama_kategori']];
    }

    return $hasil;
}

function fmtMeja(array $m, bool $denganKodeQr = false): array
{
    $hasil = ['id' => (int) $m['id'], 'nomor_meja' => $m['nomor_meja'], 'kapasitas' => intAtauNull($m['kapasitas']), 'status' => $m['status']];
    if ($denganKodeQr) {
        $hasil['kode_qr'] = $m['kode_qr'];
    }

    return $hasil;
}

/**
 * Pesanan lengkap dengan relasi meja, waiter, kasir, dan detail.menu.
 * token & kode_bayar disembunyikan kecuali diminta (keduanya kunci akses).
 * Tanpa $denganDetail (riwayat) item tidak dimuat supaya ringan.
 */
function fmtPesanan(array $daftar, bool $kodeBayar = false, bool $token = false, bool $denganDetail = true): array
{
    if (!$daftar) {
        return [];
    }
    $daftarId = fn (string $kolom, array $baris) => array_values(array_unique(array_filter(array_column($baris, $kolom))));
    $ambil = function (string $sql, array $ids): array {
        if (!$ids) {
            return [];
        }
        $tanda = implode(',', array_fill(0, count($ids), '?'));

        return Db::semua(str_replace('(?)', "($tanda)", $sql), $ids);
    };

    $meja = array_column($ambil('SELECT * FROM meja WHERE id IN (?)', $daftarId('meja_id', $daftar)), null, 'id');
    $orang = array_column($ambil('SELECT id, nama FROM users WHERE id IN (?)',
        array_values(array_unique(array_merge($daftarId('waiter_id', $daftar), $daftarId('kasir_id', $daftar))))), null, 'id');
    $detail = $denganDetail ? $ambil('SELECT * FROM detail_pesanan WHERE pesanan_id IN (?) ORDER BY id', array_column($daftar, 'id')) : [];
    $menu = array_column($ambil('SELECT * FROM menu WHERE id IN (?)', $daftarId('menu_id', $detail)), null, 'id');

    $detailPer = [];
    foreach ($detail as $d) {
        $detailPer[$d['pesanan_id']][] = [
            'id' => (int) $d['id'], 'pesanan_id' => (int) $d['pesanan_id'], 'menu_id' => (int) $d['menu_id'],
            'jumlah' => (int) $d['jumlah'], 'harga_satuan' => (int) $d['harga_satuan'], 'subtotal' => (int) $d['subtotal'],
            'catatan' => $d['catatan'], 'menu' => isset($menu[$d['menu_id']]) ? fmtMenu($menu[$d['menu_id']]) : null,
        ];
    }
    $nama = fn ($id) => $id !== null && isset($orang[$id]) ? ['id' => (int) $id, 'nama' => $orang[$id]['nama']] : null;

    return array_map(function (array $p) use ($meja, $detailPer, $nama, $kodeBayar, $token, $denganDetail) {
        $hasil = [
            'id' => (int) $p['id'], 'kode_pesanan' => $p['kode_pesanan'], 'meja_id' => (int) $p['meja_id'],
            'waiter_id' => intAtauNull($p['waiter_id']), 'kasir_id' => intAtauNull($p['kasir_id']),
            'nama_pelanggan' => $p['nama_pelanggan'], 'tanggal' => waktuIso($p['tanggal']),
            'waktu_konfirmasi' => waktuIso($p['waktu_konfirmasi']), 'status' => $p['status'], 'total' => (int) $p['total'],
            'bayar' => intAtauNull($p['bayar']), 'kembalian' => intAtauNull($p['kembalian']), 'metode_bayar' => $p['metode_bayar'],
            'waktu_bayar' => waktuIso($p['waktu_bayar']), 'waktu_antar' => waktuIso($p['waktu_antar']),
            'meja' => isset($meja[$p['meja_id']]) ? fmtMeja($meja[$p['meja_id']]) : null,
            'waiter' => $nama($p['waiter_id']), 'kasir' => $nama($p['kasir_id']),
        ];
        if ($denganDetail) {
            $hasil['detail'] = $detailPer[$p['id']] ?? [];
        }
        if ($kodeBayar) {
            $hasil['kode_bayar'] = $p['kode_bayar'];
        }
        if ($token) {
            $hasil['token'] = $p['token'];
        }

        return $hasil;
    }, $daftar);
}

/** Satu pesanan (dibaca ulang dari database) dalam format JSON. */
function pesananJson(int $id, bool $kodeBayar = false, bool $token = false): array
{
    return fmtPesanan([Db::cari('pesanan', $id)], $kodeBayar, $token)[0];
}
