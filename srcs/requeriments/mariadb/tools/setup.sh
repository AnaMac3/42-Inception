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

# Default MariaDB data directory
DATADIR="/var/lib/mysql"

# ------------------------------------------------------------------
# Runtime directory preparation
# ------------------------------------------------------------------
# MariaDB uses a UNIX socket located in /run/mysql to accept local
# connections from clients.
#
# This directory may no exist in a fresh container filesystem
# and must be created manually. It also needs to be owned by the 
# mysql user so that the MariaDB server can write to it.
#
# - mkdir -p creates the directory if it does not exist and does
# - chown ensures correct ownership and prevents startup errors
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# ------------------------------------------------------------------
# Database initialization (first container startup only)
# ------------------------------------------------------------------
# The presence of the 'mysql' system directory indicates that the
# database has already been initialized. 
# If it does not exists, this is the first time the container runs
# and the database must be initialized.

if [ ! -d "$DATADIR/mysql" ]; then
		echo "Initializing MariaDB database..."

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

		# Create the application database and user.
		# Env variables are provided through the .env file and injected
		# by Docker Compose at runtime.
		# The MariaDB client is executed as the database root user 
		# (not password at this stage).
		# A heredoc is used to pass multiple SQL commands
		mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
	# Stop the temporary MariaDB instance.
	# This ensures a clean shutdown before restarting the server
	# in foreground mode.
	kill "$pid"
	wait "$pid"
fi

# ------------------------------------------------------------------
# Final MariaDB startup (foreground)
# ------------------------------------------------------------------
# Start MariaDB in foreground mode.
# Using 'exec' replaces the shell process (PID 1) with the MariaDB
# server process, allowing Docker to properly track signals and manage
# the container lifecycle
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir="$DATADIR"
