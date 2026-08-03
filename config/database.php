<?php

return [

    'default' => env('DB_CONNECTION', 'pgsql'),

    'connections' => [

        'pgsql' => [
            'driver' => 'pgsql',
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '5432'),
            'database' => env('DB_DATABASE', 'forge'),
            'username' => env('DB_USERNAME', 'forge'),
            'password' => env('DB_PASSWORD', ''),
            'charset' => 'utf8',
            'prefix' => '',
            'prefix_indexes' => true,
            'search_path' => 'public',
            'sslmode' => env('DB_SSLMODE', 'require'),
        ],

        'layerbase' => [
            'driver' => 'layerbase_sqlite',
            'host' => env('DB_HOST', '127.0.0.1'),
            'port' => env('DB_PORT', '5432'),
            'database' => env('DB_DATABASE', 'database'),
            'username' => env('DB_USERNAME', ''),
            'password' => env('DB_PASSWORD', ''),
            'sslmode' => env('DB_SSLMODE', 'require'),
            // Deliberately no 'charset', 'search_path', 'application_name',
            // or 'timezone' keys here — keeping them out stops
            // PostgresConnector from firing SET NAMES / SET search_path /
            // SET application_name, which the SQLite-backed proxy doesn't
            // support and will error on.
            'foreign_key_constraints' => env('DB_FOREIGN_KEYS', true),
        ],

    ],

    'migrations' => [
        'table' => 'migrations',
        'update_date_on_publish' => true,
    ],

];
