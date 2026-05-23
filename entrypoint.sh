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

# Fix ownership and permissions
# Use 'find' with -exec to handle nested directories properly
find /app/storage /app/bootstrap/cache /app/public/css/builds /app/public/js/builds \
    -exec chown www-data:www-data {} \; \
    -exec chmod u+rwX,g+rwX,o-rwx {} \; 2>/dev/null || true

# Same for top-level app directories
chown -R www-data:www-data /app/storage /app/bootstrap/cache /app/Modules /app/public/css/builds /app/public/js/builds 2>/dev/null || true

# Ensure Modules directory exists
mkdir -p /app/Modules
chown -R www-data:www-data /app/Modules

echo "[ENTRYPOINT] Clear FreeScout cache..."
php artisan freescout:clear-cache --doNotGenerateVars || {
    echo "❌ ERROR: 'freescout:clear-cache' command failed."
    exit 1
}

echo "[ENTRYPOINT] Linking storage directory..."
php artisan storage:link || {
    echo "⚠️  WARNING: 'storage:link' command failed (may already exist)."
    true  # Don't exit, symlink might already exist
}

echo "[ENTRYPOINT] Run migrations..."
php artisan migrate --force || {
   echo "❌ ERROR: 'migration' command failed."
   exit 1
}

echo "[ENTRYPOINT] Starting FrankenPHP..."
exec docker-php-entrypoint "$@"