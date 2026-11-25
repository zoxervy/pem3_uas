<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Kategori;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;

class KategoriController extends Controller
{
    public function index()
    {
        return Kategori::orderBy('nama_kategori')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate(['nama_kategori' => ['required', 'string', 'max:50']]);

        return response()->json(Kategori::create($data), 201);
    }

    public function update(Request $request, Kategori $kategori)
    {
        $data = $request->validate(['nama_kategori' => ['required', 'string', 'max:50']]);
        $kategori->update($data);

        return $kategori;
    }

    public function destroy(Kategori $kategori)
    {
        try {
            $kategori->delete();
        } catch (QueryException) {
            return response()->json(['message' => 'Kategori masih dipakai oleh menu, tidak bisa dihapus.'], 409);
        }

        return response()->json(['message' => 'Kategori dihapus.']);
    }
}
