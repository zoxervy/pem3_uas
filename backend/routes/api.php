<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\KategoriController;
use App\Http\Controllers\Api\LaporanController;
use App\Http\Controllers\Api\LogController;
use App\Http\Controllers\Api\MejaController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\PembayaranController;
use App\Http\Controllers\Api\PesananController;
use App\Http\Controllers\Api\PublikController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

// Pelanggan: tanpa login, lewat QR
Route::prefix('publik')->middleware('throttle:60,1')->group(function () {
    Route::get('/meja/{kode}', [PublikController::class, 'menu']);
    Route::post('/meja/{kode}/pesanan', [PublikController::class, 'pesan'])->middleware('throttle:10,1');
    Route::get('/pesanan/{token}', [PublikController::class, 'status']);
    Route::get('/bayar/{kode}', [PublikController::class, 'infoBayar']);
    Route::post('/bayar/{kode}', [PublikController::class, 'bayar'])->middleware('throttle:10,1');
});

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/dashboard', [DashboardController::class, 'index'])->middleware('role:admin,waitress,kasir');

    // Data master (lihat)
    Route::middleware('role:admin,waitress')->group(function () {
        Route::get('/kategori', [KategoriController::class, 'index']);
        Route::get('/menu', [MenuController::class, 'index']);
        Route::get('/meja', [MejaController::class, 'index']);
    });

    // Admin: kelola master data, user, QR meja, laporan, log
    Route::middleware('role:admin')->group(function () {
        Route::apiResource('kategori', KategoriController::class)->except(['index', 'show']);
        Route::apiResource('menu', MenuController::class)->except(['index', 'show']);
        Route::apiResource('meja', MejaController::class)->except(['index', 'show']);
        Route::post('/meja/{meja}/qr-baru', [MejaController::class, 'qrBaru'])->whereNumber('meja');
        Route::apiResource('users', UserController::class)->except(['show']);
        Route::get('/laporan/penjualan', [LaporanController::class, 'penjualan']);
        Route::get('/log-aktivitas', [LogController::class, 'index']);
    });

    // Pesanan berjalan: dipantau semua staf
    Route::middleware('role:admin,waitress,kasir')->group(function () {
        Route::get('/pesanan', [PesananController::class, 'index']);
        Route::get('/pesanan/{pesanan}', [PesananController::class, 'show'])->whereNumber('pesanan');
    });

    // Kasir: terima pesanan & tugaskan waitress, bayar tunai (cadangan)
    Route::middleware('role:kasir')->group(function () {
        Route::get('/waitress', [PesananController::class, 'daftarWaitress']);
        Route::post('/pesanan/{pesanan}/tugaskan', [PesananController::class, 'tugaskan'])->whereNumber('pesanan');
        Route::post('/pesanan/{pesanan}/bayar', [PembayaranController::class, 'konfirmasi'])->whereNumber('pesanan');
    });

    // Waitress: ambil tugas, validasi di meja, antar
    Route::middleware('role:waitress')->group(function () {
        Route::post('/pesanan/{pesanan}/ambil', [PesananController::class, 'ambil'])->whereNumber('pesanan');
        Route::put('/pesanan/{pesanan}/items', [PesananController::class, 'ubahItems'])->whereNumber('pesanan');
        Route::post('/pesanan/{pesanan}/konfirmasi', [PesananController::class, 'konfirmasi'])->whereNumber('pesanan');
        Route::post('/pesanan/{pesanan}/antar', [PesananController::class, 'antar'])->whereNumber('pesanan');
    });

    // Batal (sebelum dibayar): kasir, atau waitress yang bertugas
    Route::post('/pesanan/{pesanan}/batal', [PesananController::class, 'batal'])->whereNumber('pesanan')->middleware('role:kasir,waitress');

    Route::get('/riwayat', [PembayaranController::class, 'riwayat'])->middleware('role:admin,kasir');
});
