# Imagen base del contenedor: todo se construye encima de debian bookworm -> el contenedor tendrá filesystem debian, apt, /etc, /usr..., NO es la VM, es un sistema aislado
FROM debian:bookworm 

# descarga lista de paquetes
RUN apt-get update
# instala mysql, clientes y scripts de inicialización 
RUN apt-get install -y mariadb-server
# borra cache de apt, reduce tamaño de imagen, buena práctica docker
RUN rm -rf /var/lib/apt/lists/*

# copia tu configuracion personalizada, sobreescribe la config por defecto de mariadb. Por defecto, maridb escucha solo en localhost; como wordpress está en otro contenedor, necesita acceso por red docker
COPY conf/my.conf /etc/mysql/mariadb.conf.d/50-server.cnf
# copia el script de arranque, lo pone en un directorio del path
COPY tools/setup.sh /usr/local/bin/setup.sh

# da permisos de ejecución al script
RUN chmod +x /usr/local/bin/setup.sh

# Documenta que el contenedor escucha en 3306 (pero no abre puertos ni expone al host, la exposición real se hace en el docker-compose.yml)
EXPOSE 3306

# define qué se ejecuta cuando arranca el contenedor, reemplaza el proceso PID 1 -> cuando haces docker compose up mariadb, docker ejecuta el setup.sh
ENTRYPOINT ["setup.sh"]
