<?php

return [
    // Switched away from 'libsql' as the default: the native libsql PHP
    // extension aborts the entire process (not a catchable exception) on
    // ANY SQL error — missing table, duplicate key, anything. That's a
    // hard blocker for production use, confirmed directly from your crash
    // logs (src/statement.rs:46 calling .unwrap() on the raw SQL result).
    //
    // 'sqlite' below uses PHP's built-in pdo_sqlite driver against the
    // exact same file, with normal, catchable PHP exceptions on error
    // instead of a process abort. The 'libsql' connection is left in
    // place in case Turso cloud sync becomes a real requirement later —
    // set DB_CONNECTION=libsql in .env to switch back.
    'default' => env('DB_CONNECTION', 'sqlite'),

    'connections' => [
        'sqlite' => [
            'driver' => 'sqlite',
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix' => '',
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        ],

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
