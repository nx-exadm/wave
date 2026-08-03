<?php

namespace App\Providers;

use Illuminate\Database\SQLiteConnection;

class LayerbaseSqliteConnection extends SQLiteConnection
{
    /**
     * SQLite's own default is foreign_keys = OFF unless explicitly turned
     * on. We never run the connect-time enabling pragma for this driver
     * (SQLiteConnector's configureForeignKeyConstraints step is bypassed),
     * so this starts false and only changes if something in this same
     * connection explicitly writes the pragma.
     */
    protected bool $foreignKeyConstraintsEnabled = false;

    public function getDriverName()
    {
        return 'sqlite';
    }

    /**
     * The Layerbase proxy rejects PDO::exec() for statements that return
     * rows. Route through PDO::query() instead, which handles both cases.
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
     * The Layerbase proxy classifies any "pragma ..." statement as a
     * no-results command at the proxy level — this happens regardless of
     * whether the PHP side uses exec(), prepare()+execute(), or query(), so
     * no client-side PDO call can work around it. Laravel only reads this
     * particular value (via SQLiteGrammar::compileChange) to decide whether
     * to wrap a table-rebuild with disable/enable pragmas, so we answer
     * from our own tracked state instead of asking the proxy.
     */
    public function select($query, $bindings = [], $useReadPdo = true)
    {
        if ($this->isBarePragmaRead($query, 'foreign_keys')) {
            return $this->run($query, $bindings, function () {
                return [(object) ['foreign_keys' => (int) $this->foreignKeyConstraintsEnabled]];
            });
        }

        return parent::select($query, $bindings, $useReadPdo);
    }

    /**
     * Writes like "PRAGMA foreign_keys = ON;" already succeed fine against
     * the proxy (they go through statement(), which works). We just also
     * update our tracked state here so future bare reads stay accurate.
     */
    public function statement($query, $bindings = [])
    {
        if (preg_match('/^\s*pragma\s+foreign_keys\s*=\s*(on|off|1|0)\s*;?\s*$/i', $query, $m)) {
            $this->foreignKeyConstraintsEnabled = in_array(strtolower($m[1]), ['on', '1'], true);
        }

        return parent::statement($query, $bindings);
    }

    protected function isBarePragmaRead($query, string $name)
    {
        return (bool) preg_match('/^\s*pragma\s+'.preg_quote($name, '/').'\s*;?\s*$/i', $query);
    }
}
