<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index()
    {
        return User::orderBy('role')->orderBy('nama')->get();
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:100'],
            'username' => ['required', 'string', 'max:50', 'unique:users,username'],
            'password' => ['required', 'string', 'min:6'],
            'role' => ['required', Rule::in(['admin', 'waitress', 'kasir'])],
            'no_hp' => ['nullable', 'string', 'max:20'],
            'aktif' => ['sometimes', 'boolean'],
        ]);

        return response()->json(User::create($data), 201);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'nama' => ['required', 'string', 'max:100'],
            'username' => ['required', 'string', 'max:50', Rule::unique('users', 'username')->ignore($user->id)],
            'password' => ['nullable', 'string', 'min:6'],   // kosong = password tidak diganti
            'role' => ['required', Rule::in(['admin', 'waitress', 'kasir'])],
            'no_hp' => ['nullable', 'string', 'max:20'],
            'aktif' => ['sometimes', 'boolean'],
        ]);
        if (empty($data['password'])) {
            unset($data['password']);
        }
        // admin tidak boleh menonaktifkan / menurunkan role dirinya sendiri
        if ($user->id === $request->user()->id && (($data['aktif'] ?? true) === false || $data['role'] !== 'admin')) {
            return response()->json(['message' => 'Anda tidak bisa menonaktifkan atau mengubah role akun sendiri.'], 422);
        }

        $user->update($data);
        if (($data['aktif'] ?? true) === false) {
            $user->tokens()->delete();   // paksa logout semua sesi akun yang dinonaktifkan
        }

        return $user;
    }

    public function destroy(Request $request, User $user)
    {
        if ($user->id === $request->user()->id) {
            return response()->json(['message' => 'Tidak bisa menghapus akun sendiri.'], 422);
        }
        try {
            $user->delete();
        } catch (QueryException) {
            return response()->json(['message' => 'User punya riwayat transaksi, nonaktifkan saja.'], 409);
        }

        return response()->json(['message' => 'User dihapus.']);
    }
}
