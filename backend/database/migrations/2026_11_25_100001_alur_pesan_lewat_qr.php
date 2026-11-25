<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

/**
 * Alur baru: pelanggan memesan lewat QR meja, waitress memvalidasi,
 * pelanggan membayar lewat QR pembayaran, lalu waitress mengantar.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('meja', function (Blueprint $t) {
            $t->string('kode_qr', 40)->nullable()->unique()->after('status');   // isi QR meja
        });

        Schema::table('pesanan', function (Blueprint $t) {
            $t->enum('status', ['menunggu_konfirmasi', 'menunggu_pembayaran', 'lunas', 'disajikan', 'batal'])
              ->default('menunggu_konfirmasi')->change();
            $t->unsignedBigInteger('waiter_id')->nullable()->change();          // diisi saat waitress memvalidasi
            $t->string('token', 40)->nullable()->unique()->after('kode_pesanan');      // akses pelanggan (cek status)
            $t->string('kode_bayar', 40)->nullable()->unique()->after('token');        // isi QR pembayaran
            $t->enum('metode_bayar', ['qris', 'tunai'])->nullable()->after('kembalian');
            $t->dateTime('waktu_konfirmasi')->nullable()->after('tanggal');
            $t->dateTime('waktu_antar')->nullable()->after('waktu_bayar');
        });

        Schema::table('log_aktivitas', function (Blueprint $t) {
            $t->unsignedBigInteger('user_id')->nullable()->change();            // aksi pelanggan tidak punya user
        });

        foreach (DB::table('meja')->whereNull('kode_qr')->pluck('id') as $id) {
            DB::table('meja')->where('id', $id)->update(['kode_qr' => Str::random(32)]);
        }
    }

    public function down(): void
    {
        Schema::table('pesanan', function (Blueprint $t) {
            $t->dropColumn(['token', 'kode_bayar', 'metode_bayar', 'waktu_konfirmasi', 'waktu_antar']);
        });
        Schema::table('meja', function (Blueprint $t) {
            $t->dropColumn('kode_qr');
        });
    }
};
