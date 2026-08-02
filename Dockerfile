FROM dunglas/frankenphp:latest-php8.3-alpine AS runtime

RUN apk add --no-cache libffi-dev shadow nodejs npm curl \
    && docker-php-ext-install ffi pcntl opcache \
    && install-php-extensions @composer exif gd zip

RUN echo "ffi.enable=true" > /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN curl -L -o /usr/lib/liblibsql.so https://github.com \
    && chmod 755 /usr/lib/liblibsql.so

WORKDIR /app
COPY . .

RUN composer install --no-dev --optimize-autoloader --ignore-platform-req=ext-intl

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
