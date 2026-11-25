<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Validation\ValidationException;

class Pesanan extends Model
{
    protected $table = 'pesanan';
    public $timestamps = false;

    protected $fillable = [
        'kode_pesanan', 'token', 'kode_bayar', 'meja_id', 'waiter_id', 'kasir_id', 'nama_pelanggan', 'tanggal',
        'waktu_konfirmasi', 'status', 'total', 'bayar', 'kembalian', 'metode_bayar', 'waktu_bayar', 'waktu_antar',
    ];

    /** token = kunci pelanggan, kode_bayar = isi QR pembayaran; dibuka hanya di tempat yang perlu. */
    protected $hidden = ['token', 'kode_bayar'];

    /** Status yang masih "berjalan" (meja dianggap terisi). */
    public const STATUS_AKTIF = ['menunggu_konfirmasi', 'menunggu_pembayaran', 'lunas'];

    /** Status yang sudah dibayar (masuk laporan penjualan). */
    public const STATUS_DIBAYAR = ['lunas', 'disajikan'];

    /** Perpindahan status yang diizinkan. */
    public const TRANSISI = [
        'menunggu_konfirmasi' => ['menunggu_pembayaran', 'batal'],
        'menunggu_pembayaran' => ['lunas', 'batal'],
        'lunas' => ['disajikan'],
    ];

    protected function casts(): array
    {
        return [
            'tanggal' => 'datetime', 'waktu_konfirmasi' => 'datetime',
            'waktu_bayar' => 'datetime', 'waktu_antar' => 'datetime',
        ];
    }

    public function meja() { return $this->belongsTo(Meja::class, 'meja_id'); }
    public function waiter() { return $this->belongsTo(User::class, 'waiter_id'); }
    public function kasir() { return $this->belongsTo(User::class, 'kasir_id'); }
    public function detail() { return $this->hasMany(DetailPesanan::class, 'pesanan_id'); }

    public function scopeSudahBayar(Builder $q): Builder
    {
        return $q->whereIn('status', self::STATUS_DIBAYAR);
    }

    public function hitungTotal(): int
    {
        return (int) $this->detail()->sum('subtotal');
    }

    public static function hitungKembalian(int $total, int $bayar): int
    {
        return $bayar - $total;
    }

    /** Item hanya boleh diubah selama waitress belum memvalidasi (NF-02). */
    public function bisaDiubah(): bool
    {
        return $this->status === 'menunggu_konfirmasi';
    }

    public function bisaPindahKe(string $statusBaru): bool
    {
        return in_array($statusBaru, self::TRANSISI[$this->status] ?? [], true);
    }

    /** Ubah input item jadi baris detail; harga selalu diambil dari tabel menu. */
    public static function bangunItems(array $items): array
    {
        $menus = Menu::whereIn('id', collect($items)->pluck('menu_id'))->get()->keyBy('id');
        $baris = [];
        $total = 0;
        foreach ($items as $i) {
            $menu = $menus[$i['menu_id']];
            if (! $menu->tersedia) {
                throw ValidationException::withMessages(['items' => "Menu {$menu->nama_menu} sedang habis."]);
            }
            $subtotal = DetailPesanan::hitungSubtotal((int) $i['jumlah'], $menu->harga);
            $baris[] = [
                'menu_id' => $menu->id, 'jumlah' => (int) $i['jumlah'], 'harga_satuan' => $menu->harga,
                'subtotal' => $subtotal, 'catatan' => $i['catatan'] ?? null,
            ];
            $total += $subtotal;
        }

        return [$baris, $total];
    }

    public static function kodeBaru(): string
    {
        $prefix = 'ORD-'.now()->format('Ymd').'-';
        $terakhir = self::where('kode_pesanan', 'like', $prefix.'%')->max('kode_pesanan');
        $urut = $terakhir ? ((int) substr($terakhir, -3)) + 1 : 1;

        return $prefix.str_pad((string) $urut, 3, '0', STR_PAD_LEFT);
    }

    /** Aturan validasi item pesanan (dipakai pelanggan & waitress). */
    public static function aturanItems(): array
    {
        return [
            'items' => ['required', 'array', 'min:1', 'max:50'],
            'items.*.menu_id' => ['required', 'exists:menu,id'],
            'items.*.jumlah' => ['required', 'integer', 'min:1', 'max:99'],
            'items.*.catatan' => ['nullable', 'string', 'max:255'],
        ];
    }
}
