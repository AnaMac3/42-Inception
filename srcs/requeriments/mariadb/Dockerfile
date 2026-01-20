# ==================================================================
# MariaDB Dockerfile
# 
# This Dockerfile builds a custom MariaDB image.
# The goal of this image is NOT only to install MariaDB, but to 
# prepare a clean and controlled environment where the database can 
# be safely initialized at container runtime.
# 
# Key design principles:
#   - Use minimal  and stable Linux base image (Debian Bookworm)
#   - Install MariaDB server using the distribution package manager
#   - Override the default MariaDB configuration to allow network
#   access from other containers (WordPress)
#   - Delegate database initialization logic to a runtime script 
#   (setup.sh) executed as the container entrypoint
#
# The creation of databases, users, and permissions is handled by
# the setup.sh script when the container starts, not at build time.
# This distinction is critical to ensure correct behaviour when using
# persistent volumes.
#
# ==================================================================

# Base image: Debian Bookworm
# Provides a minimal Linux filesystem with standard tools (apt, /etc, 
# usr...), an isolated container env built on top of the host kernel.
FROM debian:bookworm 

# Install MariaDB server
# The package includes the database daemon, client tools, and
# initialization scripts required to run the service.
# The package list is updated first to ensure the latest metadata.
RUN apt-get update && \
apt-get install -y mariadb-server \
rm -rf /var/lib/apt/lists/*

# Copy a custom MariaDB configuration file.
# By default, MariaDB binds only to localhost (127.0.0.1), which would
# prevent access from other containers.
# This custom conf enables MariaDB to listen on the Docker network
# interface, allowing WordPress to connect using the service name
# 'mariadb' as the database host
COPY conf/my.conf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy the database initialization script into the container.
# This script is responsible for:
#   - Starting the MariaDB service
#   - Creating the database and users
#   - Applying correct privileges
#   - Handling first-time initialization vs container restarts
COPY tools/setup.sh /usr/local/bin/setup.sh

# Grant execution permissions to the setup script
RUN chmod +x /usr/local/bin/setup.sh

# Document that the MariaDB server listents on 3306
# This does NOT expose the port to the host.
# The database remains accesible only within the Docker network,
# which is a deliberate security decision.
EXPOSE 3306

# Define the container entrypoint.
# When the container starts, this script becomes PID 1 and is 
# responsible for launching and managing the MariaDB service.
ENTRYPOINT ["setup.sh"]
