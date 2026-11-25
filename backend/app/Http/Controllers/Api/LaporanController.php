<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LaporanController extends Controller
{
    /** F-13: laporan penjualan (hanya pesanan lunas) per periode, per waitress, dan per menu. */
    public function penjualan(Request $request)
    {
        $v = $request->validate(['dari' => ['nullable', 'date'], 'sampai' => ['nullable', 'date', 'after_or_equal:dari']]);
        $dari = $v['dari'] ?? now()->toDateString();
        $sampai = $v['sampai'] ?? $dari;

        $lunas = fn () => Pesanan::sudahBayar()
            ->whereDate('waktu_bayar', '>=', $dari)->whereDate('waktu_bayar', '<=', $sampai);

        $perWaitress = $lunas()->join('users', 'users.id', '=', 'pesanan.waiter_id')
            ->groupBy('users.id', 'users.nama')
            ->select('users.id as waiter_id', 'users.nama', DB::raw('COUNT(*) as jumlah_transaksi'), DB::raw('SUM(pesanan.total) as total'))
            ->orderByDesc('total')->get();

        $perMenu = $lunas()->join('detail_pesanan', 'detail_pesanan.pesanan_id', '=', 'pesanan.id')
            ->join('menu', 'menu.id', '=', 'detail_pesanan.menu_id')
            ->groupBy('menu.id', 'menu.nama_menu')
            ->select('menu.id as menu_id', 'menu.nama_menu', DB::raw('SUM(detail_pesanan.jumlah) as terjual'), DB::raw('SUM(detail_pesanan.subtotal) as total'))
            ->orderByDesc('terjual')->get();

        return [
            'dari' => $dari,
            'sampai' => $sampai,
            'jumlah_transaksi' => $lunas()->count(),
            'total_pendapatan' => (int) $lunas()->sum('total'),
            'per_waitress' => $perWaitress,
            'per_menu' => $perMenu,
        ];
    }
}
