<?php

use Wave\Facades\Wave;

Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

Route::get('/activate-theme-temp', function () {
    $seeder = new \Database\Seeders\ThemesTableSeeder();
    $seeder->run();

    $theme = \Wave\Theme::first();

    if (!$theme) {
        return 'Seeder ran but still no theme row — different issue, tell Claude this.';
    }

    \Wave\Theme::query()->update(['active' => 0]);
    $theme->update(['active' => 1]);

    return 'Seeded and activated theme: ' . $theme->name . ' — DELETE THIS ROUTE NOW.';
});

Wave::routes();
