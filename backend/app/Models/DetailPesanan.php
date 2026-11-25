<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DetailPesanan extends Model
{
    protected $table = 'detail_pesanan';
    public $timestamps = false;
    protected $fillable = ['pesanan_id', 'menu_id', 'jumlah', 'harga_satuan', 'subtotal', 'catatan'];

    public function menu() { return $this->belongsTo(Menu::class, 'menu_id'); }
    public function pesanan() { return $this->belongsTo(Pesanan::class, 'pesanan_id'); }

    public static function hitungSubtotal(int $jumlah, int $hargaSatuan): int
    {
        return $jumlah * $hargaSatuan;
    }
}
