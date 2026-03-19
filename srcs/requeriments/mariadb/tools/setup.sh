#!/bin/bash

# ==================================================================
# MariaDB initialization and startup script
#
# This script is executed as the container ENTRYPOINT and therefore
# runs every time the MariaDB container starts. 
# 
# Responsabilities:
#	- Prepare required runtime directories for MariaDB
#      - Detect whether the database has already been initialized
#      - Initialize the database only on first container startup
#      - Create the application database and users
#      - Start the MariaDB server in foreground to keep the container
#      alive
#
# This design is required when using when using persistent volumes:
# - Initialization happens only once
# - Data is preserved across container restarts
#
# MariaDB is started temporarily in background during the first run
# to allow executing SQL initialization commands. Once initialization
# is complete, the temporary server is stopped and MariaDB is
# started again in foreground as the main container process.
# ==================================================================

# Exit inmediately if any command fails
set -e 

echo "DEBUG BEFORE ANYTHING:"
ls -la /var/lib/mysql

# ------------------------------------------------------------------
# Load secrets
# ------------------------------------------------------------------
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/mysql_password)

# Default MariaDB data directory
DATADIR="/var/lib/mysql"

# ------------------------------------------------------------------
# Runtime directory preparation
# ------------------------------------------------------------------
# MariaDB uses a UNIX socket located in /run/mysql to accept local
# connections from clients.
#
# This directory may must be created manually and it needs to be 
# owned by the mysql user

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# ------------------------------------------------------------------
# Database initialization (first container startup only)
# ------------------------------------------------------------------
# If 'mysql' system directory does not exists, it means this is the  
# first time the container runs and the database must be initialized.

echo "DEBUG BEFORE IF:"
ls -la /var/lib/mysql

if [ ! -d "$DATADIR/mysql" ]; then
		echo "Initializing MariaDB database..."
		echo "ENTERING INIT BLOCK"

		# Create the internal MariaDB system tables.
		# This must be done before the server can start.
		# This process is performed as the mysql user, not as root,
		# because MariaDB should never run with root privileges.
		mariadb-install-db --user=mysql --datadir="$DATADIR"

		# Start MariaDB temporarily in the background ('&')
		# This allows executing SQL commands (to create databases
		# and users) while the server is running.
		# The process ID is stored so the temporary server can be 
		# stopped once initialization is complete
		mysqld --user=mysql --datadir="$DATADIR" &
		pid="$!"

		# Wait until MariaDB is ready to accept connections.
		# 'mysqladmin ping' returns success once the server is available.
		until mysqladmin ping --silent; do
			echo "Waiting for MariaDB to start..."
			sleep 2
		done

		echo "Configurating database..."

		# ------------------------------------------------------------------
		# Secure root account and create app DB/user
		# ------------------------------------------------------------------
		# - Root password is set for 'root'@'localhost'
		# - Remote root access ('root'@'%') is removed for security
		# - Applciation db is created if it doesn't exist
		# - Application user is created for both:
		#		- 'localhost' for internal container connections
		#		- '%' for external/remote connections (for wordpress)
		#   with privileges limited to the app db
		mysql -u root <<EOF
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
-- Remove remote root access (security best practice)
DELETE FROM mysql.user WHERE User='root' AND Host='%';
-- Create app DB
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
-- Create app user for remote connections (docker network)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
-- Create app user for local connections (inside container)
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';

FLUSH PRIVILEGES;
EOF
	# Stop the temporary MariaDB instance.
	# This ensures a clean shutdown before restarting the server in foreground
	kill "$pid"
	wait "$pid"

fi

# ------------------------------------------------------------------
# Final MariaDB startup (foreground)
# ------------------------------------------------------------------
# Start MariaDB in foreground mode.
# Using 'exec' replaces the shell process (PID 1) with the MariaDB
# server process
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir="$DATADIR"
