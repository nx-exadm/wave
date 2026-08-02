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
# as a Composer global package. --php-vesion (not a typo on my end — that's
# the actual flag name shipped by the tool) and --thread-safe are picked up
# dynamically based on whether this PHP build is ZTS, since FrankenPHP
# images can ship either, and installing the wrong TS/NTS binary loads
# silently-wrong (or not at all).
RUN mkdir -p /usr/local/etc/php/conf.d \
    && touch /usr/local/etc/php/conf.d/99-libsql.ini \
    && export COMPOSER_ALLOW_SUPERUSER=1 \
    && composer global require darkterminal/turso-php-installer \
    && export PATH="$(composer config --global home)/vendor/bin:$PATH" \
    && TS_FLAG="$(php -r 'echo PHP_ZTS ? "--thread-safe" : "";')" \
    && turso-php-installer install -n $TS_FLAG \
        --php-vesion=8.3 \
        --php-ini=/usr/local/etc/php/conf.d/99-libsql.ini \
        --extension-dir="$(php -r 'echo ini_get("extension_dir");')" \
    && php -m | grep -i libsql
# The final `php -m | grep -i libsql` is a deliberate build-time assertion:
# if the extension didn't actually load, this line fails the build here,
# loudly and immediately, instead of the cryptic "Class LibSQL not found"
# error surfacing later inside composer's package:discover step.

COPY . .

# --ignore-platform-req=ext-intl is no longer needed: intl is installed above.
RUN composer install --no-dev --optimize-autoloader

RUN npm cache clean --force && npm install
RUN npm run build

RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

ENV PORT=10000
EXPOSE 10000

CMD php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan migrate --force && \
    php artisan db:seed --force && \
    frankenphp run --config /etc/frankenphp/Caddyfile
