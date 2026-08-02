# 1. PHP 8.3 (matches what's already confirmed working with this
# composer.json today — bump to a newer PHP later once you've verified
# Filament/Wave/Livewire compatibility, but no reason to risk that now).
FROM php:8.3-fpm-alpine

# 2. Install Nginx + build/runtime deps.
# sqlite-dev: headers for pdo_sqlite below.
# nodejs/npm: for the Vite asset build.
# su-exec: lightweight user-switching so artisan commands run as
# www-data, not root — root-owned files/symlinks created during
# migrate, storage:link, or filament:upgrade can't later be
# written/read by the www-data PHP-FPM workers that serve real
# requests, which is what caused every permission error so far.
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

# 7. Ensure the sqlite file exists before ownership is set below —
# otherwise it gets created later (by `migrate`, running as www-data)
# inside a directory that's already correctly owned, which is fine
# either way, but creating it now makes ownership fully deterministic.
RUN mkdir -p /run/nginx /var/www/html/database \
    && touch /var/www/html/database/database.sqlite

# 8. Re-own the ENTIRE app tree to www-data, not just a few subfolders.
# Composer and npm (step 6) both ran as root and wrote files as root —
# vendor/, node_modules build output, public/build assets, all of it.
# The CMD below runs artisan commands as www-data (via su-exec), and
# several of those commands write into public/ (storage:link creates
# a symlink there; filament:upgrade copies JS/CSS assets there). If
# any part of the tree is still root-owned, those specific commands
# fail with "Permission denied" even though storage/database work fine
# — which is exactly the failure just seen. Re-owning everything here,
# as the last build step, is the only way to guarantee every path the
# CMD touches is writable by the user actually running it.
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

# Laravel 11/12 defaults CACHE_STORE=database, which needs a `cache`
# table that only exists after `migrate` runs — but every artisan
# command boots all service providers before the command itself
# executes, and Wave's provider reads cached settings on boot. Forcing
# the array (in-memory) cache driver for every command up through
# migrate avoids touching the real cache table before it's guaranteed
# to exist; everything after migrate uses whatever's actually in .env.
#
# Everything from package:discover through migrate now runs via
# su-exec www-data — the same user that owns the entire app tree
# (step 8 above) and that PHP-FPM's workers run as at request time.
#
# NOTE 1: `route:cache` is deliberately NOT run here. This app uses
# Laravel Folio for page routing — Folio registers routes dynamically
# at boot, and route:cache doesn't correctly capture that, which
# previously caused the homepage to return an empty 200 body.
#
# NOTE 2: `view:cache` is ALSO deliberately NOT run here. This app
# uses Livewire Volt anonymous components (@volt(...) blocks, e.g. in
# wave/resources/views/media/index.blade.php). Volt registers these
# components in a runtime registry as a side effect of normal request
# handling — pre-compiling views ahead of time via view:cache produced
# a cached view referencing a Volt component hash that was never
# actually registered in the live process's registry, causing
# "Unable to find component: [volt-anonymous-fragment-...]" 500 errors
# on any page using @volt (e.g. /admin/media). Views still compile
# fine on-demand at request time and are cached by OPcache after the
# first hit, so this costs a negligible amount of one-time compilation
# per view, not per request.
#
# NOTE 3: `db:seed --force` is deliberately NOT run here either. It
# was originally included to populate the database on first boot, but
# because this CMD runs on every deploy/restart (not just the first
# one), it was silently overwriting real production data — including
# an admin email/password that had been changed through the app —
# back to the seeders' hardcoded defaults on every single redeploy.
# Seeding is a one-time setup action, not a startup action.
CMD su-exec www-data sh -c ' \
    CACHE_STORE=array CACHE_DRIVER=array php artisan package:discover --ansi && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan storage:link || true && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan filament:upgrade && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan livewire:publish --assets && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan migrate --force && \
    php artisan config:cache \
    ' && \
    php-fpm -D && nginx -g "daemon off;"
