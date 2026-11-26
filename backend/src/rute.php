<?php

declare(strict_types=1);

/** Daftar endpoint API. Role: null = publik, [] = cukup login, ['admin'] = role tertentu. */
function buatApp(): App
{
    $app = new App();
    $semua = ['admin', 'waitress', 'kasir'];

    // Pelanggan (tanpa login, lewat QR)
    $app->rute('GET', '/publik/meja/{kode}', 'publikMenu', batas: ['publik', 60]);
    $app->rute('POST', '/publik/meja/{kode}/pesanan', 'publikPesan', batas: ['pesan', 10]);
    $app->rute('GET', '/publik/pesanan/{token}', 'publikStatus', batas: ['publik', 60]);
    $app->rute('GET', '/publik/bayar/{kode}', 'publikInfoBayar', batas: ['publik', 60]);
    $app->rute('POST', '/publik/bayar/{kode}', 'publikBayar', batas: ['bayar', 10]);

    // Login
    $app->rute('POST', '/login', 'login', batas: ['login', 10]);
    $app->rute('POST', '/logout', 'logout', []);
    $app->rute('GET', '/me', 'me', []);
    $app->rute('GET', '/dashboard', 'dashboard', $semua);

    // Data master
    $app->rute('GET', '/kategori', 'kategoriIndex', ['admin', 'waitress']);
    $app->rute('POST', '/kategori', 'kategoriSimpan', ['admin']);
    $app->rute('PUT', '/kategori/{id}', 'kategoriSimpan', ['admin']);
    $app->rute('DELETE', '/kategori/{id}', 'kategoriHapus', ['admin']);
    $app->rute('GET', '/menu', 'menuIndex', ['admin', 'waitress']);
    $app->rute('POST', '/menu', 'menuSimpan', ['admin']);
    $app->rute('PUT', '/menu/{id}', 'menuSimpan', ['admin']);
    $app->rute('DELETE', '/menu/{id}', 'menuHapus', ['admin']);
    $app->rute('GET', '/meja', 'mejaIndex', ['admin', 'waitress']);
    $app->rute('POST', '/meja', 'mejaSimpan', ['admin']);
    $app->rute('PUT', '/meja/{id}', 'mejaSimpan', ['admin']);
    $app->rute('DELETE', '/meja/{id}', 'mejaHapus', ['admin']);
    $app->rute('POST', '/meja/{id}/qr-baru', 'mejaQrBaru', ['admin']);
    $app->rute('GET', '/users', 'userIndex', ['admin']);
    $app->rute('POST', '/users', 'userSimpan', ['admin']);
    $app->rute('PUT', '/users/{id}', 'userSimpan', ['admin']);
    $app->rute('DELETE', '/users/{id}', 'userHapus', ['admin']);

    // Pesanan berjalan
    $app->rute('GET', '/pesanan', 'pesananIndex', $semua);
    $app->rute('GET', '/pesanan/{id}', 'pesananShow', $semua);
    $app->rute('GET', '/waitress', 'daftarWaitress', ['kasir']);
    $app->rute('POST', '/pesanan/{id}/tugaskan', 'pesananTugaskan', ['kasir']);
    $app->rute('POST', '/pesanan/{id}/bayar', 'bayarTunai', ['kasir']);
    $app->rute('POST', '/pesanan/{id}/ambil', 'pesananAmbil', ['waitress']);
    $app->rute('PUT', '/pesanan/{id}/items', 'pesananUbahItems', ['waitress']);
    $app->rute('POST', '/pesanan/{id}/konfirmasi', 'pesananKonfirmasi', ['waitress']);
    $app->rute('POST', '/pesanan/{id}/antar', 'pesananAntar', ['waitress']);
    $app->rute('POST', '/pesanan/{id}/batal', 'pesananBatal', ['kasir', 'waitress']);

    // Laporan
    $app->rute('GET', '/riwayat', 'riwayat', ['admin', 'kasir']);
    $app->rute('GET', '/laporan/penjualan', 'laporanPenjualan', ['admin']);
    $app->rute('GET', '/log-aktivitas', 'logIndex', ['admin']);

    return $app;
}
