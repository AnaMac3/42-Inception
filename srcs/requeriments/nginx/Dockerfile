# ==================================================================
# NGINX Dockerfile
# 
# This Dockerfile builds a custom NGINX web server image.
# The goal of this image is to provide a minila HTTPS web server 
# capable of serving static content and proxying request to the
# WordPress PHP-FPM container.
# 
# Key design principles:
#	- Use minimal and stable Linux base image (Debian Bookworm)
#	- Install only required packages (nginx and openssl)
#	- Generate TLS certificates for HTTPS
#	- Copy a custom NGINX configuration tailored for WordPress
#	- Keep NGINX running in doreground as the single container process
#
# This container is stateless: it does not manage application data
# or database connections. Its only responsibility is to serve
# HTTPS requests and forward PHP requests to PHP-FPM
# ==================================================================

# Base image: Debian Bookworm
# Provides a minimal Linux filesystem with standard tools, running 
# inside an isolated container environment
FROM debian:bookworm

# Install NGINX and OpenSSL
# These packages are installed at build time to provide the web server
# and TLS functionality
#	- nginx: the web server and reverse proxy
#	- openssl: used to generate self-signed certificates
# Temporary package lists are removed to reduce the final image size
RUN apt-get update && apt-get install -y nginx openssl \
&& rm -rf /var/lib/apt/lists/*

# Create directory for SSL certificates
# NGINX requires a location to store TLS keys and certificates
RUN mkdir -p /etc/nginx/ssl

# Generate self-signed TLS certificate
# For development purposes, a self-signed certificate is generated
# at build time. In production, certificates should be issued by
# a trusted Certificate Authority (CA). 
# Options explained:
#	- req: create a certificate signing request (CSR) or self-signed cert
#	- -x509: output a self-signed certificate instead of CSR
#	- -nodes: do not encrypt the private key (prevents password prompt
#	on startup)
#	- -days 365: valid for 1 year
#	- -newkey rsa:2048: generate a new 2048-bit RSA key
#	- -keyout: path to store the private key
#	- -out: path to store the certificate
#	- -subj: certificate subject (DN), including CN = domain name
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=amacarul.42.fr"

# Copy custom NGINX configuration
# The configuration file defines:
#	- TLS settings
#	- Reverse proxy to PHP-FPM container
# 	- Default server settings
# The file is copied into sites-available and linked to sites-enabled
# for activation 
COPY conf/nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Expose HTTPS port
# NGINX listens on port 443 for secure HTTPS traffic. 
# This port is exposed for inter-container networking and host access
EXPOSE 443

# Container entrypoint
# NGINX must run in foreground to keep the container alive
# The 'daemon off;' directly prevents NGINX from forking into background,
# ensuring the main process becomes PID 1
CMD ["nginx", "-g", "daemon off;"]
