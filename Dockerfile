FROM php:8.3-fpm-alpine
RUN apk add --no-cache nginx nodejs npm su-exec
COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini
COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_pgsql pcntl opcache exif gd zip intl @composer
WORKDIR /var/www/html
COPY . .

# TEMP DEBUG — remove after we get the file contents
RUN echo "=== RolesTableSeeder.php ===" && cat database/seeders/RolesTableSeeder.php

RUN composer install --no-dev --optimize-autoloader --no-scripts
RUN npm cache clean --force && npm install && npm run build
RUN mkdir -p /run/nginx \
    && chown -R www-data:www-data /var/www/html
EXPOSE 80
CMD su-exec www-data sh -c ' \
    CACHE_STORE=array CACHE_DRIVER=array php artisan package:discover --ansi && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan storage:link || true && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan filament:upgrade && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan livewire:publish --assets && \
    CACHE_STORE=array CACHE_DRIVER=array php artisan migrate --force && \
    if [ ! -f storage/.seeded ]; then \
        CACHE_STORE=array CACHE_DRIVER=array php artisan db:seed --force && touch storage/.seeded; \
    fi && \
    php artisan config:cache \
    ' && \
    php-fpm -D && nginx -g "daemon off;"
