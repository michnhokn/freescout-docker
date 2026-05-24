#!/bin/sh
set -e

echo "[ENTRYPOINT] Ensure storage directories exist and have correct permissions..."
mkdir -p /app/storage/framework/{cache,sessions,views} \
         /app/storage/logs \
         /app/storage/app/public \
         /app/storage/app/attachment \
         /app/bootstrap/cache \
         /app/public/css/builds \
         /app/public/js/builds

chown -R www-data:www-data /app/storage /app/bootstrap/cache /app/Modules /app/public/css/builds /app/public/js/builds 2>/dev/null || true
chmod -R u+rwX,g+rwX,o-rwx /app/storage /app/bootstrap/cache /app/public/css/builds /app/public/js/builds 2>/dev/null || true

mkdir -p /app/Modules
chown -R www-data:www-data /app/Modules

echo "[ENTRYPOINT] Clearing configuration cache..."
php artisan config:clear || true
php artisan cache:clear || true

echo "[ENTRYPOINT] Linking storage directory..."
php artisan storage:link || {
    echo "⚠️  WARNING: 'storage:link' command failed (may already exist)."
    true
}

echo "[ENTRYPOINT] Run migrations..."
php artisan migrate --force || {
    echo "⚠️  WARNING: 'migrate' command failed (may have no new migrations)."
    true
}

echo "[ENTRYPOINT] Starting FrankenPHP..."
exec docker-php-entrypoint "$@"