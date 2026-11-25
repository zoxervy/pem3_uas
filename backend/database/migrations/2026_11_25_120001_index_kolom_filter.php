<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/** Index untuk kolom yang dipakai filter dashboard, laporan, dan log. */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pesanan', function (Blueprint $t) {
            $t->index('status');
            $t->index('waktu_bayar');
        });
        Schema::table('log_aktivitas', function (Blueprint $t) {
            $t->index('waktu');
        });
    }

    public function down(): void
    {
        Schema::table('pesanan', function (Blueprint $t) {
            $t->dropIndex(['status']);
            $t->dropIndex(['waktu_bayar']);
        });
        Schema::table('log_aktivitas', function (Blueprint $t) {
            $t->dropIndex(['waktu']);
        });
    }
};
