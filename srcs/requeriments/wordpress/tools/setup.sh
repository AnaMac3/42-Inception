#!/bin/bash
set -e

# Esperar a mariadb
until mysqladmin ping \
	-h mariadb \
	-u "$MYSQL_ROOT_USER" \
	-p "$MYSQL_ROOT_PASSWORD" \
	--silent
do
	echo "Waiting for MariaDB..."
	sleep 2
done

echo "MariaDB is ready!"

# Instalar wordpress solo si no existe
if [ ! -f wp-config.php ]; then
	echo "Installing WordPress..."

	wp core download --allow-root

	wp config create \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$MYSQL_PASSWORD" \
		--dbhost="$MYSQL_HOSTNAME" \
		--allow-root

	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_USER" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email \
		--allow-root

	wp user create \
		"$WORDPRESS_USER" \
		"$WORDPRESS_USER_EMAIL" \
		--user_pass="$WORDPRESS_USER_PASSWORD" \
		--allow-root
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
