FROM php:8.3-fpm-alpine

RUN apk add --no-cache nginx nodejs npm su-exec

COPY docker/nginx/default.conf /etc/nginx/http.d/default.conf
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/zz-opcache.ini

COPY --from=mlocati/php-extension-installer:latest /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pcntl opcache exif gd zip intl @composer

WORKDIR /var/www/html
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-scripts

# Install the native libSQL PHP extension — this step was missing
# entirely before, which is very likely why the driver was
# "Unsupported": the Composer package alone doesn't include the
# compiled native extension, only the Laravel-side wrapper around it.
RUN php artisan turso-php:install --no-interaction || true

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
    php artisan config:cache \
    ' && \
    php-fpm -D && nginx -g "daemon off;"
