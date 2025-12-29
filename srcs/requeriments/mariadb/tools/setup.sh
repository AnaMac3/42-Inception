#!/bin/bash

#este script debe:
# - arrancar mariadb
# - crear db y usuarios solo si no existen
# - dejar maridb en foreground??

set -e # detiene el script si hay algún error

DATADIR="/var/lib/mysql"

# Crear directorio de socket para evitar errores de arranque
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# Inicializar base de datos solo si no existe

if [ ! -d "$DATADIR/mysql" ]; then
       echo "Initializing MariaDB database..."

       # Crear tablas del sistema de mariadb
       mariadb-install-db --user=mysql --datadir="$DATADIR"

       # Arrancar mairadb temporalmente en background
       mysqld --user=mysql --datadir="$DATADIR" &
       pid="$!"

       # Esperar a que mariadb esté lista
       until mysqladmin ping --silent; do
	       echo "Waiting for MariaDB to start..."
	       sleep 2
       done

       # Crear base de datos y usuarios
       mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
	# Detener mariadb temporal

	kill "$pid"
	wait "$pid"
fi

# Arrancar mariadb en foreground para docker
echo "Starting MariaDB..."
exec mysqld --user=mysql --datadir="$DATADIR"
