#!/bin/sh

# Script di inizializzazione per Laravel
# Viene eseguito ogni volta che il container parte

echo "🚀 Avvio container Laravel..."

# Aspetta che il filesystem sia pronto
sleep 2

# Installa dipendenze Composer se non esistono
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Installo dipendenze Composer..."
    composer install --no-interaction --optimize-autoloader
else
    echo "✅ Dipendenze Composer già presenti"
fi

# Controlla se .env esiste
if [ ! -f ".env" ]; then
    echo "⚠️  File .env non trovato, copio .env.example"
    cp .env.example .env
fi

# Genera APP_KEY solo se non esiste già
if grep -q "APP_KEY=$" .env || ! grep -q "APP_KEY=" .env; then
    echo "🔑 Genero APP_KEY..."
    php artisan key:generate --force
else
    echo "✅ APP_KEY già presente"
fi

# Crea il database SQLite se non esiste
if [ ! -f "database/database.sqlite" ]; then
    echo "💾 Creo database SQLite..."
    touch database/database.sqlite
    chmod 664 database/database.sqlite
fi

# Esegui le migrations solo se il database è vuoto
# Controlla se la tabella migrations esiste
if ! php artisan migrate:status > /dev/null 2>&1; then
    echo "📊 Eseguo migrations..."
    php artisan migrate --force
else
    echo "✅ Database già migrato"
fi

# Imposta permessi corretti
echo "🔐 Imposto permessi..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "✨ Inizializzazione completata!"
echo "🎯 Avvio PHP-FPM..."

# Esegui PHP-FPM (mantiene il container attivo)
exec php-fpm
