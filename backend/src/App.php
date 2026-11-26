<?php

declare(strict_types=1);

/** Router kecil: cocokkan method + path, cek login & role, lalu panggil handler. */
final class App
{
    private array $rute = [];

    /**
     * @param ?array $role  null = publik, [] = cukup login, ['admin', ...] = role tertentu
     * @param ?array $batas [nama, maks per menit] untuk membatasi percobaan
     */
    public function rute(string $method, string $pola, callable $handler, ?array $role = null, ?array $batas = null): void
    {
        $regex = preg_replace(['#\{id\}#', '#\{(\w+)\}#'], ['(?P<id>\d+)', '(?P<$1>[A-Za-z0-9]+)'], $pola);
        $this->rute[] = [$method, "#^$regex$#", $handler, $role, $batas];
    }

    /** @return array{0:int, 1:mixed} kode status dan data JSON */
    public function tangani(Req $req): array
    {
        try {
            if ($req->method === 'OPTIONS') {
                return [204, null];
            }
            $pathCocok = false;
            foreach ($this->rute as [$method, $regex, $handler, $role, $batas]) {
                if (!preg_match($regex, $req->path, $cocok)) {
                    continue;
                }
                $pathCocok = true;
                if ($method !== $req->method) {
                    continue;
                }
                $req->param = array_filter($cocok, 'is_string', ARRAY_FILTER_USE_KEY);
                if ($batas !== null) {
                    RateLimit::cek($batas[0] . ':' . $req->ip, $batas[1], 60);
                }
                if ($role !== null) {
                    $req->user = $this->cekAkses($req, $role);
                }
                $hasil = $handler($req);

                return $hasil instanceof Respon ? [$hasil->status, $hasil->data] : [200, $hasil];
            }
            gagal($pathCocok ? 405 : 404, $pathCocok ? 'Method tidak didukung.' : 'Endpoint tidak ditemukan.');
        } catch (HttpError $e) {
            return [$e->status, ['message' => $e->getMessage()] + ($e->errors ? ['errors' => $e->errors] : [])];
        } catch (Throwable $e) {
            error_log('[resto-api] ' . $e);

            return [500, ['message' => env('APP_DEBUG') === 'true' ? $e->getMessage() : 'Terjadi kesalahan di server.']];
        }
    }

    private function cekAkses(Req $req, array $role): array
    {
        $user = Auth::userDariToken($req->token) ?? gagal(401, 'Unauthenticated.');
        if (!$user['aktif']) {
            gagal(403, 'Akun tidak aktif atau belum login.');
        }
        if ($role && !in_array($user['role'], $role, true)) {
            gagal(403, 'Anda tidak punya akses ke fitur ini.');
        }

        return $user;
    }
}
