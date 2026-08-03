<?php

use Wave\Facades\Wave;

Route::get('/plaintest', fn () => 'raw output: [' . setting('site.title', 'FALLBACK') . ']');

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

Route::get('/plaintest3', function () {
    try {
        return \Illuminate\Support\Facades\Blade::render(
            '<x-layouts.marketing :seo="$seo">test content</x-layouts.marketing>',
            [
                'seo' => [
                    'title' => 'Test Title',
                    'description' => 'Test Description',
                    'image' => url('/og_image.png'),
                    'type' => 'website',
                ],
            ]
        );
    } catch (\Throwable $e) {
        return 'CAUGHT ERROR: ' . $e->getMessage() . ' | ' . $e->getFile() . ':' . $e->getLine();
    }
});

Wave::routes();
