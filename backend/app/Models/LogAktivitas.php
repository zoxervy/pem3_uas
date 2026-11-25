<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LogAktivitas extends Model
{
    protected $table = 'log_aktivitas';
    public $timestamps = false;
    protected $fillable = ['user_id', 'pesanan_id', 'aksi', 'keterangan', 'waktu'];

    protected function casts(): array
    {
        return ['waktu' => 'datetime'];
    }

    public function user() { return $this->belongsTo(User::class, 'user_id'); }
    public function pesanan() { return $this->belongsTo(Pesanan::class, 'pesanan_id'); }

    /** Catat satu aksi; dipakai semua controller. */
    public static function catat(?int $userId, string $aksi, string $keterangan, ?int $pesananId = null): self
    {
        return self::create([
            'user_id' => $userId, 'pesanan_id' => $pesananId,
            'aksi' => $aksi, 'keterangan' => $keterangan, 'waktu' => now(),
        ]);
    }
}
