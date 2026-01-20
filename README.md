# 42-Inception
This project has been created as part of the 42 curriculum by amacarul.

- Docker technology
- Containers
- Service orchestration
- Networking
- Persistent storage
- Secure environment configuration

## Table of Contents
- [Description](#description)
- [Instructions](#instructions)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Build & Run](#build-&-run)
  - [Stop & Clean](#stop-clean)
- [Project description](#project-description)
  - [Docker](#docker)
    - [Virtual Machine vs Docker](#virtual-machine-vs-docker)
  - [Docker images and Dockerfile](#docker-images-and-dockerfile)
    - [Images](#images)
    - [Dockerfile](#dockerfile)
  - [Docker Compose](#docker-compose)
  - [Volúmenes - Persistencia de datos](#volúmenes---persistencia-de-datos)
    - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  - [Docker Network - cómo se comunican los contenedores](docker-network-cómo-se-comunican-los-contenedores)
    - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Variables de entorno y secretos](#variables-de-entorno-y-secretos)
    - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [NGINX, WordPress and MariaDB](#nginx-wordpress-and-mariadb)
    - [NGINX](#nginx)
    - [WordPress](#wordpress)
    - [MariaDB](#mariadb)
  - [Cómo se relacionan todos los conceptos](cómo-se-relacionan-todos-los-conceptos) 
- [Resources](#resources)

----------------------------------------

## Description

El proyecto **Inception** consiste en crear una infraestructura completa de servicios web utilziando **Docker** y **Docker Compose**, donde cada servicio se ejecuta en su propio contenedor, construido desde cero.  
El objetivo del proyecto es desplegar un **stack de servicios interconectados** de manera modular y segura, gestionando contenedores, volúmenes persistentes, redes internas y variables de entorno, siguiendo buenas prácticas de desarrollo y DevOps.  
El proyecto debe incluir:  
- **Tres contenedores independientes**:
  - **NGINX**: única puerta de entrada al sistema mediante HTTPS (TLS 1.2/1.3 ) en el puerto 443.
  - **WordPress + PHP-FPM**: servidor de aplicación web sin NGINX
  - **MariaDB**: base de datos independiente
- **Dos volúmenes persistentes** disponibles en `/home/<login>/data` de la host machine que ejecute docker:
  - Uno para la base de datos de MariaDB
  - Otro para los archivos de WordPress
- **Una Docker-network** que conecte los tres servicios entre sí:
  - NGINX se comunica con PHP mediante el puerto 9000
  - PHP conecta con MariaDB mediante el puerto 3306
- **Dockerfiles propios** para cada servicio (no se permite usar imágenes preconfiguradas, excepto Alpine o Debian)
- **Variables de entorno obligatorias** y credenciales fuera del repositorio (usar `.env` y/o Docker secrets)
- Todos los contenedores deben **reiniciarse automáticamente** si fallan ⚠️ DÓNDE GESTIONO ESTO? CÓMO SE PRUEBA??
- Prohibido usar: `latest`, `host`, `--link`, `links`, bucles infinitos (`sleep infinity`, `tail - f`, `bash`, `while true`, etc.) ⚠️ CÓMO EVITO USAR ESTO??
- El dominio de la aplicación debe ser `<login>.42.fr` y debe resolverse localmente hacia la VM donde corren los contenedores, de modo que el navegador del host pueda acceder a la web usando HTTPS.  
- Los Dockerfiles debe ser referenciados correctamente en el `docker-compose.yml` y gestionados desde el Makefile


----------------------------
More requeriments:
- En tu database WordPress tiene que haber dos usuarios: uno de ellos ha de ser el administrador, su username no puede contener 'admin', 'Admin', 'administrator, o 'Administrator' ✅
- para simplificar el proceso, debes configurar tu domain name to point a tu local IP address ✅ -> CREO QUE ESTO YA LO HAGO CON EL TUNEL SSH  Y TODO ESO, NO? SÍ, ESTO SE LOGRA MEDIANTE LA CONFIGURACIÓN DE /ETC/HOSTS Y SI ES NECESARIO UN TUNEL SSH- AVERIGUAR CÓMO SE HACE ESTO EN LOS ORDENADORES DE 42!!!
- Este domain name debe ser login.42.fr. usa tu propio login. amacarul.42.fr redirigirá a la dirección IP que apunta a la website de amacarul ✅

-> no tiene que haber contraseñas ⚠️ -> CÓMO QUE NO??
> se recomienda usar .env file para guardar las variables de entorno y para usar Docker secrets para almacenar infor confidencial ⚠️ -> SOLO USO .ENV POR AHORA
Por razones de seguridad, las credenciales, API keys, passwords, etc. deben guardarse localmente de varias maneras / en varios archivos y deben ser ignorados por git. Las credenciales almacenadas publicamente suponen el suspenso del proyecto.  
Puedes guardar tus variables (como domain name) en un archivo de variables de entorno cono .env.
-------------------------------------

## Instructions

### Prerequisites:
  - Acces to a Linux machine / VM ([see DEV_DOC](./DEV_DOC.md#virtual-machine-setup-virtualbox-debian))
  - Dockera and Docker Compose installed ([see DEV_DOC](./DEV_DOC.md#installing-docker-docker-compose-and-build-tools))

### Installation
   - Clone the repository:
     
            git clone git@github.com:AnaMac3/42-Inception.git
     
     Options:
     - Clone on your local machine and share the folder with the VM via VirtualBox Shared Folders ([see DEV_DOC](./DEV_DOC.MD#shared-folders-between-host-and-vm))
     - Clone directly inside the VM (creo que para esto habrá que instalar git en la VM no?? ⚠️)

   - Create the [`.env`](./DEV_DOC.md#environment-variables-env-file) file in `srcs/`
   - Create the persistent volume folders in the VM:

         mkdir -p /home/<login>/data/mariadb
         mkdir -p /home/<login>/data/wordpress

### Build & Run
   - Start all services:

         make

  > Note: `make` builds thee Docker images and starts all containers in the stack.

  - Networking / SHH tunneling (⚠️NO SÉ SI ESTE ES EL NOMBRE ADECUADO PARA ESTE PUNTO!!):
    - As services run inside the VM, HTTPS traffic must be forwarded to your host to access the site from the browser.
    - Domain configuration and SSH tunneling: [see DEV_DOC](./DEV_DOC#domain-configuration-and-ssh-tunneling).

   - Access to the website
     - Open in your browser:

               https://<login>.42.fr

### Stop & Clean

| Makefile command | Description |
|---------|--------------|
| `make` | Builds Docker images (if needed) and starts the full stack in detached mode. Internally, runs - it does `docker compose build` followed by `docker compose up -d` |
| `make stop` | Stops all running containers without removing them. Containers, networks, images, and volumes remain intact. |
| `make down` | Stops and removes containers and Docker Compose networks. Docker-managed volumes are removed, but bind-mounted persistent data in `/home/login/data/...` is preserved. Images are not deleted. |
| `male clean` | Stops and removes containers, networks, Docker-managed volumes, and project images. Persistent data directories in `/home/login/data/...` are not deleted. |
| `make fclean` | Performs `make clean`, then deletes all persistent data in `/home/login/data/...` and runs `docker system prune -a --force`. This fully resets the project to a fresh state.|


## Project description
NO SÉ SI ESTO PEGA AQUÍ O EN OTRO LUGAR, PERO PARA EXPLICAR EL CÓDIGO, EL PROYECTO ENTERO, EN ORDEN, LO IDEAL SERIA SEGUIR ESTA ESTRUCTURA:
- DOCKER_COMPOSE.YML -> ARQUITECTURA GLOBAL, FLUJO DE ARRANQUE, RELACIÓN ENTRE SERVICIOS
- DOCKERFILES -> QUÉ SE INSTALA, QUÉ SE COPIA... CÓMO SE CONSTRUYE CADA IMAGEN
- SCRIPTS DE ENTRYPOINTS / SETUP -> QUÉ OCURRE CUANDO EL CONTENEDOR ARRANCA, POR QUÉ NO SE HACE TODO EN EL DOCKERFILE, DIFERENCIA ENTRE BUILD TIME Y RUN TIME
- CONFIGURACIONES Y .ENV -> VARIABLES, SEGURIDAD, TLS, COMUNICACIÓN INTERNA ENTRE CONTENEDORES

### Docker
**Docker** es una herramienta que permite ejecutar aplicaciones en **contenedores**.  
Un **contenedor** es un entorno aislado y reproducible, es una especie de mini-sistema aislado que ejecuta una aplicación con solo las **dependencias necesarias**. No es una máquina virtual completa: es más ligero y rápido.  

Containers are isolated processes for each of your app's components. Each component runs in its own isolated environment, completely isolated from everything else on your machine.  

**Problemas que resuelve Docker:**
- Dependencias que son incompatibles con tu versión de software
- Dependencias en versiones diferentes
- Dependencias incompatibles entre proyectos
- Necesidad de reproducir entornos exactamente iguales
- Aislamiento de bases de datos, servidores web, etc.

**Qué contiene un contenedor**
- La aplicación (p.ej. WordPress, NGINX, MariaDB...)
- Sus dependencias (librerías, binarios)
- Archivos de configuración
- El entorno de ejecución mínimo necesario  
Un contenedor es la **instancia ejecutable de una imagen Docker**, no un sistema operativo ni una máquina virtual.

#### Virtual Machine vs Docker
| Virtual Machine | Contenedor Docker |
|-----------------|-----------|
| Incluye un sistema operativo completo con su kernel | Comparte el kernel del host |
| Pesada y lenta en arrancar | Muy ligero y arranca en milisegundos |
| Cada VM consume mucha RAM/CPU | Cada contenedor usa solo lo imprescindible |
| Diseñada para aislamiento total | Diseñado para despliegue rápido ; aislamiento de procesos y red, pero comparte kernel |

A menudo, los containers y las VM se utilizan juntas (como en este proyecto *Inception*). En vez de utilizar una máquina virtual para correr una aplicación, una máquina virtual con container runtime puede correr múltiples aplicaciones conteinarizadas -> mayor uso de recursos y reducción de costes.  

### Docker Images and Dockerfile
#### Images
Una **imagen Docker** es una **plantilla inmutable** de un sistema que contiene:
- Archivos de la aplicación
- Dependencias
- Configuraciones
- Comandos de arranque

**Diferencias entre imagen y contenedor**
| Imagen | Contenedor |
|--------|------------|
| Plantilla | Instancia ejecutable de la imagen |
| Inmutable | Puede modificarse durante su ejecución |
| Sin estado | Con estado temporal (se pierde al destruirse) |

#### Dockerfile
Un **Dockerfile** es archivo que define cómo construir una imagen de Docker. 

Ejemplo simplificado para NGINX:

      # Imagen base del contenedor: todo se construye sobre bookworm
      FROM debian:bookworm
      # Instala paquete nginx
      RUN apt update && apt install -y nginx
      # Copia la configuración personalizada, sustituyendo la configuración por defecto
      COPY ./config/default.conf /etc/nginx/conf.d/
      # Define el entrypoint
      ENTRYPOINT ["nginx", "-g", "daemon off;"]

  ⚠️ EXPLICAR QUÉ HACE CADA LÍNEA !!!
  ⚠️ NO SÉ SI ESTO DEBERIA IR EN EL README O EN EL DEV_DOC O SIMPLEMENTE SON DETALLES PARA MI QUE NO DEBERIAN IR EN NINGÚN LADO...

**Instrucciones principales de Dockerfile**
| Keyword | Definition |
|---------|------------|
| FROM | Indica a Docker en qué sistema operativo debe ejecutarse tu máquina virtual. Serán `debian:buster?bookworm?` para Debian o `alpine:x:xx` para Linux. |
| RUM | Eejcuta un comando en tu máquina virtual. Equivale a conectarse por SSH y escribir un comando bash. |
| COPY | Copia un archivo. Especificar la ubicación del archivo a copiar desde el directorio que contiene tu Dockerfile y luego especificar dónde se quiere copiar dentro de la máquina virtual.  |
| EXPOSE | Indica los puertos de red específicos en los que se escucha durante la ejecución. No permite que el host acceda a los puertos del contenedor; expone el puerto especificado y lo hace disponible solo para la comunicación entre contenedores.  |
| ENTRYPOINT | Especifica el comando para iniciar el contenedor. |
| CMD | Argumentos por defecto del ENTRYPOINT |

**Buenas prácticas:**
- Un contenedor debe ejecutar **un solo servicio**
- No ejecutar daemons ni bucles infinitos para mantener el contenedor vivo
- Usar imágenes base ligeras y versionadas
- Limpiar cachés de paquetes
- Usar ENTRYPOINT correctamente
  Usar:

          ENTRYPOINT ["mysql"]
  Nunca:

          CMD service myswl start && tail -f /dev/null

**Imagen -> contenedor en ejecución -> corre un único servicio**.
En este proyecto se piden tres servicios principales:
  
| Servicio | Contenedor | Qué contiene |
|----------|------------|--------------|
| NGINX | `nginx` | Servidor web con TLS |
| WordPress+PHP-FPM | `wordpress`| PHP + WordPress, sin nignx |
| MariaDB | `mariadb` | Database |

**Debian vs Alpine**: explicar por qué uso debian en vez de alpine: porque es más fácil para empezar... y por qué más?

 > En este proyecto, como base de cada imagen, se puede usar:  
          - **Debian**: FROM debian:bookworm  
          - **Alpine**: FROM alpine:3.18  
  
          En *Inception* está prohibido usar imágenes prefabricadas como:
          
                FROM nginx:latest
                FROM mariadb:latest
                FROM wordpress:latest
  
#### PID 1 y ENTRYPOINT
  ⚠️ HAY QUE HACER ESTE APARTADO MÁS CLARO... RESUMIR Y EXPLICAR BIEN LAS RELACIONES ENTRE LOS DIFERENTES CONTAINERS/SERVICIOS Y SUS ENTRYPOINTS...
En Linux, **PID 1** es el primer proceso que se ejecuta en el sistema.  
Es responsable de:
- gestionar señales
- reaprovechar procesos zombie

En Docker, **cada contenedor tiene su propio PID 1**, que es proceso definido en el Dockerfile por:
- `ENTRYPOINT`
- `CMD`, si no hay `ENTRYPOINT`

**Relación PID 1 <-> contenedor**
- El proceso que se ejecuta como PID 1 mantiene vivo el contenedor
- Si ese proceso termina, el contenedor se muere
- Algunos programas necesitan ajustes para funcionar correctamente como PID1, lo que causa:
  - Contenedores que no se detienen correctamente con `docker stop`
  - Procesos zombie
  - señales que no se gestionan correctamente
  - contenedores que se cierran solos o crashean
- Por eso en *Inception* está prohibido usar bucles infinitos. Tampoco se deben lanzar procesos en background y salir del script. ???

**Foreground vs background**  
Un proceso en **foreground**:
- No se ejecuta con `&`
- No termina
- Mantiene vivo el contenedor
Un proceso en **background**
- Se lanza con `&`
- El script puede terminar
- El contenedor se cierra  
**¿Cómo se consigue un proceso en foreground?**   
Se usa `exec`:

      exec mysql_safe
      exec pgp-fpm -F
      exec nginx -g "daemon off;"

`exec`:
- reemplaza el proceso del script
- convierte ese proceso en **PID 1**
- permite que Docker envíe señales correctamente

**Un proceso principal por contenedor**
- Cada contenedor debe tener **un solo proceso principal**
- Ese proceso vive en foreground
- El contenedor vive mientras el proceso viva

| Contenedor | Proceso PID 1 |
|------------|---------------|
| mariadb | mysql_safe |
| wordpress | php-fpm (⚠️ PROFUNDICAR EN QUÉ ES ESTO, QUÉ ES PHP-FPM, QUÉ ES CADA ENTRYPOINT DE CADA CONTAINER!)|
| nginx | nginx |

**Apagado limpio de contenedores**  
Cuando se ejecuta 

    docker compose stop

Docker:
- Envía `SIGTERM` al PID 1
- Espera unos segundos
- Si no responde, envía `SIGKILL`

Si el proceso está en foreground y gestiona señales correctamente, el contenedor se apaga limpiamente.   ⚠️ TODO ESTO SE GESTIONA EN LOS DOCKERFILES, NO???


### Docker Compose
**Docker Compose** es una herramienta que permite definir y ejecutar varios contenedores a la vez junto con sus redes y sus volúmenes. Se gestiona através de un archivo `docker-compose.yml`, que constituye el plano arquitectónico del proyecto y en el que se definen:
- Servicios (qué contenedores hay: nginx, wordpress, mariadb)
- Redes (cómo se comunican)
- Volúmenes (dónde guardan datos persistentes)
- Variables de entorno
- Dependencias
- Reconstrucciones automáticas
- Puertos expuestos
- Orden lógico del sistema

El Makefile ejecuta el `docker-compose.yml`.   

#### Explicación del `docker-compose.yml` de *Inception* 
Este archivo define toda la arquitectura del proyecto:
- 3 servicios:
  - `mariadb` -> capa de datos
  - `wordpress` -> capa de aplicación (PHP)
  - `nginx` -> capa de entrada (reverse proxy + TLS)          
- 1 red interna:
  - `inceptionnet` -> permite que los contenedores se comuniquen por nombre
- 2 volúmenes persistentes:
  - WordPress (`/var/www/html`)
  - MariaDB (`/var/lib/mysql`)

##### Ejemplo simplificado:

        services:
          nginx:
            build: ./requirements/nginx
            ports:
              - "443:443"
            volumes:
              - wordpress_data:/var/www/html
            networks:
              - inception
        
          wordpress:
            build: ./requirements/wordpress
            networks:
              - inception
        
          mariadb:
            build: ./requirements/mariadb
            volumes:
              - db_data:/var/lib/mysql
            networks:
              - inception
        
        volumes:
          wordpress_data:
          db_data:
        
        networks:
          inceptionnet:

| keyword o como llamar a esto? | Description |
|-----|------|
| `services` | definen los servicios que ejecutarán los contenedores. Servicios que tenemos: `nginx`, `wordpress`, `mariadb`. |
| `container_name` | asigna un nombre específico al contenedor que se crea a partir de este servicio |
|  `build` | indica la ubicación del Dockerfile y los archivos necesarios para construir la imagen del contenedor |
| `image` | indica qué imagen debe usarse como base para el servicio que estás definiendo. Si la imagen no se encuentra a nivel local en el sistema docker, la descargará automaticamente (CREO QUE ESTO ES ALGO QUE HAY QUE EVITAR) |
| `ports` | mapeo de puertos. PUERTO_HOST:PUERTO_CONTENEDOR |
| `volumes` | creamos un volumen en el host al directorio que especifiquemos en el contenedor. EXPLICAR QUÉ SON LOS VOLUMES... |
| `restart` | indica cómo debe comportarse el contenedor en caso de que se detenga. Indicamos que tiene que reiniciar |
| `networks` | especifica a qué redes tiene que estar conectado el contenedor |
| controlador de red `bridge` | permite a los contenedores comunicarse entre sí en el mismo host |
 

##### Flujo de arranque:  
Cuando ejecutas `docker-compose up`, ocurre lo siguiente:
1. Docker crea la red `inceptionnet`
2. Docker construye las imágenes (si no existen)
3. Docker arranca los contenedores, respetand:
   - `mariadb` primero
   - luego `wordpress`
   - finalmente `nginx`
   ⚠️ `depends_on` **NO garantiza** que el servicio esté listo, solo que el contenedor haya arrancado. Por eso luego se utilizan scripts de espera (`sleep`) ⚠️⚠️⚠️⚠️ REPASAR QUE ESOS SCRIPTS DE ESPERA NO SEAN LOS PROHIBIDOS POR EL SUBJECT!!!

##### Comunicación entre servicios
La red `inceptionnet` permite que:
- WordPress se conecta a MariaDB usando `host = mariadb` DÓNDE PASA ESTO???
- Nginx se conecta a WordPress usando `fastcgi_pass wordpress:9000` (`/nginx/conf/nginx.conf`)

          Internet -> NGINX -> WordPress -> MariaDB

##### Persistencia de datos
Se utilizan bind mounts

        /home/login/data/wordpress
        /home/login/data/mariadb

### Volúmenes - Persistencia de datos
Un contenedor puede morir, pero los datosimportantes deben sobrevivir. Por eso existen los volúmenes:

      volumes:
          wordpress_data:
          mariadb_data:

*Inception* exige que estén montados en:

        /home/<login>/data/wordpress
        /home/<login>/data/mariadb

Sirven para:
- con MariaDB -> persistir la base de datos
- con WordPress -> guardar plugins, temas, uploads

Si destruyes el contenedor y lo vuelves a levantar:

      docker compose down
      docker compose up --build

Tus datos siguen ahí.  
Estos datos se borran con ... ⚠️ : 

#### Docker Volumes vs Bind Mounts
Los contenedores son efímeros: si borras un contenedor, se borra su filesystem, es decir, se pierden las bases de datos, uploads, etc.  
Para evitarlo, Docker permite la **persistencia de datos fuera del contenedor** de dos maneras diferentes:
- Docker volumes
- Bind mounts

##### Docker Volumes
Son espacios de almacenamiento creados y gestionados por Docker, independientes del contenedor. Docker decide dónde vive el host.
Ejemplo:

        services:
          mariadb:
            volumes:
              - db_data:/var/lib/mysql

        volumes:
          wordpress_data:
          db_data:

Normalmente se guardan en `var/lib/docker/volumes/db_data/_data`. Esta es una ruta que no controlas tú.  
Ventajas:
- Son fáciles de usar
- Más seguros (Docker controla permisos)
- Portables
- Recomendados en producción real

Desventajas:
- No sabes exactamente dónde están
- El subject exige una ruta concreta
- No puedes demostrar fácilmente la persistencia en `/home/login/data`

##### Bind Mounts
Montajes directos del host. Un bind mount conecta una carpeta del host con una carpeta del contenedor.  
Ejemplo: 

        /home/login/data/mariadb:/var/lib/mysql

Los datos se guardan donde tú decides.  
Puedes hacer `ls /home/login/data/mariadb` y ver los archivos de la database.  
Ventajas:
- Control absoluto de la ruta
- Fácil de inspeccionar
Desventajas:
- Más fácil romper permisos
- Menos portable
- El host "interfiere" más

### Docker Network - cómo se comunican los contenedores
Los contenedores están aislados entre sí.  
Para comunicarse, deben estar en la misma red Docker:

      networks:
          inception:
            driver: bridge

Esto permite:
- NGINX -> PHP-FPM por el puerto 9000
- PHP-FPM -> MariaDB por el puerto 3306

Los contenedores se buscan por su nombre de servicio:

    fastcgi_pass wordpress:9000;

???? ⚠️ DONDE APARECE ESTO???

QUÉ SON LOS HOST NETWORKS???

#### Docker Network vs Host Network
?????

### Variables de entorno y secretos
Nunca se deben poner contraseñas en el repositorio.
Usar `.env` para:

    ....

Usar secrets para...: ⚠️⚠️⚠️⚠️

⚠ Cosas que meter en github:
    - Makefile
    - docker-compose.yml
    - Dockerfiles
    - scripts
    - Configuraciones (nginx.conf, www.conf, etc)
  - Cosas que no deben subirse a github:
    - Los volúmenes: /home/login/data -> estos se crean en la máquina virtual, no se guardan en github
    - archivo .env si contene contraseñas -> debe estar en .gitignore
    - certificados TLS generados
   
#### Secrets vs Environment Variables
   
### NGINX, WordPress and MariaDB
Aunque el foco del proyecto es **Docker y la infraestructura**, es importante entender qué servicios estamos containerizando:

#### NGINX
**NGINX** es un servidor web muy ligero y rápido. En este proyecto cumple dos funciones:
1. Servir contenido HTTPS mediante un certificado TLS.
2. Actuar como reverse proxy, enviando las peticiones `.php` al contenedor de PHP-FPM (WordPress).
NGINX es más eficiente que Apache para manejar muchas conexiones simultáneas.

| certificado TLS |
|-----|
| Un certificado TLS (Transport Layer Security) es un protocolo que cifra la comunicación entre el navegador y tu servidor (HTTPS). Es un archivo que: <br>- identifica al servidor <br> - permite cifrar el tráfico HTTPS <br>- asegura que la comunicación no puede ser leída por terceros |

En este proyecto/esquema, NGINX actúa como **servidor web** y **proxy inverso**. Sus funciones son:
- Punto de entrada único: es el único contenedor que expone puertos al mundo exterior (puerto 443).
- Terminación TLS: el tráfico viaja cifrado desde el navegador hasta NGINX. NGINX "desencripta" la petición usando tus certificados generados con OpenSSL (??).
- Servidor de archivos estáticos: ...
- Pasarela FastCGI: ...??? ⚠️


#### WordPress
**WordPress** es un CMS (Content Management System) escrito en PHP. Permite crear con facilidad:
- páginas
- blogs
- usuarios
- plugins
- temas
En este proyecto debe ejecutarse con PHP-FPM (no con Apache) porque:
- NGINX no ejecuta PHP directamente
- PHP-FPM gestiona procesos PHP como un servicio separado. PHP-FPM es el proceso que ejecuta PHP y espera repeticiones.


El flujo es:

Navegador -> NGINX (443) -> PHP-FPM (9000) -> WordPress (PHP) -> MariaDB (3306)

WP-CLI: herramienta oficial de wordpress para administrar por línea de comandos. Con WP-CLI se pueden hacer cosas como:
- descargar wordpress
- crear wp-config.php
- instalar wordpress
- crear usuarios
- activar plugins / themes...

En este proyecto no se puede usar el navegador para instalar wordpress, todo debe hacerse automáticamente, con wp-cli.

#### MariaDB
**MariaDB** es un sistema de bases de datos SQL (alternativa a MySQL, en realidad es un fork de MySQL). WordPress lo usa para guardar:
- posts
- usuarios
- contraseñas
- configuraciones
- plugins
- etc
Los datos deben persisitir en un volumen, para que no se pierdan al destruir contenedores.


### Cómo se relacionan todos los conceptos

1. **Dockerfiles** construyen imágenes para cada servicio
2. **Compose** define cómo se conectan: redes, volúmenes, puertos
3. **Compose levanta los contenedores** en el orden necesario
4. **NGINX** recibe tráfico HTTPS y lo pasa a PHP-FPM (WordPress)
5. **WordPress** consulta la base de datos en MariaDB
6. **Los volúmenes** garantizan que WordPress y MariaDB persistan datos
7. **Las varaibles de entorno** configuran credenciales y dominio
8. El sistema funciona como una infraestructura real

-> Docker Engine??  
Docker engine es el componente base de Docker. Es lo que empaqueta tu aplicación y sus dependencias en un solo paquete, llamado container ???. El Docker Engine incluye el Docker **daemon** que es un proceso background que gestiona los containers de Docker y el cliente de Docker, que es la herramienta de linea de comandos que te permite interactuar con docker daemon.   
Cómo funciona Docker engine:
- Escribes un Dockerfile que contiene las instrucciones para construir una Docker image. La Docker image es es un paquete ejecutable que contiene todo o necesario para correr una parte de software??
- Usas el cliente Docker para construir la imagen Docker by running `docker build` command y especificicando la ruta del Dockerfile. Docker daemon lee las instrucciones en el Dockerfile y construye la imagen.
- Cuando la imagen ya está construida, puedes usar el Docker client para correr la imagen como un container usando `docker run`. El Docker daemon crea un contenedor para la imagen y ejecuta la app dentro del container
- Docker engine proporciona un environment seguro y aislado para ejecutar la app en el y también gestiona recursos como el CPY, memoria y almacenamiento para el contenedor
- Puedes usar Docker client para ver, parar y gestionar containers en ejecución en tu sistema. También peudes usar docker client para pushear la iamgen docker a un registro como docjer Hub

-------------------------------------

### Crear estructura del proyecto

NO SÉ SI ESTO PEGA AQUÍ O EN OTRO LUGAR, PERO PARA EXPLICAR EL CÓDIGO, EL PROYECTO ENTERO, EN ORDEN, LO IDEAL SERIA SEGUIR ESTA ESTRUCTURA:
- DOCKER_COMPOSE.YML -> ARQUITECTURA GLOBAL, FLUJO DE ARRANQUE, RELACIÓN ENTRE SERVICIOS
- DOCKERFILES -> QUÉ SE INSTALA, QUÉ SE COPIA... CÓMO SE CONSTRUYE CADA IMAGEN
- SCRIPTS DE ENTRYPOINTS / SETUP -> QUÉ OCURRE CUANDO EL CONTENEDOR ARRANCA, POR QUÉ NO SE HACE TODO EN EL DOCKERFILE, DIFERENCIA ENTRE BUILD TIME Y RUN TIME
- CONFIGURACIONES Y .ENV -> VARIABLES, SEGURIDAD, TLS, COMUNICACIÓN INTERNA ENTRE CONTENEDORES

Estructura del proyecto:
   
           inception/
                  │
                  ├── Makefile
                  ├── .gitignore
                  ├── README.md (opcional)
                  └── srcs/
                      ├── .env
                      ├── docker-compose.yml
                      └── requirements/
                          ├── nginx/
                          │   ├── Dockerfile
                          │   ├── conf/
                          │   │   └── nginx.conf
                          │   └── tools/
                          │       └── generate_cert.sh
                          │
                          ├── wordpress/
                          │   ├── Dockerfile
                          │   ├── conf/
                          │   │   └── www.conf
                          │   └── tools/
                          │       └── wp_setup.sh
                          │
                          └── mariadb/
                              ├── Dockerfile
                              ├── conf/
                              │   └── my.cnf
                              └── tools/
                                  └── mariadb_init.sh

- `.env`: contiene contraseñas y datos sensibles, no se sube al repositorio
     
8. Crea las carpetas del host que luego montarás como volúmenes / estructura de directorios

       mkdir -p /home/<login>/data/wordpress
       mkdir -p /home/<login>/data/mariadb

       #Ajustar permisos para que Docker pueda escribir
       sudo chown -R <login>:<login> /home/<login>/data

        
## Definir `docker-compose.yml` (servicios, redes, volúmenes y dependencias)
El archivo `docker-compose.yml` es un archivo de configuración utilizado para definir y gestionar múltiples contenedores en un entorno Docker. Permite describir las relaciones, configuraciones y servicios que compondrán una aplicación o conjunto de servicios interconectados.  
- definir qué servicios existen
- Para cada servicio:
  - build (ruta al Dockerfile)
  - env_file
  - volumes
  - networks
  - depends_on
  - ports (solo nginx)
 

            services: #define los contenedores que van a existir
              nginx:
                build: ./requeriments/nginx #docker construye la imagen usando el dockerfile en este directorio -> no usa imágenes prehechas
                container_name: nginx #construye el contenedor con ese nombre en vez de con nombres aleatorios
                env_file: #carga todas las variables de .env
                  - .env
                ports:
                  - "443:443" #VM escucha en 443:443, redirige a 443 el contenido nginx, único servicio expuesto al exterior
                volumes:
                  - /home/amacarul/data/wordpress:/var/www/html #donde wordpress se instala, guarda themes, uploads... NGINX necesita leer estos archivos; wordpress y NGINX comparten volumen
                depends_on: #dependencias: arranca wordpress antes
                  - wordpress
                networks:
                  - inception #crea una red privada docker
                restart: always
            
              wordpress:
                build: ./requeriments/wordpress
                container_name: wordpress
                env_file:
                  - .env
                volumes:
                  - /home/amacarul/data/wordpress:/var/www/html
                depends_on: #arranca mariadb antes
                  - mariadb
                networks:
                  - inception
                restart: always
            
              mariadb:
                build: ./requeriments/mariadb
                container_name: mariadb
                env_file:
                  - .env
                volumes:
                  - /home/amacarul/data/mariadb:/var/lib/mysql #donde mariadb guarda db, tablas, users. Si se borra el contenedor, si no hay volumen, se pierde la base de datos. COn volumen, la base de datos persiste.
                networks:
                  - inception
                restart: always
            
            networks:
              inception:
                driver: bridge

Tras configurar el archivo `docker-compose.yml`, ejecutar:

      docker compose config

Si no hay errores, seguimos.

[Comandos del docker compose](https://iesgn.github.io/curso_docker_2021/sesion5/comando.html)


-------------
EXPLICACIÓN EN BURDO SOBRE CÓMO FUNCIONA ESTO:  
Las imágenes de docker son plantillas, creamos una para mariadb, otra para wordpress y otra para nginx, con sus respectivos Dockerfiles.  
Los contenedores son instancias en ejecución de las imágenes. A partir de una imagen podemos crear uno o varios contenedores. El contenedor es lo que se ejecuta.  
docker-compose.yml define qué contenedores se crean a partir de qué imágenes, cómo se conectan entre ellos, las redes, los volúmenes, las variables de entorno y los puertos. En Inception, docker-compose no descarga imágenes externas, sino que usa `build` para construir imágenes locales y luego levanta los contenedores con esas imágenes `up`.   
Flujo de ejecución:  

      docker compose build
      docker compose up
      
Opción no manual para hacer todo a la vez:

      docker compose up --build

¿Qué pasa cuando los contenedores están `up`?   
- Mariadb: arranca y crea la base de datos y el usuario
- Wordpress (php-fpm): se conecta a mariadb por la red interna de docker
- nginx: escucha en el puerto 443(TLS obligatorio en inception) y reenvia peticiones php a wordpress.

Parar contendores: detiene los contenedores pero no los borra, se pueden volver a arrancar con `up`:

      docker compose stop

Parar un contenedor concreto:

      docker stop wordpress

Matar contendores (forzar parada, usar solo si stop no funciona):

      docker kill wordpress

Parar y borrar contenedores (no borra volúmenes por defecto): 

      docker compose down

Para borrar también volúmenes:

      docker compose down -v


-------------------

## Construcción de cada imagen
### MariaDB
   - Dockerfile
     - Tiene que construir la imagen
     - Instalar mariadb-server / mysql
     - Copiar la configuración personalizada, sobreescribiendo la config por defecto de mariadb (para que tenga acceso por red docker)
     - Copiar el script de arranque en el directorio que toca
     - Dar permisos para ejecutar ese script
     - Documentar que escucha en 3306
     - Definir el entrypoint (qué se ejecuta cuando arranca el contenedor), reemplaza pid1 -> hemos hecho que el entrypoint sea setup.sh, que hace `exec mysql_safe`, por lo que `mysql_safe` es el PID1. El contenedor vivirá mientras MariaDB esté viva.
   - setup.sh
     - arranca mariadb
     - inicializa DB y usuarios si no existen
     - deja mysql corriendo
   - Instalación de la base de datos
   - Inicialización de usuarios y permisos
   - Configuración persistente del volúmen

MariaDB es la base de datos para el wordpress que hagamos. WordPress necesita conectarse a ella par aguardar posts, usuarios, configuración, etc. Antes de que wordpress pueda arrancar, mariadb debe:
1. Arrancar el servidor (`mysql` o `service mysql start`)
2. Crear la base de datos que va a usar wordpress ->   CÓMO ES ESTA BASE DE DATOS? DÓNDE LA CONFIGURO???⚠️
3. Crear un usuario con contraseña que wordpress usará
4. Dar permisos a ese usuario sobre la base de datos
5. Condigurar la contraseña de root y refrescar privilegios
El `setup.sh` de mariadb prepara la base de datos para que wordpress puede usarla sin problemas.
  
     --> archivos Dockerfile, setup.sh y my.conf de mariadb hechos.
     --> Cómo probar solo mariadb: desde srcs

         docker compose build mariadb
         docker compose up mariadb

     En otra terminal:

         docker ps #muestra los contenedores que están corriendo
         docker logs mariadb #muestra logs existentes

     Ahí tienes que ver:
     - inicialización la primera vez
     - solo arranque las siguientes


¡¡¡EXPLICAR QUÉ SE HACE EN CADA ARCHIVO PASO A PASO!!!  

      
### WordPress + PHP-FPM
   - Dockerfile
   - Instalación manual de PHP, PHP-FPM -> 
   - Descarga de WordPress
   - Configuración dinámica con variables de entorno
   - Script de setup

Entrar en el container:

    docker exec -it wordpress bash

Comprobar conexión desde WordPress al contenedor MariaDB:

      docker exec -it wordpress bash
      mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE

Si funciona, la base de datos es accesible.

Comprobar que wordpress se ha instalado correctamente:

      # conectarse al contenedor
      docker exec -it wordpress bash
      # ver si existe el archivo wp-config.php -> si existe, wordpress está configurado
      ls -l /var/www/html

Verificar que wordpress puede conectar a mariadb:

        wp db check --allow-root

Ver usuarios de wordpress:

      wp user list --allow-root

Comprobar que wordpress responde (sin navegador):

      docker exec -it wordpress wp core is-installed --allow-root
      # tiene que devolver exit code 0

### NGINX
   - Dockerfile
   - Configuración TLS
   - Exposición del puerto 443
   - Configuración de fastcgi_pass
   - Scripts necesarios -> creo que hay parte del dockerfile que deberia ir a script
   - 

⚠️ IMPORTANTE!!: EJECUTAR EL MAKE FCLEAN CON SUDO!! 

        sudo ls && make fclean



## Configuración del dominio
- `/etc/hosts`-> `login.42.fr`

En terminal:

      sudo nano /etc/hosts

Añadir línea:

      127.0.0.1 login.42.fr

Guardar con Ctrl+O, Enter, salir con Ctrl+X

Probar: ping login.42.fr, si responde desde 127.0.0.1, está bien configurado.

⚠️COMO ESTAMOS EN UNA VM HAY QUE HACER UN TUNEL SSH QUE CONECTE EL 443 CON EL NAVEGADOR (?):
- Windows (con WSL):
  - En terminal, ejecutar:

            ssh -L 443:localhost:443 login@<IP_DE_VM>

  - Mantener esa ventana abierta. Mientras esté conectada, el túnel estará activo.
  - Abrir en Chrome https://localhost
  - 
- TAMBIÉN HAY QUE HACER ESTO EN WINDOWS --> 
  - Pulsar tecla Windows y escribir block de notas
  - Click dcho, seleccionar Ejecutar como admin
  - Dentro de block de notas ir a Archivo -> Abrir
  - Ruta: C:\Windows\System32\drivers\etc
  - Cambiar filtro de documentos de texto txt a Todos los archivos
  - Abrir el arhcivo host
  - Añadir al final del archivo la línea: 127.0.0.1 amacarul.42.fr
  - Guardar y cerrar
 
- En iMacs con Linux:
  - Como no somos sudo no podemos usar el puerto 442 local
  - Solución: Mapeo de puertos altos: usaremos un puerto libre, como 8443
  - En terminal:
 
          ssh -L 8443:localhost:443 login@<IP_DE_VM>

  - En el navegador: https://localhost:8443
  - Explicación: se redirige el puerto 443 de la VM al 8443 del IMac mediante un túnel SSH, porque no tenemos privilegios de root en el host para usar el puerto 443 o editar el archivo host.
 
Otra opción para los ordenadores de 42: Proxy SOCKS ⚠️ PENDIENTE DE PROBAR!!!:
- Crear túnel SOCKS con SSH:

         ssh -D 8080 login@<IP_VM>

- Mantener terminal abierta
- Configurar el navegador (firefox)
  - Ajustes -> configuración de red
  - Configuración manual de proxy
  - Servidor SOCKS: 127.0.0.1 y puerto 8080
  - Marcar casilla: Proxy DNS cuando se utiliza SOCKS v5
  - Cuando escribas login.42.fr en la barra de direcciones, Firefox no le preguntará al iMac (donde no eres sudo), sino que le preguntará a la VM a través del tunel.

## Pruebas del sistema
- Comprobación de que todos los contenedores arrancan
- Conexión entre servicios
- Acceso HTTPS:

        curl -k https://amacarul.42.fr

- Persistencia de datos
- Revisión de logs -> creo que esto se mira en data/mariadb/wordpress -> wp_users.idb, wp_usermeta.idb
- Creación de posts -> wp_posts, wp_postmeta, wp_term_relationships, wp_terms, wp_term_taxonomy ???
- en data/wordpress/wp-content -> uploads (imagenes subidas), plugins, themes...

COSAS A PROBAR:
- Hacer login en la página: https://login.42.fr/wp-login.php ó /wp-admin
- Crear entrada: en https://login.42.fr/wp-admin -> menú izquierdo -> entradas -> añadir nueva -> escribir título y contenido -> publicar -> esto crea filas en wp_posts, wp_postmeta
- Comprobar qué se modifica cuando haces esto:
  - Ver usuarios:

            #entrar al contenedor mariadb
            docker exec -it mariadb bash
            mysql -u root -p
            #ejecutar SQL
            SHOW DATABASES;
            USE wordpress;
            SELECT user_login, user_registered FROM wp_users;
    
  - Ver posts:
    
              SELECT ID, post_title, post_status FROM wp_post
  
  - Ver archivos subidos:
  
              ls data/wordpress/wp-content/uploads

-------------------------------------

## Resources
[Forstman1 repo](https://github.com/Forstman1/inception-42)  
[gemartin99 repo](https://github.com/gemartin99/Inception?tab=readme-ov-file)  
[Grademe tutorial](https://tuto.grademe.fr/inception/)  
[dockerdocs](https://docs.docker.com/)  
[dockerdocs - Building best practices](https://docs.docker.com/build/building/best-practices/)  
[Docker compose commands](https://iesgn.github.io/curso_docker_2021/sesion5/comando.html)   
[Docker commands](https://kinsta.com/es/blog/comandos-docker/)  
[Dockerfile keywords](https://www.nicelydev.com/docker/mots-cles-supplementaires-dockerfile#:~:text=Le%20mot%2Dcl%C3%A9%20EXPOSE%20permet,utiliser%20l'option%20%2Dp%20.)  
[SQL keywords](https://www.w3schools.com/sql/sql_ref_keywords.asp)  
[WordPress documentation](https://wordpress.org/documentation/)  
