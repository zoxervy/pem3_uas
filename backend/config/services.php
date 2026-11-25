<?php

return [
    // 'simulasi' = demo tanpa uang sungguhan, nanti 'midtrans'.
    'pembayaran' => [
        'mode' => env('PEMBAYARAN_MODE', 'simulasi'),
    ],
];
