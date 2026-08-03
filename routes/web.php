<?php

use Wave\Facades\Wave;

Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

Route::get('/create-admin-temp', function () {
    $user = \App\Models\User::create([
        'name' => 'Admin',
        'email' => 'admin@example.com',
        'password' => bcrypt('ChangeThisPassword123!'),
        'email_verified_at' => now(),
    ]);

    if (class_exists(\Spatie\Permission\Models\Role::class)) {
        $role = \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'admin']);
        $user->assignRole($role);
    }

    return 'Created user: ' . $user->email . ' — DELETE THIS ROUTE NOW.';
});

Wave::routes();
