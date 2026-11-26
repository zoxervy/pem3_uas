<?php

declare(strict_types=1);

// Satu-satunya pintu masuk API. Web server meneruskan semua /api/* ke file ini.
require __DIR__ . '/../src/bootstrap.php';

// Untuk Flutter yang dijalankan dari alamat lain (mis. `flutter run` di Laragon). Login memakai
// token di header Authorization, bukan cookie, jadi "*" aman.
header('Access-Control-Allow-Origin: ' . env('CORS_ORIGIN', '*'));
header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');

[$status, $data] = buatApp()->tangani(Req::dariGlobal());

http_response_code($status);
if ($data !== null) {
    header('Content-Type: application/json');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
}
