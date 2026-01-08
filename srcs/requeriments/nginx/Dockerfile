FROM debian:bookworm

# Instalar nginx y openssl para certificados
RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*
# por qué borramos lib/apt/lists??? para que la imagen pese menos

# Crear carpeta para certificados
RUN mkdir -p /etc/nginx/ssl

# Generar certificado auto-firmado (esto se puede hacer en script aparte si lo prefieres)
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=amacarul.42.fr"

# Copiar nuestra conf
COPY conf/nginx.conf /etc/nginx/sites-available/default
RUN ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

EXPOSE 443

# NGINX debe ejecutarse en primer plano para que el contenedor no se detenga
CMD ["nginx", "-g", "daemon off;"]

