<?php

declare(strict_types=1);

// Pelanggan tanpa login: semua akses memakai kode rahasia (QR meja, token pesanan, kode bayar).

function mejaDariKode(string $kode): array
{
    return Db::satu('SELECT * FROM meja WHERE kode_qr = ?', [$kode]) ?? gagal(404, 'QR meja tidak dikenali.');
}

/** Menu untuk meja yang QR-nya di-scan. */
function publikMenu(Req $r): array
{
    $meja = mejaDariKode($r->param['kode']);

    return [
        'meja' => ['nomor_meja' => $meja['nomor_meja']],
        'kategori' => kategoriIndex(),
        'menu' => array_map('fmtMenu', menuDenganKategori('WHERE m.tersedia = 1')),
    ];
}

/** Pelanggan mengirim pesanan; masuk ke kasir dengan status menunggu_konfirmasi. */
function publikPesan(Req $r): Respon
{
    $meja = mejaDariKode($r->param['kode']);
    $d = V::cek($r->body, ['nama_pelanggan' => 'opsional|teks:100'], ['nama_pelanggan' => 'nama']);
    $items = validasiItems($r->body);

    $id = Db::transaksi(function () use ($meja, $d, $items) {
        [$baris, $total] = bangunItems($items);
        $kode = kodePesananBaru();
        $id = Db::sisip('pesanan', [
            'kode_pesanan' => $kode, 'token' => acak(40), 'meja_id' => $meja['id'], 'nama_pelanggan' => $d['nama_pelanggan'] ?? null,
            'tanggal' => sekarang(), 'status' => 'menunggu_konfirmasi', 'total' => $total,
        ]);
        simpanDetail($id, $baris);
        perbaruiStatusMeja($meja['id']);
        catatLog(null, 'pesan_qr', "Pelanggan meja {$meja['nomor_meja']} mengirim pesanan $kode", $id);

        return $id;
    });

    return new Respon(pesananJson($id, token: true), 201);
}

/** Status pesanan untuk layar HP pelanggan (diakses dengan token rahasia). */
function publikStatus(Req $r): array
{
    $p = Db::satu('SELECT * FROM pesanan WHERE token = ?', [$r->param['token']]) ?? gagal(404, 'Pesanan tidak ditemukan.');

    return fmtPesanan([$p])[0];
}

function pesananDariKodeBayar(string $kode): array
{
    return Db::satu('SELECT * FROM pesanan WHERE kode_bayar = ?', [$kode]) ?? gagal(404, 'Kode pembayaran tidak dikenali.');
}

/** Rincian tagihan saat QR pembayaran di tablet waitress di-scan. */
function publikInfoBayar(Req $r): array
{
    return fmtPesanan([pesananDariKodeBayar($r->param['kode'])])[0];
}

/** Pembayaran mode simulasi (pengganti QRIS sungguhan untuk demo). */
function publikBayar(Req $r): array
{
    if (env('PEMBAYARAN_MODE', 'simulasi') !== 'simulasi') {
        gagal(404, 'Endpoint tidak ditemukan.');
    }
    $id = pesananDariKodeBayar($r->param['kode'])['id'];

    return ubahPesanan($id, function (array $p) {
        if ($p['status'] !== 'menunggu_pembayaran') {
            salahInput('status', 'Pesanan ini tidak sedang menunggu pembayaran.');
        }
        Db::ubah('pesanan', ['status' => 'lunas', 'bayar' => $p['total'], 'kembalian' => 0, 'metode_bayar' => 'qris', 'waktu_bayar' => sekarang()], $p['id']);
        catatLog(null, 'bayar_online', "Pesanan {$p['kode_pesanan']} dibayar lewat QR (simulasi), total {$p['total']}", $p['id']);
    });
}
