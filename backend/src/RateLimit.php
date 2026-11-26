<?php

declare(strict_types=1);

/** Batas percobaan per IP (mis. login 10x/menit), dicatat di file storage/batas/. */
final class RateLimit
{
    public static function cek(string $kunci, int $maks, int $detik): void
    {
        if (env('RATE_LIMIT', '1') === '0') {
            return;
        }
        $folder = AKAR . '/storage/batas';
        if (!is_dir($folder)) {
            @mkdir($folder, 0775, true);
        }
        $f = @fopen($folder . '/' . sha1($kunci), 'c+');
        if ($f === false) {
            return;     // storage tidak bisa ditulis: lebih baik tetap melayani daripada error
        }
        flock($f, LOCK_EX);
        $d = json_decode(stream_get_contents($f) ?: '', true) ?: ['n' => 0, 'sampai' => 0];
        if ($d['sampai'] < time()) {
            $d = ['n' => 0, 'sampai' => time() + $detik];
        }
        $d['n']++;
        ftruncate($f, 0);
        rewind($f);
        fwrite($f, json_encode($d));
        flock($f, LOCK_UN);
        fclose($f);
        if ($d['n'] > $maks) {
            gagal(429, 'Terlalu banyak percobaan, coba lagi sebentar lagi.');
        }
    }
}
