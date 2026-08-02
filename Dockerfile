FROM dunglas/frankenphp:latest-php8.3-alpine AS runtime

# 1. Install Linux core tools, PHP extensions, Node.js, and npm
RUN apk add --no-cache libffi-dev shadow nodejs npm \
    && docker-php-ext-install ffi pcntl opcache \
    && install-php-extensions @composer

# 2. Enable PHP FFI for the Turso Database Driver
RUN echo "ffi.enable=true" > /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini \
    && echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

WORKDIR /app
COPY . .

# 3. Install PHP composer packages cleanly
RUN composer install --no-dev --optimize-autoloader --no-suggest

# 4. Clear npm cache and safely install dependencies
RUN npm cache clean --force && npm install

# 5. Compile the frontend assets using the correct native environment pipeline
RUN npm run build

# 6. Apply production directory security rules
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

ENV PORT=10000
EXPOSE 10000

# 7. Optimize settings layouts and connect schemas to Turso
CMD php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan migrate --force && \
    php artisan db:seed --force && \
    frankenphp run --config /etc/frankenphp/Caddyfile
