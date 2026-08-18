FROM php:8.4-cli

# MySQL driver required by the application (pdo_mysql uses the bundled mysqlnd).
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip curl \
    && docker-php-ext-install pdo_mysql \
    && rm -rf /var/lib/apt/lists/*

# Composer (used only when the host vendor/ is not mounted).
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /app

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
