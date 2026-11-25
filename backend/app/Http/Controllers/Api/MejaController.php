<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Meja;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class MejaController extends Controller
{
    public function index(Request $request)
    {
        $meja = Meja::orderByRaw('CAST(nomor_meja AS UNSIGNED), nomor_meja')->get();

        // kode QR hanya untuk admin (dipakai mencetak QR meja)
        return $request->user()->isAdmin() ? $meja->each->makeVisible('kode_qr') : $meja;
    }

    /** Ganti kode QR meja (QR lama tidak berlaku lagi), mis. kalau QR tercetak hilang/disalahgunakan. */
    public function qrBaru(Meja $meja)
    {
        $meja->update(['kode_qr' => \Illuminate\Support\Str::random(32)]);

        return $meja->makeVisible('kode_qr');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nomor_meja' => ['required', 'string', 'max:10', 'unique:meja,nomor_meja'],
            'kapasitas' => ['nullable', 'integer', 'min:1'],
        ]);

        return response()->json(Meja::create($data)->makeVisible('kode_qr'), 201);
    }

    public function update(Request $request, Meja $meja)
    {
        $data = $request->validate([
            'nomor_meja' => ['required', 'string', 'max:10', Rule::unique('meja', 'nomor_meja')->ignore($meja->id)],
            'kapasitas' => ['nullable', 'integer', 'min:1'],
        ]);
        $meja->update($data);

        return $meja->makeVisible('kode_qr');
    }

    public function destroy(Meja $meja)
    {
        try {
            $meja->delete();
        } catch (QueryException) {
            return response()->json(['message' => 'Meja sudah punya riwayat pesanan, tidak bisa dihapus.'], 409);
        }

        return response()->json(['message' => 'Meja dihapus.']);
    }
}
