FROM dunglas/frankenphp:1-php8.4

LABEL org.opencontainers.image.title="FreeScout Docker" \
      org.opencontainers.image.description="Self-hosted FreeScout help desk on FrankenPHP" \
      org.opencontainers.image.version="1.8.221" \
      org.opencontainers.image.vendor="Michael Engel" \
      org.opencontainers.image.url="https://github.com/michnhokn/freescout-docker" \
      org.opencontainers.image.source="https://github.com/michnhokn/freescout-docker" \
      org.opencontainers.image.documentation="https://github.com/michnhokn/freescout-docker/blob/main/README.md" \
      org.opencontainers.image.licenses="AGPL-3.0" \
      org.opencontainers.image.base.name="docker.io/dunglas/frankenphp:1-php8.4"

RUN apt-get update \
    && apt-get install -y --no-install-recommends git procps ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN install-php-extensions \
    pdo_mysql \
    pdo_pgsql \
    imap \
    zip \
    gd \
    pcntl \
    intl

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Tell FrankenPHP to listen on port 8080 via HTTP.
ENV SERVER_NAME=":8080"
ENV APP_ENV=prod

ARG FREESCOUT_VERSION=1.8.220

# FrankenPHP expects the app to be in /app by default
WORKDIR /app

# Clone the dist branch (deployment-ready, includes vendor/)
RUN git clone --branch dist https://github.com/freescout-help-desk/freescout.git /tmp/freescout \
    && cd /tmp/freescout \
    && git checkout ${FREESCOUT_VERSION} \
    && cp -a /tmp/freescout/. /app/ \
    && rm -rf /tmp/freescout /app/.git

RUN if [ -f /app/.env.example ] && [ ! -f /app/.env ]; then cp /app/.env.example /app/.env; fi

# Install dependencies with Composer
RUN rm -rf vendor/ && composer clear-cache
RUN composer install --optimize-autoloader --no-interaction --ignore-platform-reqs

# Copy application and vendor files
COPY Caddyfile /etc/frankenphp/Caddyfile

# Set up permissions for Symfony cache and log directories
RUN mkdir -p storage bootstrap/cache \
    && chown -R www-data:www-data . \
    && chmod -R 775 storage bootstrap/cache

# Use the default production PHP configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN mkdir -p /config/caddy /data/caddy var/cache var/log \
    && chown -R www-data:www-data /app /config/caddy /data/caddy

# --- Copy entrypoint script ---
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN setcap -r /usr/local/bin/frankenphp
USER www-data

EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=5s --start_period=5s --retries=3 \
    CMD curl -f http://localhost:8080/healthz || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["--config","/etc/frankenphp/Caddyfile","--adapter","caddyfile"]