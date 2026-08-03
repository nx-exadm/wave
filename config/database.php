<?php

return [
    // Previously had a 'libsql' connection here using Turso's native
    // extension. Removed entirely (not just switched away from) because
    // the libsql PHP extension aborts the entire process (not a
    // catchable exception) on ANY SQL error — missing table, duplicate
    // key, anything. That's a hard blocker for production use, confirmed
    // directly from crash logs (src/statement.rs:46 calling .unwrap()
    // on the raw SQL result). Simply not setting DB_CONNECTION=libsql
    // wasn't enough — having the package installed and the connection
    // configured was enough for the native extension to load and
    // interfere with real queries (e.g. Filament's /admin/users page),
    // even while 'sqlite' was the active default connection.
    //
    // 'sqlite' below uses PHP's built-in pdo_sqlite driver against the
    // exact same file, with normal, catchable PHP exceptions on error
    // instead of a process abort.
    'default' => env('DB_CONNECTION', 'sqlite'),

    'connections' => [
        'sqlite' => [
            'driver' => 'sqlite',
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix' => '',
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        ],
    ],

    'migrations' => [
        'table' => 'migrations',
        'update_date_on_publish' => true,
    ],
];
