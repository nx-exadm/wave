<?php

namespace App\Providers;

use App\Database\LayerbaseSqliteConnection;
use Illuminate\Database\Connectors\PostgresConnector;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\ServiceProvider;

class LayerbaseDatabaseServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        DB::extend('layerbase_sqlite', function (array $config, string $name) {
            $config['name'] = $name;

            $connector = new PostgresConnector();
            $pdo = $connector->connect($config);

            return new LayerbaseSqliteConnection(
                $pdo,
                $config['database'],
                $config['prefix'] ?? '',
                $config
            );
        });
    }
}
