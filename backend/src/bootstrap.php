<?php

declare(strict_types=1);

const AKAR = __DIR__ . '/..';

/** Baca konfigurasi dari environment, lalu dari file .env (format KUNCI=nilai). */
function env(string $kunci, ?string $bawaan = null): ?string
{
    static $isi = null;
    if ($isi === null) {
        $isi = [];
        $file = AKAR . '/.env';
        if (is_file($file)) {
            foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $baris) {
                $baris = trim($baris);
                if ($baris === '' || $baris[0] === '#' || !str_contains($baris, '=')) {
                    continue;
                }
                [$k, $v] = explode('=', $baris, 2);
                $isi[trim($k)] = trim(trim($v), "\"'");
            }
        }
    }
    $sistem = getenv($kunci);

    return $sistem !== false ? $sistem : ($isi[$kunci] ?? $bawaan);
}

// Waktu di database disimpan dalam zona waktu aplikasi (mis. WITA).
date_default_timezone_set(env('APP_TIMEZONE', 'Asia/Makassar'));

foreach (['Db', 'Http', 'Validasi', 'Format', 'Auth', 'RateLimit', 'App'] as $f) {
    require __DIR__ . "/$f.php";
}
foreach (glob(__DIR__ . '/handler/*.php') as $f) {
    require $f;
}
require __DIR__ . '/rute.php';
