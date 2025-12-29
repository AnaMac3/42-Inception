#!/bin/bash
set -e # salir si hay error

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Esperar a mariadb
until mysqladmin ping \
	-h "$MYSQL_HOSTNAME" \
	-u "$MYSQL_ROOT_USER" \
	-p"$MYSQL_ROOT_PASSWORD" \
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
		--role=subscriber \
		--allow-root
fi

echo "Starting PHP-FPM..."
exec php-fpm -F
