<?php

declare(strict_types=1);

// Siapkan backend di komputer lokal (Laragon):  php setup.php
// Membuat .env (bila belum ada), database, tabel, dan data demo.
// Database yang sudah berisi tabel tidak disentuh, kecuali dijalankan dengan:  php setup.php --reset

if (PHP_SAPI !== 'cli') {
    exit;
}
chdir(__DIR__);
if (!is_file('.env')) {
    copy('.env.example', '.env');
    echo "• .env dibuat dari .env.example\n";
}
require __DIR__ . '/src/bootstrap.php';

$nama = env('DB_DATABASE', 'resto');
if (!preg_match('/^\w+$/', $nama)) {
    exit("DB_DATABASE hanya boleh huruf, angka, dan underscore.\n");
}
$socket = env('DB_SOCKET', '');
$dsn = $socket !== '' ? "mysql:unix_socket=$socket;charset=utf8mb4"
    : 'mysql:host=' . env('DB_HOST', '127.0.0.1') . ';port=' . env('DB_PORT', '3306') . ';charset=utf8mb4';
try {
    $server = new PDO($dsn, env('DB_USERNAME', 'root'), env('DB_PASSWORD', ''), [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
} catch (PDOException $e) {
    exit("Gagal terhubung ke MySQL: {$e->getMessage()}\nPastikan MySQL di Laragon sudah Start dan isi .env benar.\n");
}
$server->exec("CREATE DATABASE IF NOT EXISTS `$nama` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
$server->exec("USE `$nama`");

$tabel = $server->query('SHOW TABLES')->fetchAll(PDO::FETCH_COLUMN);
if ($tabel && !in_array('--reset', $argv, true)) {
    exit("Database '$nama' sudah berisi tabel, jadi tidak diubah.\nUntuk menghapus semua data lalu mulai dari awal:  php setup.php --reset\n");
}
$server->exec('SET FOREIGN_KEY_CHECKS = 0');
foreach ($tabel as $t) {
    $server->exec("DROP TABLE `$t`");
}
$server->exec('SET FOREIGN_KEY_CHECKS = 1');

foreach (['schema.sql', 'seed.sql'] as $file) {
    foreach (preg_split('/;\s*\n/', file_get_contents($file)) as $sql) {
        $sql = trim(preg_replace('/^--.*$/m', '', $sql));
        if ($sql !== '') {
            $server->exec($sql);
        }
    }
    echo "• $file diimpor\n";
}

echo "\nSelesai. Database '$nama' siap.\n";
echo "Cek API : http://localhost/resto-api/api/publik/meja/xxx  (harus: QR meja tidak dikenali)\n";
echo "Akun    : admin/admin123, sari/kasir123 (kasir), rina/waitress123 dan budi/waitress123 (waitress)\n";
echo "QR meja (setelah flutter run -d chrome --web-port 8080):\n";
foreach ($server->query('SELECT nomor_meja, kode_qr FROM meja ORDER BY id') as $m) {
    echo "  Meja {$m['nomor_meja']}: http://localhost:8080/?meja={$m['kode_qr']}\n";
}
