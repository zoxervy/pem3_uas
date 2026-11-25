<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('detail_pesanan', function (Blueprint $t) {
            $t->id();
            $t->foreignId('pesanan_id')->constrained('pesanan')->cascadeOnDelete();
            $t->foreignId('menu_id')->constrained('menu')->restrictOnDelete();
            $t->unsignedInteger('jumlah');
            $t->unsignedInteger('harga_satuan');          // harga saat dipesan
            $t->unsignedInteger('subtotal');              // jumlah x harga_satuan
            $t->string('catatan')->nullable();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('detail_pesanan');
    }
};
