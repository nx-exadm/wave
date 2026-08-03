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

// Wave routes
Wave::routes();
