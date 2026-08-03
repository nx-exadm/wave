<?php

namespace App\Providers;

use Illuminate\Database\SQLiteConnection;

class LayerbaseSqliteConnection extends SQLiteConnection
{
    public function getDriverName()
    {
        return 'sqlite';
    }

    /**
     * Laravel's default unprepared() calls PDO::exec(), which the Layerbase
     * proxy rejects for any statement that returns rows (e.g. bare pragma
     * reads like "pragma foreign_keys" used internally when SQLite rebuilds
     * a table for a column change). PDO::query() handles both result-set
     * and non-result-set statements safely, so route everything through it.
     */
    public function unprepared($query)
    {
        return $this->run($query, [], function ($query) {
            if ($this->pretending()) {
                return true;
            }

            $statement = $this->getPdo()->query($query);

            $change = $statement !== false;

            $this->recordsHaveBeenModified($change);

            return $change;
        });
    }
}
