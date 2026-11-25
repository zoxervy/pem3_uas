<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LogAktivitas;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class PembayaranController extends Controller
{
    /** F-11: bayar tunai di kasir. Simpan kasir_id, hitung kembalian, status lunas. */
    public function konfirmasi(Request $request, Pesanan $pesanan)
    {
        $bayar = (int) $request->validate(['bayar' => ['required', 'integer', 'min:0']])['bayar'];
        $kasir = $request->user();

        DB::transaction(function () use ($pesanan, $bayar, $kasir) {
            $pesanan = Pesanan::lockForUpdate()->findOrFail($pesanan->id);
            if ($pesanan->status !== 'menunggu_pembayaran') {
                throw ValidationException::withMessages(['status' => 'Pesanan ini tidak sedang menunggu pembayaran.']);
            }
            if ($bayar < $pesanan->total) {
                throw ValidationException::withMessages(['bayar' => 'Uang bayar kurang dari total tagihan.']);
            }

            $pesanan->update([
                'kasir_id' => $kasir->id,
                'bayar' => $bayar,
                'kembalian' => Pesanan::hitungKembalian($pesanan->total, $bayar),
                'waktu_bayar' => now(),
                'metode_bayar' => 'tunai',
                'status' => 'lunas',
            ]);

            LogAktivitas::catat($kasir->id, 'konfirmasi_bayar',
                "Kasir {$kasir->nama} menerima pembayaran tunai {$pesanan->kode_pesanan} (total {$pesanan->total})",
                $pesanan->id);
        });

        return $pesanan->fresh()->load(['meja', 'waiter', 'kasir', 'detail.menu']);
    }

    /** F-12: riwayat transaksi lunas, filter ?dari=YYYY-MM-DD&sampai=YYYY-MM-DD. */
    public function riwayat(Request $request)
    {
        $request->validate(['dari' => ['nullable', 'date'], 'sampai' => ['nullable', 'date']]);

        return Pesanan::with(['meja', 'waiter:id,nama', 'kasir:id,nama'])
            ->sudahBayar()
            ->when($request->query('dari'), fn ($q, $d) => $q->whereDate('waktu_bayar', '>=', $d))
            ->when($request->query('sampai'), fn ($q, $d) => $q->whereDate('waktu_bayar', '<=', $d))
            ->orderByDesc('waktu_bayar')
            ->limit(500)
            ->get();
    }
}
