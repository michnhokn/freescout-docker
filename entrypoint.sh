#!/bin/sh
set -e

echo "[ENTRYPOINT] Ensure storage directories exist and have correct permissions..."
mkdir -p /app/storage/framework/{cache,sessions,views} \
         /app/storage/logs \
         /app/storage/app/public \
         /app/storage/app/attachment
chown -R www-data:www-data /app/storage
chmod -R 775 /app/storage

# Same for Modules
mkdir -p /app/Modules
chown -R www-data:www-data /app/Modules

echo "[ENTRYPOINT] Clear Freescout cache..."
php artisan freescout:clear-cache --doNotGenerateVars || {
    echo "❌ ERROR: 'freescout:clear-cache' command failed."
    exit 1
}

echo "[ENTRYPOINT] Linking storage directory..."
php artisan storage:link || {
    echo "❌ ERROR: 'storage:link' command failed."
    exit 1
}

echo "[ENTRYPOINT] Run migrations..."
php artisan migrate --force || {
    echo "❌ ERROR: 'migration' command failed."
    exit 1
}

exec docker-php-entrypoint "$@"