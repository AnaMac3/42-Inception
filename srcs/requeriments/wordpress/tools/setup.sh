#!/bin/bash

# ==================================================================
# WordPress initialization and startup script
#
# This script is executed as the container ENTRYPOINT and therefore
# runs every time the WordPress container starts. 
# 
# Responsibilities:
#	- Wait until the MariaDB service is reachable
#	- Install and configure WordPress only on first container startup
#	- Create the admin user and an additional application user
#	- Ensure correct ownership and permissions of WordPress files
#	- Start PHP-FPM in foreground as the main container process
#
# This script implements an "initialize-once" pattern:
#	- If persistent data alreadye xists, no reinstallation occurs
#	- On container restarts, WordPress is left intact
# ==================================================================

# Exit immediately if any command fails
set -e

# ------------------------------------------------------------------
# Load secrets
# ------------------------------------------------------------------
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)
WORDPRESS_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WORDPRESS_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# ------------------------------------------------------------------
# Wait for MariaDB to become available
# ------------------------------------------------------------------
# 'depends_on' in docker-compose ensures container start order but
# does not guarantee service readiness.
# This loop ensures that WordPress waits until MariaDB responds.
# 'mysqladmin ping' tries to connect to MariaDB using:
# 	- The server hostname
#	- credentials from env
# and succeeds once MariaDB is accepting the connection.
until mysqladmin ping \
	-h "$MYSQL_HOSTNAME" \
	-u "$MYSQL_USER" \
	-p"$MYSQL_PASSWORD" \
	--silent
do
	echo "Waiting for MariaDB..."
	sleep 2
done

echo "MariaDB is ready!"

# ------------------------------------------------------------------
# Ensure initial WordPress files are present in the volume
# ------------------------------------------------------------------
#if [ -z "$(ls -A /var/www/html)" ]; then
#	echo "Initializing WordPress files in volume..."
#	cp -R /usr/src/wordpress/* /var/www/html || true
#fi

# ------------------------------------------------------------------
# WordPress installation (first container startup only)
# ------------------------------------------------------------------
# The presence of 'wp-config.php' indicates that WordPress has 
# already been installed
# If it does not exist, this is the first container startup
if [ ! -f wp-config.php ]; then
	echo "Installing WordPress..."

	# Download WordPress core files
	# --allow-root: WP-CLI normally refuses to run as root (for
	# security), but the container starts as root, so this flag
	# is required
	wp core download --allow-root

	# Generate wp-config.php using env variables
	# Connets WordPress to MariaDB
	wp config create \
		--dbname="$MYSQL_DATABASE" \
		--dbuser="$MYSQL_USER" \
		--dbpass="$MYSQL_PASSWORD" \
		--dbhost="$MYSQL_HOSTNAME" \
		--allow-root

	# Install WordPress core and create the admin user
	# Initializes the database and the credentials
	# --skip-email prevents WordPress from attempting to send email
	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WORDPRESS_TITLE" \
		--admin_user="$WORDPRESS_ADMIN_USER" \
		--admin_password="$WORDPRESS_ADMIN_PASSWORD" \
		--admin_email="$WORDPRESS_ADMIN_EMAIL" \
		--skip-email \
		--allow-root

	# Create an additional non-admin user with subscriber role
	wp user create \
		"$WORDPRESS_USER" \
		"$WORDPRESS_USER_EMAIL" \
		--user_pass="$WORDPRESS_USER_PASSWORD" \
		--role=subscriber \
		--allow-root
fi

# ------------------------------------------------------------------
# File ownership and permissions
# ------------------------------------------------------------------
# PHP-FPM runs as the 'www-data' user. Correct ownership and 
# permissions are required so that PHP can read/write plugins, uploads
# and updates
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# ------------------------------------------------------------------
# Start PHP-FPM in foreground
# ------------------------------------------------------------------
# PHP-FPM is the main service of this container
# Running it in foreground and using 'exec' makes it PID 1,
# allowing Docker to properly manage signals and container lifecycle
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
