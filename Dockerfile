FROM dunglas/frankenphp:latest-php8.3-bookworm AS runtime

# libsqlite3-dev: needed so pdo_sqlite has headers to compile against below.
# libcap2-bin: provides setcap, used below to strip frankenphp's baked-in
# cap_net_bind_service capability — Render's sandboxed runtime refuses to
# exec ANY binary carrying Linux capabilities ("Operation not permitted"),
# and we don't need that capability anyway since we bind port 10000, not
# a privileged (<1024) port.
# Node 20 LTS: Debian bookworm's apt nodejs is old/18.x and can trip up
# modern Vite/Tailwind builds.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg libsqlite3-dev libcap2-bin \
    && setcap -r "$(which frankenphp)" \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# pdo_sqlite: PHP's built-in SQLite driver — ships with PHP itself, no
# external download or native third-party extension needed. This replaces
# the native libsql extension entirely (see config/database.php for why:
# that extension aborts the whole process on any SQL error).
RUN docker-php-ext-install pcntl opcache pdo_sqlite \
    && install-php-extensions @composer exif gd zip intl

WORKDIR /app

COPY . .

# --no-scripts: composer's post-autoload-dump scripts (package:discover,
# storage:link, filament:upgrade, livewire:publish) boot the full Laravel
# app. The database file doesn't have any tables yet at build time either
# way, so anything that queries it here would still fail — these scripts
# are moved to CMD below, run at container start once migrations have had
# a chance to run, matching how `migrate`/`db:seed` were already deferred
# to runtime in the original file.
RUN composer install --no-dev --optimize-autoloader --no-scripts

RUN npm cache clean --force && npm install
RUN npm run build

RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

ENV PORT=10000
EXPOSE 10000

# Laravel 11/12 defaults CACHE_STORE=database, which needs a `cache` table
# that only exists after `migrate` runs — but every artisan command boots
# all service providers (including Wave's, which reads cached settings)
# before the command itself executes. That's what crashed here: something
# read from `cache` before migrate ever got a chance to create the table.
#
# Fix: force the `array` (in-memory) cache driver for every command up
# through migrate, so nothing touches the real cache table until it's
# guaranteed to exist. Once migrate finishes, drop the override so
# config:cache/route:cache/view:cache/db:seed/frankenphp all use whatever
# cache driver is actually set in .env, table now present.
CMD CACHE_STORE=array CACHE_DRIVER=array php artisan package:discover --ansi && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan storage:link || true && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan filament:upgrade && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan livewire:publish --assets && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan migrate --force && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan db:seed --force && \
    frankenphp run --config /etc/frankenphp/Caddyfile
