#!/bin/sh

#echo "=== Variabili d'ambiente ==="
#env
#echo "============================"

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

# Permessi sicuri per .env (640: rw-r-----)
# Solo proprietario può leggere/scrivere, gruppo può solo leggere, altri niente
chown www-data:www-data .env
chmod 640 .env
echo "🔒 Permessi .env impostati a 640"

# Genera APP_KEY solo se non esiste già
if grep -q "APP_KEY=$" .env || ! grep -q "APP_KEY=" .env; then
    echo "🔑 Genero APP_KEY..."
    php artisan key:generate --force
fi

# Dopo aver generato la key, ri-imposta i permessi
# (artisan key:generate potrebbe cambiarli)
chmod 640 .env
echo "✅ APP_KEY generata"

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

# PERMESSI DETTAGLIATI
echo "🔐 Imposto permessi corretti..."

# Assicurati che le directory esistano
mkdir -p storage/framework/cache
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p bootstrap/cache

# Imposta proprietà a www-data (utente PHP-FPM)
chown -R www-data:www-data storage
chown -R www-data:www-data bootstrap/cache

# Imposta permessi directory: 775 (rwxrwxr-x)
# - proprietario (www-data) può leggere/scrivere/eseguire
# - gruppo (www-data) può leggere/scrivere/eseguire  
# - altri possono solo leggere/eseguire
find storage -type d -exec chmod 775 {} \;
find bootstrap/cache -type d -exec chmod 775 {} \;

# Imposta permessi file: 664 (rw-rw-r--)
# - proprietario (www-data) può leggere/scrivere
# - gruppo (www-data) può leggere/scrivere
# - altri possono solo leggere
find storage -type f -exec chmod 664 {} \;
find bootstrap/cache -type f -exec chmod 664 {} \;

# Permessi speciali per il database SQLite
if [ -f "database/database.sqlite" ]; then
    chown www-data:www-data database/database.sqlite
    chmod 664 database/database.sqlite
    # Anche la directory deve essere scrivibile
    chown www-data:www-data database
    chmod 775 database
fi

# Verifica permessi (per debug)
echo "📋 Verifica permessi:"
ls -la .env
ls -la storage/ | head -n 5

echo "✨ Inizializzazione completata!"
echo "🎯 Avvio PHP-FPM..."

if [ "$APP_ENV" = "production" ] || [ "$APP_ENV" = "prod" ]; then
# Esegui PHP-FPM (mantiene il container attivo)
    echo "🚀 PROD mode: avvio PHP-FPM"
    exec php-fpm
else
    echo "🧪 DEV mode: avvio artisan serve"
    exec php artisan serve --host=0.0.0.0 --port=8000
fi

