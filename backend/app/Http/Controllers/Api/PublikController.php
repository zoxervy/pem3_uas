<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kategori;
use App\Models\LogAktivitas;
use App\Models\Meja;
use App\Models\Menu;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

/** Endpoint tanpa login untuk pelanggan yang scan QR. */
class PublikController extends Controller
{
    private function mejaDariKode(string $kode): Meja
    {
        return Meja::where('kode_qr', $kode)->first() ?? abort(404, 'QR meja tidak dikenali.');
    }

    /** Menu untuk meja yang QR-nya di-scan. */
    public function menu(string $kode)
    {
        $meja = $this->mejaDariKode($kode);

        return [
            'meja' => ['nomor_meja' => $meja->nomor_meja],
            'kategori' => Kategori::orderBy('nama_kategori')->get(),
            'menu' => Menu::with('kategori')->where('tersedia', true)->orderBy('nama_menu')->get(),
        ];
    }

    /** Pelanggan mengirim pesanan; masuk ke kasir dengan status menunggu_konfirmasi. */
    public function pesan(Request $request, string $kode)
    {
        $meja = $this->mejaDariKode($kode);
        $data = $request->validate(['nama_pelanggan' => ['nullable', 'string', 'max:100']] + Pesanan::aturanItems());

        $pesanan = DB::transaction(function () use ($data, $meja) {
            [$baris, $total] = Pesanan::bangunItems($data['items']);
            $pesanan = Pesanan::create([
                'kode_pesanan' => Pesanan::kodeBaru(),
                'token' => Str::random(40),
                'meja_id' => $meja->id,
                'nama_pelanggan' => $data['nama_pelanggan'] ?? null,
                'tanggal' => now(),
                'status' => 'menunggu_konfirmasi',
                'total' => $total,
            ]);
            $pesanan->detail()->createMany($baris);
            $meja->perbaruiStatus();
            LogAktivitas::catat(null, 'pesan_qr', "Pelanggan meja {$meja->nomor_meja} mengirim pesanan {$pesanan->kode_pesanan}", $pesanan->id);

            return $pesanan;
        });

        return response()->json($pesanan->load(['meja', 'detail.menu'])->makeVisible('token'), 201);
    }

    /** Status pesanan untuk layar HP pelanggan (diakses dengan token rahasia). */
    public function status(string $token)
    {
        $p = Pesanan::where('token', $token)->first() ?? abort(404, 'Pesanan tidak ditemukan.');

        return $p->load(['meja', 'detail.menu', 'waiter:id,nama']);
    }

    /** Rincian tagihan saat QR pembayaran di tablet waitress di-scan. */
    public function infoBayar(string $kode)
    {
        $p = Pesanan::where('kode_bayar', $kode)->first() ?? abort(404, 'Kode pembayaran tidak dikenali.');

        return $p->load(['meja', 'detail.menu']);
    }

    /** Pembayaran mode simulasi (pengganti QRIS sungguhan untuk demo). */
    public function bayar(string $kode)
    {
        abort_unless(config('services.pembayaran.mode') === 'simulasi', 404);
        $id = Pesanan::where('kode_bayar', $kode)->value('id') ?? abort(404, 'Kode pembayaran tidak dikenali.');

        $p = DB::transaction(function () use ($id) {
            $p = Pesanan::lockForUpdate()->findOrFail($id);
            if ($p->status !== 'menunggu_pembayaran') {
                throw ValidationException::withMessages(['status' => 'Pesanan ini tidak sedang menunggu pembayaran.']);
            }
            $p->update([
                'status' => 'lunas', 'bayar' => $p->total, 'kembalian' => 0,
                'metode_bayar' => 'qris', 'waktu_bayar' => now(),
            ]);
            LogAktivitas::catat(null, 'bayar_online', "Pesanan {$p->kode_pesanan} dibayar lewat QR (simulasi), total {$p->total}", $p->id);

            return $p;
        });

        return $p->load(['meja', 'detail.menu']);
    }
}
