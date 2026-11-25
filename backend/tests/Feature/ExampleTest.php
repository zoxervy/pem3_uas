<?php

namespace Tests\Feature;

use App\Models\Kategori;
use App\Models\LogAktivitas;
use App\Models\Meja;
use App\Models\Menu;
use App\Models\Pesanan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    private function sebagai(User $u): User
    {
        Sanctum::actingAs($u);

        return $u;
    }

    private function siapkan(): array
    {
        $k = Kategori::create(['nama_kategori' => 'Makanan']);
        $nasi = Menu::create(['kategori_id' => $k->id, 'nama_menu' => 'Nasi Goreng', 'harga' => 25000]);
        $teh = Menu::create(['kategori_id' => $k->id, 'nama_menu' => 'Es Teh', 'harga' => 5000]);
        $meja = Meja::create(['nomor_meja' => '1', 'kapasitas' => 4]);

        return [$nasi, $teh, $meja];
    }

    /** Pelanggan mengirim pesanan lewat QR; kembalikan [id, token]. */
    private function pelangganPesan(Meja $meja, array $items): array
    {
        $res = $this->postJson("/api/publik/meja/{$meja->kode_qr}/pesanan", ['nama_pelanggan' => 'Andi', 'items' => $items])
            ->assertCreated()->assertJsonPath('status', 'menunggu_konfirmasi')->assertJsonStructure(['token']);

        return [$res->json('id'), $res->json('token')];
    }

    public function test_login_benar_salah_dan_nonaktif(): void
    {
        User::factory()->kasir()->create(['username' => 'sari', 'password' => 'rahasia1']);
        User::factory()->kasir()->create(['username' => 'off', 'password' => 'rahasia1', 'aktif' => false]);

        $this->postJson('/api/login', ['username' => 'sari', 'password' => 'salah'])->assertStatus(401);
        $this->postJson('/api/login', ['username' => 'off', 'password' => 'rahasia1'])->assertStatus(403);
        $this->postJson('/api/login', ['username' => 'sari', 'password' => 'rahasia1'])
            ->assertOk()->assertJsonPath('user.role', 'kasir')->assertJsonStructure(['token']);
    }

    public function test_akses_dibatasi_per_role(): void
    {
        $this->getJson('/api/menu')->assertStatus(401);
        $this->sebagai(User::factory()->waitress()->create());
        $this->getJson('/api/users')->assertStatus(403);
        $this->postJson('/api/menu', [])->assertStatus(403);
        $this->getJson('/api/waitress')->assertStatus(403);        // penugasan hanya kasir
    }

    public function test_qr_meja_tidak_dikenal_dan_kode_qr_tidak_bocor(): void
    {
        [, , $meja] = $this->siapkan();
        $this->getJson('/api/publik/meja/ngawur')->assertNotFound();
        $this->getJson("/api/publik/meja/{$meja->kode_qr}")->assertOk()
            ->assertJsonPath('meja.nomor_meja', '1')->assertJsonCount(2, 'menu')->assertJsonMissingPath('meja.kode_qr');

        $this->sebagai(User::factory()->waitress()->create());
        $this->assertArrayNotHasKey('kode_qr', $this->getJson('/api/meja')->json(0));     // waitress tidak melihat kode QR
        $this->sebagai(User::factory()->admin()->create());
        $this->assertNotEmpty($this->getJson('/api/meja')->json('0.kode_qr'));            // admin melihat (untuk cetak)
    }

    public function test_alur_lengkap_qr_tugaskan_validasi_bayar_antar(): void
    {
        [$nasi, $teh, $meja] = $this->siapkan();
        $rina = User::factory()->waitress()->create(['nama' => 'Rina']);
        $budi = User::factory()->waitress()->create(['nama' => 'Budi']);
        $kasir = User::factory()->kasir()->create();

        // 1. pelanggan scan QR & pesan (harga dihitung server)
        [$id, $token] = $this->pelangganPesan($meja, [['menu_id' => $nasi->id, 'jumlah' => 2], ['menu_id' => $teh->id, 'jumlah' => 1]]);
        $this->assertSame(55000, Pesanan::find($id)->total);
        $this->assertSame('terisi', $meja->fresh()->status);
        $this->getJson("/api/publik/pesanan/{$token}")->assertOk()->assertJsonPath('status', 'menunggu_konfirmasi')
            ->assertJsonMissingPath('kode_bayar');

        // 2. kasir menugaskan ke Rina
        $this->sebagai($kasir);
        $this->getJson('/api/waitress')->assertOk()->assertJsonCount(2);
        $this->postJson("/api/pesanan/$id/tugaskan", ['waiter_id' => $kasir->id])->assertStatus(422);  // bukan waitress
        $this->postJson("/api/pesanan/$id/tugaskan", ['waiter_id' => $rina->id])->assertOk()->assertJsonPath('waiter.nama', 'Rina');

        // waitress lain tidak bisa memvalidasi / mengambil
        $this->sebagai($budi);
        $this->assertCount(0, $this->getJson('/api/pesanan')->json());
        $this->postJson("/api/pesanan/$id/konfirmasi")->assertStatus(403);
        $this->postJson("/api/pesanan/$id/ambil")->assertStatus(422);

        // 3. Rina validasi di meja, ubah item, lalu QR bayar dibuat
        $this->sebagai($rina);
        $this->putJson("/api/pesanan/$id/items", ['items' => [['menu_id' => $nasi->id, 'jumlah' => 3]]])->assertOk()->assertJsonPath('total', 75000);
        $this->postJson("/api/publik/bayar/apa-saja")->assertNotFound();
        $kode = $this->postJson("/api/pesanan/$id/konfirmasi")->assertOk()
            ->assertJsonPath('status', 'menunggu_pembayaran')->json('kode_bayar');
        $this->assertNotEmpty($kode);
        $this->putJson("/api/pesanan/$id/items", ['items' => [['menu_id' => $teh->id, 'jumlah' => 1]]])->assertStatus(422); // NF-02
        $this->postJson("/api/pesanan/$id/antar")->assertStatus(422);                    // belum bayar

        // 4. pelanggan scan QR bayar
        $this->getJson("/api/publik/bayar/{$kode}")->assertOk()->assertJsonPath('total', 75000);
        $this->postJson("/api/publik/bayar/{$kode}")->assertOk()->assertJsonPath('status', 'lunas')->assertJsonPath('metode_bayar', 'qris');
        $this->postJson("/api/publik/bayar/{$kode}")->assertStatus(422);                 // tidak bisa bayar dua kali
        $this->postJson("/api/pesanan/$id/batal")->assertStatus(422);                    // sudah dibayar

        // 5. Rina mengantar
        $this->postJson("/api/pesanan/$id/antar")->assertOk()->assertJsonPath('status', 'disajikan');
        $this->assertSame('kosong', $meja->fresh()->status);
        $this->getJson("/api/publik/pesanan/{$token}")->assertJsonPath('status', 'disajikan');

        foreach (['pesan_qr', 'tugaskan', 'ubah_pesanan', 'konfirmasi_pesanan', 'bayar_online', 'antar_pesanan'] as $aksi) {
            $this->assertDatabaseHas('log_aktivitas', ['aksi' => $aksi, 'pesanan_id' => $id]);
        }
        $this->assertNull(LogAktivitas::where('aksi', 'pesan_qr')->first()->user_id);   // aksi pelanggan

        // laporan menghitung pesanan yang sudah dibayar
        $this->sebagai(User::factory()->admin()->create());
        $this->getJson('/api/laporan/penjualan')->assertOk()->assertJsonPath('total_pendapatan', 75000)
            ->assertJsonPath('per_waitress.0.nama', 'Rina');
        $this->getJson('/api/dashboard')->assertJsonPath('pendapatan_hari_ini', 75000);
        $this->getJson('/api/riwayat')->assertOk()->assertJsonCount(1);
    }

    public function test_waitress_ambil_sendiri_dan_kasir_terima_tunai(): void
    {
        [$nasi, , $meja] = $this->siapkan();
        $rina = User::factory()->waitress()->create();
        [$id] = $this->pelangganPesan($meja, [['menu_id' => $nasi->id, 'jumlah' => 2]]);

        $this->sebagai($rina);
        $this->assertCount(1, $this->getJson('/api/pesanan')->json());                 // pesanan belum ditugaskan terlihat
        $this->postJson("/api/pesanan/$id/ambil")->assertOk();
        $this->postJson("/api/pesanan/$id/konfirmasi")->assertOk();

        // pelanggan tidak bisa QRIS -> bayar tunai di kasir
        $kasir = $this->sebagai(User::factory()->kasir()->create());
        $this->postJson("/api/pesanan/$id/bayar", ['bayar' => 40000])->assertStatus(422);   // kurang
        $this->postJson("/api/pesanan/$id/bayar", ['bayar' => 60000])->assertOk()
            ->assertJsonPath('status', 'lunas')->assertJsonPath('kembalian', 10000)
            ->assertJsonPath('metode_bayar', 'tunai')->assertJsonPath('kasir_id', $kasir->id);
    }

    public function test_batal_sebelum_bayar_mengosongkan_meja(): void
    {
        [$nasi, , $meja] = $this->siapkan();
        [$id] = $this->pelangganPesan($meja, [['menu_id' => $nasi->id, 'jumlah' => 1]]);
        $this->sebagai(User::factory()->kasir()->create());
        $this->postJson("/api/pesanan/$id/batal")->assertOk()->assertJsonPath('status', 'batal');
        $this->assertSame('kosong', $meja->fresh()->status);
        $this->assertDatabaseHas('log_aktivitas', ['aksi' => 'batal', 'pesanan_id' => $id]);
    }

    public function test_menu_habis_ditolak_dan_input_divalidasi(): void
    {
        [$nasi, , $meja] = $this->siapkan();
        $nasi->update(['tersedia' => false]);
        $this->postJson("/api/publik/meja/{$meja->kode_qr}/pesanan", ['items' => [['menu_id' => $nasi->id, 'jumlah' => 1]]])->assertStatus(422);
        $this->postJson("/api/publik/meja/{$meja->kode_qr}/pesanan", ['items' => []])->assertStatus(422);
        $this->postJson("/api/publik/meja/{$meja->kode_qr}/pesanan", ['items' => [['menu_id' => 999, 'jumlah' => 1]]])->assertStatus(422);
        $this->assertSame(0, Pesanan::count());
    }

    public function test_admin_kelola_user_dan_qr_baru(): void
    {
        [, , $meja] = $this->siapkan();
        $admin = $this->sebagai(User::factory()->admin()->create());
        $this->postJson('/api/users', ['nama' => 'Dewi', 'username' => 'dewi', 'password' => '123456', 'role' => 'kasir'])->assertCreated();
        $this->assertTrue(\Hash::check('123456', User::where('username', 'dewi')->first()->password));
        $this->postJson('/api/users', ['nama' => 'X', 'username' => 'dewi', 'password' => '123456', 'role' => 'kasir'])->assertStatus(422);
        $this->putJson("/api/users/{$admin->id}", ['nama' => 'A', 'username' => $admin->username, 'role' => 'admin', 'aktif' => false])->assertStatus(422);

        $lama = $meja->kode_qr;
        $baru = $this->postJson("/api/meja/{$meja->id}/qr-baru")->assertOk()->json('kode_qr');
        $this->assertNotSame($lama, $baru);
        $this->getJson("/api/publik/meja/{$lama}")->assertNotFound();                  // QR lama tidak berlaku
    }
}
