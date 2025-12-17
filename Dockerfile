# Immagine base PHP 8.4 con FPM su Alpine Linux
FROM php:8.4-fpm-alpine

# Directory di lavoro
WORKDIR /var/www/html

# Installo solo le estensioni PHP essenziali per Laravel
# Alpine usa apk invece di apt-get
RUN apk add --no-cache \
    libzip-dev \
    && docker-php-ext-install \
    pdo_mysql \
    zip

# Installo Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copio il codice Laravel nel container
COPY . /var/www/html

# Imposto i permessi per le directory che Laravel deve scrivere
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copio lo script di entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Espongo la porta 9000 per PHP-FPM
EXPOSE 9000

# Uso lo script di entrypoint invece del comando diretto
ENTRYPOINT ["docker-entrypoint.sh"]
