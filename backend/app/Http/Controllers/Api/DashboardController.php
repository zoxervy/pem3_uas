<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Meja;
use App\Models\Pesanan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    /** F-02: isi dashboard menyesuaikan role pemanggil. */
    public function index(Request $request)
    {
        $user = $request->user();
        $hariIni = fn () => Pesanan::sudahBayar()->whereDate('waktu_bayar', now()->toDateString());

        if ($user->isAdmin()) {
            return ['role' => 'admin',
                'pendapatan_hari_ini' => (int) $hariIni()->sum('total'),
                'jumlah_transaksi' => $hariIni()->count(),
                'menu_terlaris' => DB::table('detail_pesanan')
                    ->join('pesanan', 'pesanan.id', '=', 'detail_pesanan.pesanan_id')
                    ->join('menu', 'menu.id', '=', 'detail_pesanan.menu_id')
                    ->whereIn('pesanan.status', Pesanan::STATUS_DIBAYAR)
                    ->groupBy('menu.id', 'menu.nama_menu')
                    ->select('menu.nama_menu', DB::raw('SUM(detail_pesanan.jumlah) as terjual'))
                    ->orderByDesc('terjual')->limit(5)->get(),
                'performa_waitress' => $hariIni()->join('users', 'users.id', '=', 'pesanan.waiter_id')
                    ->groupBy('users.id', 'users.nama')
                    ->select('users.nama', DB::raw('COUNT(*) as transaksi'), DB::raw('SUM(pesanan.total) as total'))
                    ->orderByDesc('total')->get(),
            ];
        }

        if ($user->isWaitress()) {
            $tugasSaya = fn (string $status) => Pesanan::where('waiter_id', $user->id)->where('status', $status)->count();

            return ['role' => 'waitress',
                'meja' => Meja::orderByRaw('CAST(nomor_meja AS UNSIGNED), nomor_meja')->get(),
                'belum_ditugaskan' => Pesanan::whereNull('waiter_id')->where('status', 'menunggu_konfirmasi')->count(),
                'perlu_validasi' => $tugasSaya('menunggu_konfirmasi'),
                'menunggu_bayar' => $tugasSaya('menunggu_pembayaran'),
                'siap_antar' => $tugasSaya('lunas'),
            ];
        }

        return ['role' => 'kasir',
            'pesanan_masuk' => Pesanan::whereNull('waiter_id')->where('status', 'menunggu_konfirmasi')->count(),
            'menunggu_bayar' => Pesanan::where('status', 'menunggu_pembayaran')->count(),
            'pendapatan_hari_ini' => (int) $hariIni()->sum('total'),
            'tunai_shift' => (int) $hariIni()->where('kasir_id', $user->id)->sum('total'),
            'transaksi_hari_ini' => $hariIni()->count(),
        ];
    }
}
