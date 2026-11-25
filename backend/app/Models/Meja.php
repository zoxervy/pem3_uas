<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Meja extends Model
{
    protected $table = 'meja';
    public $timestamps = false;
    protected $fillable = ['nomor_meja', 'kapasitas', 'status', 'kode_qr'];

    /** Kode QR hanya ditampilkan ke admin (lewat makeVisible). */
    protected $hidden = ['kode_qr'];

    protected static function booted(): void
    {
        static::creating(function (Meja $m) {
            $m->kode_qr ??= Str::random(32);
        });
    }

    public function pesanan()
    {
        return $this->hasMany(Pesanan::class, 'meja_id');
    }

    public function isKosong(): bool
    {
        return $this->status === 'kosong';
    }

    /** Meja terisi selama masih ada pesanan yang belum diantar / belum batal. */
    public function perbaruiStatus(): void
    {
        $aktif = $this->pesanan()->whereIn('status', Pesanan::STATUS_AKTIF)->exists();
        $this->update(['status' => $aktif ? 'terisi' : 'kosong']);
    }
}
