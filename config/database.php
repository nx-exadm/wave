        'libsql' => [
            'driver' => 'libsql',
            'url' => env('DB_URL'),
            'token' => env('DB_AUTH_TOKEN'),
            'database' => env('DB_DATABASE', database_path('database.sqlite')),
            'prefix' => '',
        ],
