<?php

namespace Wave\Plugins\AdminBar\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class InjectBarMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if (!$this->shouldInjectBar($request, $response)) {
            return $response;
        }

        $content = $response->getContent();

        if (str_contains($content, '<body')) {
            $cornerTabHTML = view('admin-bar::index')->render();
            $content = preg_replace('/(<body[^>]*>)(.*?)(<\/body>)/s', '$1$2' . $cornerTabHTML . '$3', $content, 1);
            $response->setContent($content);
        }

        return $response;
    }

    private function shouldInjectBar(Request $request, Response $response): bool
    {
        return auth()->check() 
            && !$request->ajax() 
            && $response->headers->get('Content-Type') === 'text/html'
            && $response->getStatusCode() === 200;
    }
}