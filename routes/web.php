<?php

use Wave\Facades\Wave;

Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

Route::get('/check-theme-temp', function () {
    $theme = \Wave\Theme::where('active', 1)->first();
    return 'Theme record: ' . json_encode($theme);
});

Wave::routes();
