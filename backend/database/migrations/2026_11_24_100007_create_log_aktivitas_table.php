<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('log_aktivitas', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained('users')->restrictOnDelete();
            $t->foreignId('pesanan_id')->nullable()->constrained('pesanan')->nullOnDelete();
            $t->string('aksi', 50);                       // buat_pesanan, ubah_status, konfirmasi_bayar, batal, login
            $t->string('keterangan')->nullable();
            $t->dateTime('waktu');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('log_aktivitas');
    }
};
