<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Menu extends Model
{
    protected $table = 'menu';
    public $timestamps = false;
    protected $fillable = ['kategori_id', 'nama_menu', 'harga', 'deskripsi', 'foto', 'tersedia'];

    protected function casts(): array
    {
        return ['harga' => 'integer', 'tersedia' => 'boolean'];
    }

    public function kategori()
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }
}
