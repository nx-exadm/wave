FROM node:20-alpine AS assets-builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM dunglas/frankenphp:latest-php8.3-alpine AS runtime
RUN apk add --no-cache libffi-dev shadow \
    && docker-php-ext-install ffi pcntl opcache \
    && install-php-extensions @composer

RUN echo "ffi.enable=true" > /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

WORKDIR /app
COPY . .
COPY --from=assets-builder /app/public/build ./public/build
RUN composer install --no-dev --optimize-autoloader --no-suggest
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

ENV PORT=10000
EXPOSE 10000

CMD php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan migrate --force && \
    php artisan db:seed --force && \
    frankenphp run --config /etc/frankenphp/Caddyfile
