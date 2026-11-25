<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pesanan', function (Blueprint $t) {
            $t->id();
            $t->string('kode_pesanan', 30)->unique();     // ORD-20261124-001
            $t->foreignId('meja_id')->constrained('meja')->restrictOnDelete();
            $t->foreignId('waiter_id')->constrained('users')->restrictOnDelete();
            $t->foreignId('kasir_id')->nullable()->constrained('users')->restrictOnDelete();
            $t->string('nama_pelanggan', 100)->nullable();
            $t->dateTime('tanggal');
            $t->enum('status', ['diproses', 'disajikan', 'menunggu_pembayaran', 'lunas', 'batal'])
              ->default('diproses');
            $t->unsignedInteger('total')->default(0);
            $t->unsignedInteger('bayar')->nullable();
            $t->unsignedInteger('kembalian')->nullable();
            $t->dateTime('waktu_bayar')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pesanan');
    }
};
