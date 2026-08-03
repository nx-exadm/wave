<?php

use Wave\Facades\Wave;

Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

Route::get('/activate-theme-temp', function () {
    $theme = \Wave\Theme::first();

    if (!$theme) {
        return 'No themes found in the themes table at all — need a different fix, tell Claude this exact message.';
    }

    \Wave\Theme::query()->update(['active' => 0]);
    $theme->update(['active' => 1]);

    return 'Activated theme: ' . $theme->name . ' — DELETE THIS ROUTE NOW.';
});

Wave::routes();
