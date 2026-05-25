#!/bin/bash
set -e

echo "[ENTRY] === Freescout Container Startup ==="

# Ensure storage directories exist (volume may be empty on first deploy)
echo "[ENTRY] Ensuring storage directories exist ..."
mkdir -p /app/storage/app/public
mkdir -p /app/storage/framework/cache/data
mkdir -p /app/storage/framework/sessions
mkdir -p /app/storage/framework/views
mkdir -p /app/storage/logs
mkdir -p /app/Modules

chown -R www-data:www-data /app/storage /app/Modules
chmod -R 775 /app/storage /app/Modules

# Auto-generate APP_KEY if not set or invalid (must start with "base64:")
if [ -z "$APP_KEY" ] || [[ ! "$APP_KEY" =~ ^base64: ]]; then
    if [ -n "$APP_KEY" ]; then
        echo "[ENTRY] APP_KEY is set but invalid (must start with 'base64:')"
    else
        echo "[ENTRY] No APP_KEY found"
    fi
    echo "Generating new APP_KEY..."
    APP_KEY=$(php artisan key:generate --show)
    export APP_KEY
    echo ""
    echo "=================================================="
    echo "IMPORTANT: Save this key in your environment!"
    echo "APP_KEY=$APP_KEY"
    echo "=================================================="
    echo ""
fi

# Run migrations
echo "[ENTRY] Running migrations ..."
php artisan migrate --force

# Cache configuration
echo "[ENTRY] Caching clear freescout cache ..."
php artisan freescout:clear-cache --doNotGenerateVars

# Create storage link (harmless if already exists)
echo "[ENTRY] Creating storage link..."
php artisan storage:link 2>/dev/null || true

# Re-apply storage ownership after artisan commands (may have created root-owned files)
echo "[ENTRY]  Re-applying storage ownership ..."
chown -R www-data:www-data /app/storage /app/bootstrap/cache /app/Modules
chmod -R 775 /app/storage /app/bootstrap/cache /app/Modules

echo "[ENTRY] === Startup complete, launching services ==="

# Start FrankenPHP
exec docker-php-entrypoint "$@"