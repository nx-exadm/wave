<?php

namespace App\Database;

use Illuminate\Database\SQLiteConnection;

class LayerbaseSqliteConnection extends SQLiteConnection
{
    public function getDriverName()
    {
        return 'sqlite';
    }
}
