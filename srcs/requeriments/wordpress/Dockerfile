FROM debian:bookworm

# Instalar PHP, PHP-FPM y dependencias 
RUN apt-get update && apt-get install -y \
	unzip \
	php8.2 \
	php8.2-fpm \
	php-mysql \
	curl \
	mariadb-client

# Instalar WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Crear directorio necesario para PHP-FPM
RUN mkdir -p /run/php

# Copiar configuración PHP-FPM
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copiar script de inicialización
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["setup.sh"]
