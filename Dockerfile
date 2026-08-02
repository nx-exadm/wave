FROM dunglas/frankenphp:latest-php8.3-bookworm AS runtime

# Node 20 LTS (Debian bookworm's apt nodejs is old/18.x and can trip up modern
# Vite/Tailwind builds) + curl for the extension installer below.
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# install-php-extensions is baked into the official frankenphp images.
RUN docker-php-ext-install pcntl opcache \
    && install-php-extensions @composer exif gd zip intl

WORKDIR /app

# --- Install the native LibSQL PHP extension -------------------------------
# tursodatabase/turso-driver-laravel is only a wrapper. The actual `LibSQL`
# class ships as a compiled Rust extension that must be installed onto the
# system BEFORE `composer install` runs, because Laravel's package:discover
# step boots the framework and resolves the DB config, which touches the
# libsql driver and needs the LibSQL class to exist.
#
# This extension is glibc-linked (needs GLIBC >= 2.29), which is why it can
# never work on the old -alpine (musl) base image — that's the real reason
# the previous build failed, and no composer flag can fix it. Switching to
# the -bookworm (Debian/glibc) image above is required.
#
# The installer's old .phar download URL was retired; it's now distributed
# as a Composer global package. Its documented -n flags (--php-vesion etc.)
# don't match what the shipped v2.1.0 CLI actually accepts.
#
# --thread-safe is required and is NOT optional here: FrankenPHP's PHP 8.3
# build is ZTS (confirmed from build logs: extension_dir contains
# "no-debug-zts-..."). Without this flag the installer's default fetches
# the NTS build, which loads but crashes with "undefined symbol:
# executor_globals" — a classic NTS-extension-in-ZTS-PHP ABI mismatch.
RUN export COMPOSER_ALLOW_SUPERUSER=1 \
    && composer global require darkterminal/turso-php-installer \
    && export PATH="$(composer config --global home)/vendor/bin:$PATH" \
    && turso-php-installer install --help \
    && turso-php-installer install -n --thread-safe \
    && php -m | grep -i libsql
# The final `php -m | grep -i libsql` is a deliberate build-time assertion:
# if the extension didn't actually load, this line fails the build here,
# loudly and immediately, instead of the cryptic "Class LibSQL not found"
# error surfacing later inside composer's package:discover step.

COPY . .

# --no-scripts: composer's post-autoload-dump scripts (package:discover,
# storage:link, filament:upgrade, livewire:publish) boot the full Laravel
# app, which now constructs a real `new LibSQL(...)` connection. At build
# time DB_SYNC_URL/DB_AUTH_TOKEN don't exist yet (they're runtime env vars
# on Render), so the extension gets empty credentials and Rust-panics
# instead of throwing a normal PHP exception. These scripts are moved to
# CMD below, run at container start once real env vars are present —
# matching how `migrate`/`db:seed` were already deferred to runtime.
RUN composer install --no-dev --optimize-autoloader --no-scripts

RUN npm cache clean --force && npm install
RUN npm run build

RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

ENV PORT=10000
EXPOSE 10000

CMD php artisan package:discover --ansi && \
    php artisan storage:link || true && \
    php artisan filament:upgrade && \
    php artisan livewire:publish --assets && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan migrate --force && \
    php artisan db:seed --force && \
    frankenphp run --config /etc/frankenphp/Caddyfile
