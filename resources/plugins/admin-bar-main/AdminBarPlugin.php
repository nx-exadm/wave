<?php

namespace Wave\Plugins\AdminBar;

use Livewire\Livewire;
use Wave\Plugins\Plugin;
use Illuminate\Support\Facades\File;

class AdminBarPlugin extends Plugin
{
    protected $name = 'Admin Bar';

    protected $description = 'An admin bar to quickly jump to documentation and different sections in your app.';

    public function register()
    {
        
    }

    public function boot()
    {
        if (!app()->runningInConsole() && !app()->environment('testing')) {
            $this->app->router->pushMiddlewareToGroup('web', \Wave\Plugins\AdminBar\Http\Middleware\InjectBarMiddleware::class);
        }
        $this->loadViewsFrom(__DIR__ . '/resources/views', 'admin-bar');
    }

    public function getPluginInfo(): array
    {
        return [
            'name' => $this->name,
            'description' => $this->description,
            'version' => $this->getPluginVersion()
        ];
    }

    public function getPluginVersion(): array
    {
        return File::json(__DIR__ . '/version.json');
    }
}