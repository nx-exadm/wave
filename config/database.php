<?php

return [
    'default' => env('DB_CONNECTION', 'libsql'),

    'connections' => [
        'libsql' => [
            'driver' => 'libsql',
            'url' => env('DB_URL', ''),
            'authToken' => env('DB_AUTH_TOKEN', ''),
            'prefix' => '',
        ],
    ],

    'migrations' => [
        'table' => 'migrations',
        'update_date_on_publish' => true,
    ],
];
