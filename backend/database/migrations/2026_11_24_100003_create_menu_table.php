<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('menu', function (Blueprint $t) {
            $t->id();
            $t->foreignId('kategori_id')->constrained('kategori')->restrictOnDelete();
            $t->string('nama_menu', 100);
            $t->unsignedInteger('harga');                 // rupiah
            $t->text('deskripsi')->nullable();
            $t->string('foto')->nullable();               // path/URL gambar
            $t->boolean('tersedia')->default(true);       // 1 = tersedia, 0 = habis
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('menu');
    }
};
