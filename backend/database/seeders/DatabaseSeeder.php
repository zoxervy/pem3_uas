<?php

namespace Database\Seeders;

use App\Models\Kategori;
use App\Models\Meja;
use App\Models\Menu;
use App\Models\User;
use Illuminate\Database\Seeder;

/** Data awal untuk demo. Password demo ada di README, WAJIB diganti kalau dipakai sungguhan. */
class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::create(['nama' => 'Administrator', 'username' => 'admin', 'password' => 'admin123', 'role' => 'admin']);
        User::create(['nama' => 'Rina', 'username' => 'rina', 'password' => 'waitress123', 'role' => 'waitress', 'no_hp' => '081200000001']);
        User::create(['nama' => 'Budi', 'username' => 'budi', 'password' => 'waitress123', 'role' => 'waitress', 'no_hp' => '081200000002']);
        User::create(['nama' => 'Sari', 'username' => 'sari', 'password' => 'kasir123', 'role' => 'kasir', 'no_hp' => '081200000003']);

        $makanan = Kategori::create(['nama_kategori' => 'Makanan']);
        $minuman = Kategori::create(['nama_kategori' => 'Minuman']);
        $snack = Kategori::create(['nama_kategori' => 'Snack']);

        $menu = [
            [$makanan, 'Nasi Goreng Spesial', 25000, 'Nasi goreng dengan telur dan ayam suwir'],
            [$makanan, 'Mie Goreng', 22000, 'Mie goreng sayur dan telur'],
            [$makanan, 'Ayam Bakar', 30000, 'Ayam bakar bumbu kecap + nasi'],
            [$makanan, 'Soto Ayam', 20000, 'Soto ayam kuah bening'],
            [$minuman, 'Es Teh Manis', 5000, null],
            [$minuman, 'Es Jeruk', 8000, null],
            [$minuman, 'Kopi Hitam', 10000, null],
            [$minuman, 'Air Mineral', 4000, null],
            [$snack, 'Kentang Goreng', 15000, null],
            [$snack, 'Pisang Goreng', 12000, null],
        ];
        foreach ($menu as [$kat, $nama, $harga, $desk]) {
            Menu::create(['kategori_id' => $kat->id, 'nama_menu' => $nama, 'harga' => $harga, 'deskripsi' => $desk]);
        }

        // simulasi: 3 meja, masing-masing punya QR sendiri (kode_qr dibuat otomatis)
        foreach ([1 => 4, 2 => 4, 3 => 6] as $nomor => $kapasitas) {
            Meja::create(['nomor_meja' => (string) $nomor, 'kapasitas' => $kapasitas]);
        }
    }
}
