<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/** Pembatas akses per role. Pemakaian di route: ->middleware('role:admin,kasir') */
class CekRole
{
    public function handle(Request $request, Closure $next, string ...$roles)
    {
        $user = $request->user();

        if (! $user || ! $user->aktif) {
            return response()->json(['message' => 'Akun tidak aktif atau belum login.'], 403);
        }
        if (! in_array($user->role, $roles, true)) {
            return response()->json(['message' => 'Anda tidak punya akses ke fitur ini.'], 403);
        }

        return $next($request);
    }
}
