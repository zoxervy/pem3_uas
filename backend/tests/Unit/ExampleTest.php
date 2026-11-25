<?php

namespace Tests\Unit;

use App\Models\DetailPesanan;
use App\Models\Meja;
use App\Models\Pesanan;
use App\Models\User;
use PHPUnit\Framework\TestCase;

/** Unit test logika murni di model (sesuai rencana unit testing di rancangan). */
class ExampleTest extends TestCase
{
    public function test_hitung_subtotal(): void
    {
        $this->assertSame(30000, DetailPesanan::hitungSubtotal(2, 15000));
    }

    public function test_hitung_kembalian(): void
    {
        $this->assertSame(5000, Pesanan::hitungKembalian(45000, 50000));
    }

    public function test_pesanan_hanya_bisa_diubah_sebelum_divalidasi(): void
    {
        $this->assertTrue((new Pesanan(['status' => 'menunggu_konfirmasi']))->bisaDiubah());
        foreach (['menunggu_pembayaran', 'lunas', 'disajikan', 'batal'] as $st) {
            $this->assertFalse((new Pesanan(['status' => $st]))->bisaDiubah(), $st);
        }
    }

    public function test_alur_status_yang_diizinkan(): void
    {
        $this->assertTrue((new Pesanan(['status' => 'menunggu_konfirmasi']))->bisaPindahKe('menunggu_pembayaran'));
        $this->assertFalse((new Pesanan(['status' => 'menunggu_konfirmasi']))->bisaPindahKe('lunas'));   // harus divalidasi dulu
        $this->assertTrue((new Pesanan(['status' => 'menunggu_pembayaran']))->bisaPindahKe('batal'));
        $this->assertFalse((new Pesanan(['status' => 'menunggu_pembayaran']))->bisaPindahKe('disajikan')); // harus bayar dulu
        $this->assertTrue((new Pesanan(['status' => 'lunas']))->bisaPindahKe('disajikan'));
        $this->assertFalse((new Pesanan(['status' => 'lunas']))->bisaPindahKe('batal'));                // sudah dibayar
    }

    public function test_meja_kosong(): void
    {
        $this->assertFalse((new Meja(['status' => 'terisi']))->isKosong());
        $this->assertTrue((new Meja(['status' => 'kosong']))->isKosong());
    }

    public function test_role_user(): void
    {
        $u = new User(['role' => 'waitress']);
        $this->assertFalse($u->isKasir());
        $this->assertTrue($u->isWaitress());
        $this->assertFalse($u->isAdmin());
    }
}
