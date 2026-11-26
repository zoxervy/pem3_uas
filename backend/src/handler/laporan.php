<?php

declare(strict_types=1);

/** F-11: bayar tunai di kasir (cadangan kalau pelanggan tidak bisa QRIS). */
function bayarTunai(Req $r): array
{
    $bayar = V::cek($r->body, ['bayar' => 'wajib|bulat:0'], ['bayar' => 'uang bayar'])['bayar'];

    return ubahPesanan($r->id(), function (array $p) use ($r, $bayar) {
        if ($p['status'] !== 'menunggu_pembayaran') {
            salahInput('status', 'Pesanan ini tidak sedang menunggu pembayaran.');
        }
        if ($bayar < $p['total']) {
            salahInput('bayar', 'Uang bayar kurang dari total tagihan.');
        }
        Db::ubah('pesanan', ['kasir_id' => $r->user['id'], 'bayar' => $bayar, 'kembalian' => $bayar - $p['total'],
            'waktu_bayar' => sekarang(), 'metode_bayar' => 'tunai', 'status' => 'lunas'], $p['id']);
        catatLog($r->user['id'], 'konfirmasi_bayar', "Kasir {$r->user['nama']} menerima pembayaran tunai {$p['kode_pesanan']} (total {$p['total']})", $p['id']);
    });
}

/** Filter tanggal ?dari=YYYY-MM-DD&sampai=YYYY-MM-DD untuk kolom waktu tertentu. */
function filterTanggal(Req $r, string $kolom): array
{
    $d = V::cek($r->query, ['dari' => 'tanggal', 'sampai' => 'tanggal']);
    $sql = '';
    $param = [];
    if (isset($d['dari'])) {
        $sql .= " AND DATE($kolom) >= ?";
        $param[] = $d['dari'];
    }
    if (isset($d['sampai'])) {
        $sql .= " AND DATE($kolom) <= ?";
        $param[] = $d['sampai'];
    }

    return [$sql, $param];
}

/** F-12: riwayat transaksi yang sudah dibayar. */
function riwayat(Req $r): array
{
    [$filter, $param] = filterTanggal($r, 'waktu_bayar');

    return fmtPesanan(Db::semua("SELECT * FROM pesanan WHERE status IN ('lunas','disajikan') $filter ORDER BY waktu_bayar DESC LIMIT 500", $param), denganDetail: false);
}

/** F-13: laporan penjualan per periode, per waitress, dan per menu. */
function laporanPenjualan(Req $r): array
{
    $d = V::cek($r->query, ['dari' => 'tanggal', 'sampai' => 'tanggal']);
    $dari = $d['dari'] ?? hariIni();
    $sampai = $d['sampai'] ?? $dari;
    if ($sampai < $dari) {
        salahInput('sampai', 'Tanggal akhir tidak boleh sebelum tanggal awal.');
    }
    $dibayar = "p.status IN ('lunas','disajikan') AND DATE(p.waktu_bayar) BETWEEN ? AND ?";
    $param = [$dari, $sampai];
    $ringkas = Db::satu("SELECT COUNT(*) n, COALESCE(SUM(p.total), 0) total FROM pesanan p WHERE $dibayar", $param);

    return [
        'dari' => $dari,
        'sampai' => $sampai,
        'jumlah_transaksi' => (int) $ringkas['n'],
        'total_pendapatan' => (int) $ringkas['total'],
        'per_waitress' => array_map(fn ($w) => ['waiter_id' => (int) $w['waiter_id'], 'nama' => $w['nama'],
            'jumlah_transaksi' => (int) $w['n'], 'total' => (int) $w['total']],
            Db::semua("SELECT u.id waiter_id, u.nama, COUNT(*) n, SUM(p.total) total FROM pesanan p
                JOIN users u ON u.id = p.waiter_id WHERE $dibayar GROUP BY u.id, u.nama ORDER BY total DESC", $param)),
        'per_menu' => array_map(fn ($m) => ['menu_id' => (int) $m['menu_id'], 'nama_menu' => $m['nama_menu'],
            'terjual' => (int) $m['terjual'], 'total' => (int) $m['total']],
            Db::semua("SELECT m.id menu_id, m.nama_menu, SUM(d.jumlah) terjual, SUM(d.subtotal) total FROM pesanan p
                JOIN detail_pesanan d ON d.pesanan_id = p.id JOIN menu m ON m.id = d.menu_id
                WHERE $dibayar GROUP BY m.id, m.nama_menu ORDER BY terjual DESC", $param)),
    ];
}

/** F-02: isi dashboard menyesuaikan role. */
function dashboard(Req $r): array
{
    $u = $r->user;
    $hariIni = "status IN ('lunas','disajikan') AND DATE(waktu_bayar) = ?";
    $angka = fn (string $sql, array $param = []) => (int) Db::nilai($sql, $param);

    if ($u['role'] === 'admin') {
        return [
            'role' => 'admin',
            'pendapatan_hari_ini' => $angka("SELECT COALESCE(SUM(total), 0) FROM pesanan WHERE $hariIni", [hariIni()]),
            'jumlah_transaksi' => $angka("SELECT COUNT(*) FROM pesanan WHERE $hariIni", [hariIni()]),
            'menu_terlaris' => array_map(fn ($m) => ['nama_menu' => $m['nama_menu'], 'terjual' => (int) $m['terjual']],
                Db::semua("SELECT m.nama_menu, SUM(d.jumlah) terjual FROM detail_pesanan d JOIN pesanan p ON p.id = d.pesanan_id
                    JOIN menu m ON m.id = d.menu_id WHERE p.status IN ('lunas','disajikan') GROUP BY m.id, m.nama_menu ORDER BY terjual DESC LIMIT 5")),
            'performa_waitress' => array_map(fn ($w) => ['nama' => $w['nama'], 'transaksi' => (int) $w['n'], 'total' => (int) $w['total']],
                Db::semua("SELECT u.nama, COUNT(*) n, SUM(p.total) total FROM pesanan p JOIN users u ON u.id = p.waiter_id
                    WHERE p.status IN ('lunas','disajikan') AND DATE(p.waktu_bayar) = ? GROUP BY u.id, u.nama ORDER BY total DESC", [hariIni()])),
        ];
    }
    if ($u['role'] === 'waitress') {
        $tugas = fn (string $status) => $angka('SELECT COUNT(*) FROM pesanan WHERE waiter_id = ? AND status = ?', [$u['id'], $status]);

        return [
            'role' => 'waitress',
            'meja' => array_map('fmtMeja', Db::semua('SELECT * FROM meja ORDER BY CAST(nomor_meja AS UNSIGNED), nomor_meja')),
            'belum_ditugaskan' => $angka("SELECT COUNT(*) FROM pesanan WHERE waiter_id IS NULL AND status = 'menunggu_konfirmasi'"),
            'perlu_validasi' => $tugas('menunggu_konfirmasi'),
            'menunggu_bayar' => $tugas('menunggu_pembayaran'),
            'siap_antar' => $tugas('lunas'),
        ];
    }

    return [
        'role' => 'kasir',
        'pesanan_masuk' => $angka("SELECT COUNT(*) FROM pesanan WHERE waiter_id IS NULL AND status = 'menunggu_konfirmasi'"),
        'menunggu_bayar' => $angka("SELECT COUNT(*) FROM pesanan WHERE status = 'menunggu_pembayaran'"),
        'pendapatan_hari_ini' => $angka("SELECT COALESCE(SUM(total), 0) FROM pesanan WHERE $hariIni", [hariIni()]),
        'tunai_shift' => $angka("SELECT COALESCE(SUM(total), 0) FROM pesanan WHERE $hariIni AND kasir_id = ?", [hariIni(), $u['id']]),
        'transaksi_hari_ini' => $angka("SELECT COUNT(*) FROM pesanan WHERE $hariIni", [hariIni()]),
    ];
}

/** F-15: log aktivitas, filter ?user_id=&aksi=&dari=&sampai=, 50 per halaman (terbaru dulu). */
function logIndex(Req $r): array
{
    [$filter, $param] = filterTanggal($r, 'l.waktu');
    if (!empty($r->query['user_id'])) {
        $filter .= ' AND l.user_id = ?';
        $param[] = (int) $r->query['user_id'];
    }
    if (!empty($r->query['aksi'])) {
        $filter .= ' AND l.aksi = ?';
        $param[] = (string) $r->query['aksi'];
    }
    $total = (int) Db::nilai("SELECT COUNT(*) FROM log_aktivitas l WHERE 1 = 1 $filter", $param);
    $halaman = max(1, (int) ($r->query['page'] ?? 1));
    $mulai = ($halaman - 1) * 50;
    $baris = Db::semua("SELECT l.*, u.nama u_nama, u.role u_role, p.kode_pesanan FROM log_aktivitas l
        LEFT JOIN users u ON u.id = l.user_id LEFT JOIN pesanan p ON p.id = l.pesanan_id
        WHERE 1 = 1 $filter ORDER BY l.waktu DESC, l.id DESC LIMIT 50 OFFSET $mulai", $param);

    return [
        'current_page' => $halaman,
        'last_page' => max(1, (int) ceil($total / 50)),
        'per_page' => 50,
        'total' => $total,
        'data' => array_map(fn ($l) => [
            'id' => (int) $l['id'], 'user_id' => intAtauNull($l['user_id']), 'pesanan_id' => intAtauNull($l['pesanan_id']),
            'aksi' => $l['aksi'], 'keterangan' => $l['keterangan'], 'waktu' => waktuIso($l['waktu']),
            'user' => $l['user_id'] === null ? null : ['id' => (int) $l['user_id'], 'nama' => $l['u_nama'], 'role' => $l['u_role']],
            'pesanan' => $l['pesanan_id'] === null ? null : ['id' => (int) $l['pesanan_id'], 'kode_pesanan' => $l['kode_pesanan']],
        ], $baris),
    ];
}
