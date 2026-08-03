<?php

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

use Wave\Facades\Wave;

// TEMPORARY DIAGNOSTIC ROUTE — remove after confirming the cause of
// the blank homepage. Tests whether the setting() helper returns
// correctly now that the settings table exists but has zero rows
// (fresh MySQL database, never seeded).
Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

// TEMPORARY DIAGNOSTIC ROUTE — isolates the homepage's marketing
// layout component from Folio entirely, with a manual try/catch on
// \Throwable (catches fatal errors too, not just normal exceptions).
// If the real homepage is silently swallowing a fatal error somewhere
// in the framework/middleware stack, this surfaces it directly in the
// response instead of returning an empty body.
Route::get('/plaintest2', function () {
    try {
        return view('components.layouts.marketing', [
            'seo' => [
                'title' => 'Test Title',
                'description' => 'Test Description',
                'image' => url('/og_image.png'),
                'type' => 'website',
            ],
        ])->render();
    } catch (\Throwable $e) {
        return 'CAUGHT ERROR: ' . $e->getMessage() . ' | ' . $e->getFile() . ':' . $e->getLine();
    }
});

// Wave routes
Wave::routes();
