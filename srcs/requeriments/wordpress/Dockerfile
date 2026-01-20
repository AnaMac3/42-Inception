# ==================================================================
# WordPress Dockerfile
# 
# This Dockerfile builds a custom WordPress application image.
# The goal of this image is to provide a PHP-FPM environment capable
# of executing WordPress PHP code.
#
# WordPress itself is not installed at build time. 
# Instead, the image prepares all required tools and dependencies,
# while the actual WordPress installation and configuration are
# performed at container runtime by a dedicated setup script. 
#
# Key design principles:
#	- Use minimal and stable Linux base image (Debian Bookworm)
#	- Install PHP, PHP-FPM and only the required PHP extensions
#	- Do NOT include a web server (NGINX runs in a separate container)
# 	- Use WP-CLI to manage WordPress at runtime
# 	- Delegate initialization logic to a runtime script (setup.sh)
#	- Run PHP-FPM as the single foreground process (PID 1)
#
# Separating build-time preparation from runtime initialization is 
# essential to:
#	- Support persistent volumes
#	- Avoid reinstalling WordPress on container restarts
#	- Ensire deterministic container behavior
# ==================================================================

# Base image: Debian Bookworm
# Provides a minimal Linux filesystem with standard tools, running 
# inside an isolated container environment
FROM debian:bookworm

# Install PHP, PHP-FPM and required dependencies
# This container is responsible for running WordPress PHP code via
# PHP-FPM
# Installed packages:
#	- php8.2		: PHP interpreter required by WordPress
#	- php8.2-fpm	: FastCGI Process Manager (runs PHP as a service)
#	- php-mysql		: PHP extension for MariaDB/MySQL connectivity
#	- mariadb-client	: Allows communication with the MariaDB 
#						container (used by wp-cli during initialization)
#	- curl			: Required to download WP-CLI
#	- unxip			: Required by WordPress and wp-cli
#
# These operations happen at BUILD TIME and prepare the execution 
# environment, but do not start a service
RUN apt-get update && apt-get install -y \
	unzip \
	php8.2 \
	php8.2-fpm \
	php-mysql \
	curl \
	mariadb-client

# Install WP-CLI
# WP-CLI is a command-line interface for WordPress administration.
# It is used at runtime to:
#	- Download WordPress core files
#	- Generate wp-config.php
#	- Create users
#	- Install and configure WordPress automatically
#
# The binary is insstalled system-wide as 'wp'
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

# Create required runtime directory for PHP-FPM
# PHP-FPM uses /run/php to store socket and PID files.
# This directory does not exist in a minimal Debian image and must
# be created manually to prevent startup errors
RUN mkdir -p /run/php

# Copy custom PHP-FPM configuration
# Overrides the default PHP-FPM pool configuration.
# This custom configuration:
#	- Configurates PHP-FPM to listen on TCP port 9000
#	- Defines the user and group executing PHP processes
#	- Adjusts process management settings
#
# NGINX will forward PHP requests to this container via FastCGI	
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy WordPress runtime initialization script
# This script defines the container runtime behaviour, and is 
# responsible for:
#	- Waiting for the MariaDB service to become available
#	- Installing and configuring WordPress on first startup only
#	- Preserving data on container restarts when using volumes
#	- Starting PHP-FPM in foreground mode	
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Set working directory
# WordPress core files will be installed in this directory.
# All wp-cli commands and PHP execution happend from here
WORKDIR /var/www/html

# Expose PHP-FPM port
# PHP-FPM listens on port 9000 for FastCGI requests.
# This port is used internally by the NGINX container.
# It is NOT exposed to the host
EXPOSE 9000

# Container entrypoint
# The setup.sh script is defined as the ENTRYPOINT.
# It becomes the first process executed when the container starts.
# The script will eventually replace itself with PHP-FPM via 'exec',
# making the container's PID 1 and ensuring correct signal handling
# and clean shutdown
ENTRYPOINT ["setup.sh"]
