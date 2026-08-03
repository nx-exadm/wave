# 1. PHP 8.3 (matches what's already confirmed working with this
# composer.json today — bump to a newer PHP later once you've verified
# Filament/Wave/Livewire compatibility, but no reason to risk that now).
FROM php:8.3-fpm-alpine

# 2. Install Nginx + build/runtime deps.
# nodejs/npm: for the Vite asset build.
# su-exec: lightweight user-switching so artisan commands run as
# www-data, not root — root-owned files/symlinks created during
# migrate, storage:link, or filament:upgrade can't later be
# written/read by the www-data PHP-FPM workers that serve real
# requests, which caused every permission error early on.
# (sqlite-dev removed — no longer using a local SQLite file at all;
# the database now lives remotely on Aiven MySQL, which is what
# actually makes data persist across Render redeploys.)
RUN apk add --no-cache nginx nodejs npm su-exec

# 3. Nginx routing config for Laravel's front controller.
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf

# 4. OPcache — bundled but off by default on this image.
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

# 5. PHP extensions.
# pdo_mysql: talks to Aiven's managed MySQL over the network — this
# replaces pdo_sqlite entirely, since there's no local database file
# anymore. (No sqlite-dev needed either, for the same reason.)
COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql pcntl opcache exif gd zip intl @composer

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

# 7. Re-own the ENTIRE app tree to www-data. Composer and npm (step 6)
# both ran as root and wrote files as root — vendor/, node_modules
# build output, public/build assets, all of it. The CMD below runs
# artisan commands as www-data (via su-exec), and several of those
# commands write into public/ or storage/ (storage:link creates a
# symlink; filament:upgrade copies JS/CSS assets; we also write the
# Aiven SSL CA cert into storage/ at runtime, below). If any part of
# the tree is still root-owned, those specific writes fail with
# "Permission denied" even though other paths work fine.
RUN mkdir -p /run/nginx \
    && chown -R www-data:www-data /var/www/html

EXPOSE 80

# Laravel 11/12 defaults CACHE_STORE=database, which needs a `cache`
# table that only exists after `migrate` runs — but every artisan
# command boots all service providers before the command itself
# executes, and Wave's provider reads cached settings on boot. Forcing
# the array (in-memory) cache driver for every command up through
# migrate avoids touching the real cache table before it's guaranteed
# to exist; everything after migrate uses whatever's actually in .env.
#
# Everything from the CA cert write through migrate now runs via
# su-exec www-data — the same user that owns the entire app tree
# (step 7 above) and that PHP-FPM's workers run as at request time.
#
# NOTE 1: `route:cache` is deliberately NOT run here. This app uses
# Laravel Folio for page routing — Folio registers routes dynamically
# at boot, and route:cache doesn't correctly capture that, which
# previously caused the homepage to return an empty 200 body.
#
# NOTE 2: `db:seed --force` is deliberately NOT run here. It was
# originally included to populate the database on first boot, but
# running it on every deploy silently overwrites real production data
# (admin email/password, edited pages, etc.) back to seeder defaults.
# Seeding is a one-time setup action — run it manually once against
# the Aiven database if you need to seed a genuinely fresh install,
# then never include it in this CMD again.
#
# NOTE 3: MYSQL_SSL_CA_CONTENT is expected as a Render env var
# containing the full text of Aiven's ca.pem (including the
# -----BEGIN CERTIFICATE----- / -----END CERTIFICATE----- lines). It's
# written to disk here at container start, since Aiven requires
# SSL/TLS and PDO needs an actual file path for MYSQL_ATTR_SSL_CA, not
# inline cert content. MYSQL_ATTR_SSL_CA should be set to
# /var/www/html/storage/aiven-ca.pem to match where this writes it.
CMD su-exec www-data sh -c ' \
    echo "$MYSQL_SSL_CA_CONTENT" > /var/www/html/storage/aiven-ca.pem && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan package:discover --ansi && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan storage:link || true && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan filament:upgrade && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan livewire:publish --assets && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan migrate --force && \
    php artisan config:cache && \
    php artisan view:cache \
    ' && \
    php-fpm -D && nginx -g "daemon off;"
