#!/bin/bash

#este script debe:
# - arrancar mariadb
# - crear db y usuarios solo si no existen
# - dejar maridb en foreground??

set -e

DATADIR="/var/lib/mysql/mysql"

if [ ! -d "$DATADIR" ]; then
       echo "Initializing MariaDB database..."

       mysql_install_db --user=mysql --datadir=/var/lib/mysql

       /usr/bin/mysqld_safe &

       sleep 5

       mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER '${MYSQL_ROOT_USER}'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

	mysqladmin shutdown
fi

echo "Starting MariaDB..."
exec /usr/bin/mysqld_safe
