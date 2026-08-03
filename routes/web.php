<?php

use Wave\Facades\Wave;

Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

Route::get('/check-theme-temp', function () {
    $theme = \Wave\Theme::where('active', 1)->first();
    return 'Theme record: ' . json_encode($theme);
});

Route::get('/activate-theme-temp', function () {
    $theme = \Wave\Theme::first();

    if (!$theme) {
        $seeder = new \Database\Seeders\ThemesTableSeeder();
        $seeder->run();
        $theme = \Wave\Theme::first();
    }

    if (!$theme) {
        return 'Still no theme row after seeding — deeper issue.';
    }

    \Wave\Theme::query()->update(['active' => 0]);
    $theme->forceFill(['active' => 1])->save();

    $confirm = \Wave\Theme::where('active', 1)->first();

    return 'Theme: ' . $theme->name . ' | Confirmed active row: ' . json_encode($confirm) . ' — DELETE THIS ROUTE NOW.';
});

Wave::routes();
