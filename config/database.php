<?php

return [

    'default' => env('DB_CONNECTION', 'libsql'),

    'connections' => [

        'libsql' => [
            'driver' => 'libsql',
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix' => '',
            'url' => env('DB_SYNC_URL', ''),
            'authToken' => env('DB_AUTH_TOKEN', ''),
            'syncInterval' => env('DB_SYNC_INTERVAL', 5),
            'read_your_writes' => env('DB_READ_YOUR_WRITES', true),
            'encryptionKey' => env('DB_ENCRYPTION_KEY', ''),
        ],

    ],

    'migrations' => [
        'table' => 'migrations',
        'update_date_on_publish' => true,
    ],

];
