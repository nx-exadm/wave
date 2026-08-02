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
# don't match what the shipped v2.1.0 CLI actually accepts, so rather than
# guess flag names from stale docs again, we let `install -n` auto-detect
# this PHP build's version/thread-safety/paths on its own — that's the
# whole point of an "auto installer," and it's the only invocation that's
# been consistent across doc versions. `install --help` is printed first
# purely so the real flag list is visible in the build log if this ever
# needs to be revisited.
RUN export COMPOSER_ALLOW_SUPERUSER=1 \
    && composer global require darkterminal/turso-php-installer \
    && export PATH="$(composer config --global home)/vendor/bin:$PATH" \
    && turso-php-installer install --help \
    && turso-php-installer install -n \
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
