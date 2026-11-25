<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LogAktivitas;
use Illuminate\Http\Request;

class LogController extends Controller
{
    /** F-15: log aktivitas, filter ?user_id=&dari=&sampai=&aksi= (terbaru dulu, 50 per halaman). */
    public function index(Request $request)
    {
        $request->validate([
            'user_id' => ['nullable', 'integer'], 'dari' => ['nullable', 'date'], 'sampai' => ['nullable', 'date'],
        ]);

        return LogAktivitas::with(['user:id,nama,role', 'pesanan:id,kode_pesanan'])
            ->when($request->query('user_id'), fn ($q, $v) => $q->where('user_id', $v))
            ->when($request->query('aksi'), fn ($q, $v) => $q->where('aksi', $v))
            ->when($request->query('dari'), fn ($q, $v) => $q->whereDate('waktu', '>=', $v))
            ->when($request->query('sampai'), fn ($q, $v) => $q->whereDate('waktu', '<=', $v))
            ->orderByDesc('waktu')->orderByDesc('id')
            ->paginate(50);
    }
}
