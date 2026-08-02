# 1. PHP 8.3 (matches what's already confirmed working with this
# composer.json today — bump to a newer PHP later once you've verified
# Filament/Wave/Livewire compatibility, but no reason to risk that now).
FROM php:8.3-fpm-alpine

# 2. Install Nginx + build/runtime deps.
# sqlite-dev: headers for pdo_sqlite below.
# nodejs/npm: for the Vite asset build.
# su-exec: lightweight user-switching so artisan commands run as
# www-data, not root — root-owned files (like database.sqlite created
# during migrate) can't later be written to by the www-data PHP-FPM
# workers that serve real requests, which is exactly what was causing
# "attempt to write a readonly database" errors.
RUN apk add --no-cache nginx sqlite-dev nodejs npm su-exec

# 3. Nginx routing config for Laravel's front controller.
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# 4. OPcache — bundled but off by default on this image.
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

# 5. PHP extensions.
# pdo_sqlite: Laravel's default connection uses SQLite here — plain,
# built-in, no third-party native extension needed (unlike the libsql
# extension this app used to use, which crashed the whole PHP process
# on any SQL error — not something you want anywhere near production).
COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_sqlite pcntl opcache exif gd zip intl @composer

# 6. Working directory + app code.
WORKDIR /var/www/html
COPY . .

# --no-scripts: composer's post-autoload-dump scripts (package:discover,
# storage:link, filament:upgrade, livewire:publish) boot the full Laravel
# app, and the database has no tables yet at build time — anything that
# queries it here would fail. These run in CMD below instead, once
# migrations have had a chance to run.
RUN composer install --no-dev --optimize-autoloader --no-scripts

RUN npm cache clean --force && npm install && npm run build

# 7. Standard nginx runtime dir + correct ownership for Laravel's
# writable paths, INCLUDING database/ — this was previously missing,
# which meant the sqlite file (created later by `migrate`, running as
# root) ended up root-owned while PHP-FPM's actual worker processes
# run as www-data. Root-owned file + non-root writer = readonly error.
RUN mkdir -p /run/nginx /var/www/html/database \
    && touch /var/www/html/database/database.sqlite \
    && chown -R www-data:www-data \
        /var/www/html/storage \
        /var/www/html/bootstrap/cache \
        /var/www/html/database

EXPOSE 80

# Laravel 11/12 defaults CACHE_STORE=database, which needs a `cache`
# table that only exists after `migrate` runs — but every artisan
# command boots all service providers before the command itself
# executes, and Wave's provider reads cached settings on boot. Forcing
# the array (in-memory) cache driver for every command up through
# migrate avoids touching the real cache table before it's guaranteed
# to exist; everything after migrate uses whatever's actually in .env.
#
# Everything that touches the sqlite file (package:discover onward
# through db:seed) now runs via su-exec www-data — same user that owns
# database.sqlite and that PHP-FPM's workers run as at request time.
# Without this, these commands run as root (Docker's default), and any
# file/table they create is root-owned and unwritable by the app later.
CMD su-exec www-data sh -c ' \
    CACHE_STORE=array CACHE_DRIVER=array php artisan package:discover --ansi && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan storage:link || true && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan filament:upgrade && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan livewire:publish --assets && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan migrate --force && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan db:seed --force \
    ' && \
    php-fpm -D && nginx -g "daemon off;"
