<?php

return [
    'default' => env('DB_CONNECTION', 'libsql'),

    'connections' => [
        'libsql' => [
            'driver' => 'libsql',
            'database' => '',
            'url' => env('DB_URL', ''),
            'authToken' => env('DB_AUTH_TOKEN', ''),
            'syncInterval' => env('DB_SYNC_INTERVAL', 5),
            'read_your_writes' => env('DB_READ_YOUR_WRITES', true),
            'prefix' => '',
        ],
    ],

    'migrations' => [
        'table' => 'migrations',
        'update_date_on_publish' => true,
    ],
];
