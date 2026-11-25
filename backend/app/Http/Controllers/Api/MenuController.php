<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;

class MenuController extends Controller
{
    private function aturan(): array
    {
        return [
            'kategori_id' => ['required', 'exists:kategori,id'],
            'nama_menu' => ['required', 'string', 'max:100'],
            'harga' => ['required', 'integer', 'min:0'],
            'deskripsi' => ['nullable', 'string'],
            'foto' => ['nullable', 'string', 'max:255'],
            'tersedia' => ['sometimes', 'boolean'],
        ];
    }

    public function index(Request $request)
    {
        return Menu::with('kategori')
            ->when($request->query('kategori_id'), fn ($q, $id) => $q->where('kategori_id', $id))
            ->orderBy('nama_menu')
            ->get();
    }

    public function store(Request $request)
    {
        return response()->json(Menu::create($request->validate($this->aturan()))->load('kategori'), 201);
    }

    public function update(Request $request, Menu $menu)
    {
        $menu->update($request->validate($this->aturan()));

        return $menu->load('kategori');
    }

    public function destroy(Menu $menu)
    {
        try {
            $menu->delete();
        } catch (QueryException) {
            return response()->json(['message' => 'Menu sudah pernah dipesan, tandai "habis" saja.'], 409);
        }

        return response()->json(['message' => 'Menu dihapus.']);
    }
}
