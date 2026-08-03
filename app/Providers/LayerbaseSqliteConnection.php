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
     * proxy rejects for any statement that returns rows. Route through
     * PDO::query() instead, which handles both cases safely.
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

    /**
     * Laravel's SQLiteGrammar internally runs $connection->scalar('pragma
     * foreign_keys') when rebuilding a table for a column change. That
     * becomes Connection::select(), which normally goes through
     * PDO::prepare()->execute()->fetchAll(). The Layerbase proxy errors on
     * that flow for bare PRAGMA reads ("Execute returned results - did you
     * mean to call query?"), so for that one statement shape we bypass
     * prepare()/execute() entirely and call PDO::query() directly.
     */
    public function select($query, $bindings = [], $useReadPdo = true)
    {
        if ($this->isBarePragmaRead($query)) {
            return $this->run($query, $bindings, function ($query) {
                if ($this->pretending()) {
                    return [];
                }

                $statement = $this->getPdoForSelect(true)->query($query);

                return $statement ? $statement->fetchAll() : [];
            });
        }

        return parent::select($query, $bindings, $useReadPdo);
    }

    /**
     * Matches bare pragma reads like "pragma foreign_keys" (no "= ON"/"= OFF"),
     * which return a row, as opposed to pragma writes, which don't.
     */
    protected function isBarePragmaRead($query)
    {
        return (bool) preg_match('/^\s*pragma\s+\w+\s*;?\s*$/i', $query);
    }
}
