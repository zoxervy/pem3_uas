<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $t) {
            $t->id();
            $t->string('nama', 100);
            $t->string('username', 50)->unique();
            $t->string('password');                       // hash
            $t->enum('role', ['admin', 'waitress', 'kasir']);
            $t->string('no_hp', 20)->nullable();
            $t->boolean('aktif')->default(true);          // 1 = aktif, 0 = nonaktif
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
