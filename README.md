# 42-Inception
42 Common Core Inception 
- de qué va??
- System administration
- Docker technology

## Table of Contents
- [Description](#description)
- [Instructions](#instructions)
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
- [Guía paso a paso](#guía-paso-a-paso)
  - [Preparar la Virtual Machine](#preparar-la-virtual-machine)
    - [Instalar Docker y Docker Compose](#instalar-docker-y-docker-compose)
    - [Cómo compartir carpetas entre la VM y el host](cómo-compartir-carpetas-entre-la-VM-y-el-host)
  - [Crear estructura del proyecto](#crear-estructura-del-proyecto)
  - [Archivo .env](#archivo-env)
  - [Definir docker-compose.yml (servicios, redes, volúmenes y dependencias)](#definir-docker-compose.yml-(servicios-redes-volumenes-y-dependencias))
  - [Construcción de cada imagen](#construcción-de-cada-imagen)
  - [Configuración de de dominio](#configuración-de-dominio)
- [Resources](#resources)

----------------------------------------

## Description

El proyecto **Inception** consiste en crear una infraestructura completa usando **Docker** y **Docker Compose**, donde cada servicio se ejecuta en su propio contenedor, construido desde cero.
Hay que configurar:
- **3 contenedores independientes**:
  - **NGINX** con TLS 1.2/1.3 (única puerta de entrada al sistema, puerto 443)
  - **WordPress + PHP-FPM** (sin NGINX)
  - **MariaDB** (solo base de datos)
- **2 volúmenes persistentes**:
  - Uno para la base de datos de MariaDB
  - Uno para los archivos de WordPress
- **Una Docker-network** que conecte los tres servicios entre sí.
  - NGINX se conecta a PHP -> puerto 9000
  - PHP conecta con MariaDB -> puerto 3306 (esto va aquí???)
- **Dockerfiles propios** para cada servicio (no se permite usar imágenes preconfiguradas - excepto Alpine o Debian)
- **Variables de entorno obligatorias**, credenciales fuera del repositorio (usar `.env` y/o Docker secrets)
- Todos los contenedores deben reiniciarse automáticamente si fallan
- Prohibido usar: `latest`, `host`, `--link`, `links`, bucles infinitos (`sleep infinity`, `tail - f`, `bash`, `while true`, etc.)
- El dominio debe resolver a tu máquina local: `login.42.fr`


 MAS COSAS:
- Los Dockerfiles debe llamarse en tu docker-compose.yml por tu Makefile

-> leer sobre como trabaja daemons y si es buena idea usarlos !!


-> leer sobre PID 1 y buenas prácticas de Dockerfiles 

- En tu database WordPress tiene que haber dos usuarios: uno de ellos ha de ser el administrador, su username no puede contener 'admin', 'Admin', 'administrator, o 'Administrator'

-> tus volumenes estarán disponibles en la carpeta /home/login/data de la host machine que use Docker. Tienes que reemplazar el login por el tuyo.

- para simplificar el proceso, debes configurar tu domain name to point a tu local IP address
- Este domain name debe ser login.42.fr. usa tu propio login. amacarul.42.fr redirigirá a la dirección IP que apunta a la website de amacarul

-> no tiene que haber contraseñas
> se recomienda usar .env file para guardar las variables de entorno y para usar Docker secrets para almacenar infor confidencial

Por razones de seguridad, las credenciales, API keys, passwords, etc. deben guardarse localmente de varias maneras / en varios archivos y deben ser ignorados por git. Las credenciales almacenadas publicamente suponen el suspenso del proyecto.  
Puedes guardar tus variables (como domain name) en un archivo de variables de entorno cono .env.


## Instructions

- Esto hay que hacerlo dentro de una máquina virtual... -> utilizar la VirtualBox
- Cómo hacerlo desde diferentes ordenadores:
  - Cosas que meter en github:
    - Makefile
    - docker-compose.yml
    - Dockerfiles
    - scripts
    - Configuraciones (nginx.conf, www.conf, etc)
  - Cosas que no deben subirse a github:
    - Los volúmenes: /home/login/data -> estos se crean en la máquina virtual, no se guardan en github
    - archivo .env si contene contraseñas -> debe estar en .gitignore
    - certificados TLS generados

- Cada ordenador necesita su propia máquina virtual con Docker instalado. El proyecto es portable (los archivos), pero Docker no se sincroniza entre máquinas.
- En cada ordenador hay que tener:
  - Una VM
  - Docker Engine
  - Docker Compose
  - carpetas de volúmenes:

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

  - contraseñas? certificados TLS??

## Project description
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

      FROM debian:bookworm
      RUN apt update && apt install -y nginx
      COPY ./config/default.conf /etc/nginx/conf.d/
      ENTRYPOINT ["nginx", "-g", "daemon off;"]

**Instrucciones principales de Dockerfile**
| Keyword | Definition |
|---------|------------|
| FROM | Indica a Docker en qué sistema operativo debe ejecutarse tu máquina virtual. Serán `debian:buster?bookworm?` para Debian o `alpine:x:xx` para Linux. |
| RUM | Eejcuta un comando en tu máquina virtual. Equivale a conectarse por SSH y escribir un comando bash. |
| COPY | Copia un archivo. Especificar la ubicación del archivo a copiar desde el directorio que contiene tu Dockerfile y luego especificar dónde se quiere copiar dentro de la máquina virtual.  |
| EXPOSE | Indica los puertos de red específicos en los que se escucha durante la ejecución. No permite que el host acceda a los puertos del contenedor; expone el puerto especificado y lo hace disponible solo para la comunicación entre contenedores.  |
| ENTRYPOINT | Especifica el comando para iniciar el contenedor. |
| CMD | Argumentos por defecto del ENTRYPOINT |

[Palabras clave de Dockerfile](https://www.nicelydev.com/docker/mots-cles-supplementaires-dockerfile#:~:text=Le%20mot%2Dcl%C3%A9%20EXPOSE%20permet,utiliser%20l'option%20%2Dp%20.)

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

 /*En este proyecto, como base de cada imagen, se puede usar:
          - **Debian**: FROM debian:bookworm
          - **Alpine**: FROM alpine:3.18
          - 
          En *Inception* está prohibido usar imágenes prefabricadas como:
          
                FROM nginx:latest
                FROM mariadb:latest
                FROM wordpress:latest*/
  
#### PID 1 y ENTRYPOINT
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
| wordpress | php-fpm |
| nginx | nginx |

**Apagado limpio de contenedores**  
Cuando se ejecuta 

    docker compose stop

Docker:
- Envía `SIGTERM` al PID 1
- Espera unos segundos
- Si no responde, envía `SIGKILL`

Si el proceso está en foreground y gestiona señales correctamente, el contenedor se apaga limpiamente.


### Docker Compose
**Docker Compose** es una herramienta que permite definir y ejecutar varios contenedores a la vez junto con sus redes y sus volúmenes. Se gestiona através de un archivo `docker-compose.yml`, en el que se definen:
- Servicios (qué contenedores hay)
- Redes (cómo se comunican)
- Volúmenes (dónde guardan datos persistentes)
- Variables de entorno
- Dependencias
- Reconstrucciones automáticas
- Puertos expuestos

El Makefile ejecuta el `docker-compose.yml`.  

En el proyecto *Inception* se requieren varios contenedores conectados entre sí:

      Internet -> NGINX -> WORDPRESS -> MARIADB

Compose los levanta todos juntos (ESTO IRÁ EN EL MAKEFILE????):

      docker compose up --build

CREO QUE PARTE DE ESTE PUNTO DEBERÍA IR EN EL "PASO A PASO" , NO EN LA TEORIA...  
**Archivo yml**: es un archivo de configuración utilizado para definir y gestionar múltiples contenedores en un entorno Docker. Permite describir las relaciones, configuraciones y servicios que compondrán una aplicación o conjunto de servicios interconectados.  
Ejemplo simplificado:


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
          inception:


- `services`: se definen los servicios que ejecutarán los contenedores. Servicios que tenemos: `nginx`, `wordpress`, `mariadb`.
  - container_name: asigna un nombre específico al contenedor que se crea a partir de este servicio
  - build: indica la ubicación del Dockerfile y los archivos necesarios para construir la imagen del contenedor
  - image: indica qué imagen debe usarse como base para el servicio que estás definiendo. Si la imagen no se encuentra a nivel local en el sistema docker, la descargará automaticamente (CREO QUE ESTO ES ALGO QUE HAY QUE EVITAR).
  - ports: mapeo de puertos. PUERTO_HOST:PUERTO_CONTENEDOR
  - volumes: creamos un volumen en el host al directorio que especifiquemos en el contenedor. EXPLICAR QUÉ SON LOS VOLUMES...
  - restart: indica cómo debe comportarse el contenedor en caso de que se detenga. Indicamos que tiene que reiniciar.
  - networks: especifica a qué redes tiene que estar conectado el contenedor.
  - red llamada amacarulnet (TIENE QUE LLAMARSE ASÍ?)
  - controlador de red `bridge`: permite a los contenedores comunicarse entre sí en el mismo host


...... -> seguir en: https://github.com/gemartin99/Inception?tab=readme-ov-file#1--descargar-imagen-de-la-maquina-virtual-

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

Si destruyes el contenedor:

      docker compose down
      docker compose up --build

Tus datos siguen ahí. 

#### Docker Volumes vs Bind Mounts
Los contenedores son efímeros: si borras un contenedor, se vorra su filesystem, es decir, se pierden las bases de datos, uploads, etc.  
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

???? ⚠️

#### Docker Network vs Host Network

### Variables de entorno y secretos
Nunca se deben poner contraseñas en el repositorio.
Usar `.env` para:

    ....

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


## Guía paso a paso

### Preparar la Virtual Machine
1. Este proyecto se hace en la VM [VirtualBox de Oracle](https://www.softonic.com/descargar/virtualbox/windows/post-descarga?dt=internalDownload)
   -> SE GUARDA EN EL SGOINFREE??
3. Instalar [Debian](https://www.debian.org/download.es.html)
   - Debian en la VM no es lo mismo que Debian en los contenedores; dentro de cada servicio podemos elegir entre debian o alpine, lo que es independiente del SO de la VM)
   - La **ISO Debian** es un archivo de imagen de disco que contiene todo el sistema de instalación del sistema operativo **Debian GNU/Linux**. Una ISO es un archivo que representa el contenido de un CD/DVD; en lugar de grabarlo en un disco físico, se puede montar en una VM como si fuera un disco real.
   - ¿Qué hace la ISO en la VM?
     - Arranca la VD desde la ISO, igual que si arrancaras un PC desde un DVD
     - Inicia el instalador de Debian, que te guía para instalar el SO dentro del disco virtual de la VM
     - Permite particionarl el disco virtual, seleccionar el entorno de escritorio, instalar paquetes básicos, configurar red, usuarios, etc
4. Crear la VM en VirtualBox:
   - Abre VirtualBox -> clic en **Nueva**
     - Name: inception
     - Folder: sgoinfre (??)
     - ISO Image: --
     - OS: Linux
     - OS Distribution: Debian
     - OS Version: Debian (64-bit)
     - Memoria RAM: 2048 minimo, 4096 recomendado
     - Number of CPU: 2 por qué??

  - Ajustes recomendados antes de arrancar la VM: **Configuración**
    - Sistema -> Placa Base:
      - Orden de arranque: dejar `Optical` arriba (para instalar desde ISO)
      - Chipset: Default
    - Sistema -> Procesador:
      - CPUS: 2 (si tu equipo tiene >= 4 cores, pon 2 o 4)
      - Enable PAE/NX, qué hace esto??
    - Pantalla -> Video Memory: 16-64MB (no crítico)
    - Almacenamiento:
      - Controlador: SATA, hacer click en el icono del CD y selecciona **elegir un archivo de disco óptico virtual** y apunta a la ISO de Debian que necesitas descargar. Tengo que tener el .vdi como Hard Diskj y el debian como optical disk
    - Red:
      - Adaptador 1: Bridged Adapter (conecta la VM a la misma red que tu host; así obtendrá IP en la LAN) (QUEREMOS QUE PASE ESO???)
    - Carpetas compartidas (opcional) -> lo configuramos más adelante
4. Arrancar la VM e instalar Debian:
   - Inicia la VM (Start)
   - Sigue el instalador de Debian:
     - Seleccionar idioma, zona horaria Europe/Spain, teclado
     - Participado: Guided - use entire disk
     - Hostname: debian, inception ... -> es para identificar la máquina dentro de la red local -> debian-inception
     - Domain name: `login.42.fr` no??
     - Root password: blablapassword
     - Usuario y contraseña: Crea un usuario con login de 42 -> amacarul, passuser
     - Particionado: guided - use entire disk -> el instalador se crea automaticamente el en disco virtual inception.vdi -> /swap
     - Instala el sistema base y el paquete SSH server si quieres acceder por SHH -> Sí -> permite conectarte a la vm desde tu host usando `ssh`, facilita trabajar en la vm sin abrir interfaz gráfica todo el tiempo.
     - NO SELECCIONAR LO DE GNOME! ESO ES LA INTERFAZ GRÁFICA, NO LA QUIERO
   - No instalar software adicional innecesario, se pueden añadir herramientas luego
   - Finaliza y reinicia.

METER ESTO EN SUBAPARTADO DENTRO DE PREPARAR LA MÁQUINA VIRTUAL, NO SE SI ES MEJOR UNA TABLA O QUÉ

| Más cosas de la VM |
|-------------------|
|**Cambiar de modo gráfico a modo texto**: desactivar completamente el modo gráfico en Debian (arrancar siempre en terminal): sudo systemctl stop gmd (si usas GNOME); para deshabilitarlo permanentemente: sudo systemctl set-default multi-user.target (multi-user.target = modo servidor (sin GUI)); y reiniciar: sudo reboot |
|**Conectarse a la VM desde host con SSH**: Arrancar la VM; Averiguar la IP de la VM -> dentro de la VM (en terminal) ejecutar `ip a`; Buscar la interfaz que esté conectada a la red, usualmente `enp0s3` o `eth0` y apunta la IP que aparece después de `inet` -> esa es la IP que usarás para SSH; En tu host: `ssh <login>@<IP_VM>`; Primer acceso: la primera vez te pedirá confirmar la huella digital del host -> yes; luego te pedirá contraseña del usuario de la VM |
| **Cambiar de usuario a root:** su - ; y ejecutar lo que quiera. No he hecho sudo, no se si hace falta |
| **Cambiar de root a usuario:** su - login |
| **Reiniciar máquina virtual**: reboot |
     
#### Instalar Docker y Docker Compose
5. Dentro de Debian, se instala Docker, Docker Compose, Make, Git
  Si añadiste usuario al instalar, deberias poder usar sudo. Si no, usa root para ejecutar los comandos y crea el usuario apropiado.
  - Instalar Docker y Docker compose:

        #Instalar Docker (paquete docjer.io) y plugin docker-compose
        sudo apt install -y docker.io docker-compose

        #Habilitar y arrancar el servicio Docker
        sudo systemctl enable --now docker

        #Añadir tu usuario al grupo docker
        sudo usermod -aG docker <login>

        #Nota: es necesario hacer logout/login o reiniciar la VM para aplicar el grupo docker

        #Comprobar que has añadido el usuario a docker correctamente
        groups <login>

        #build-essential incluye make, gcc y otras herramientas de compilación importantes
        sudo apt install build-essential

Después de hacer usermod, sal de la sesión y vuelve a entrar.  
Verifica:

    docker --version
    docker compose version

#### Cómo compartir carpetas entre la VM y el host
6. Compartir carpeta que está en host (local) en la Virtual Machine:
   - Vm -> Settings -> Shared Folders -> Añadir carpeta
   - Folder path: ubicación en local
   - Folder name: nombre que le vamos a dar
   - Mount point: /home/amacarul/inception
   - Marcar auto-mont y make permanent
   - Luego, en terminal de la VM:


             sudo mkdir -p /home/amacarul/inception
             sudo mount -t vboxsf -o uid=$(id -u),gid=$(id -g) inception /home/amacarul/inception
     
   - Tu user tiene que estar en el grupo vboxsf ->
   
           sudo groupadd vboxsf
           sudo usermod -aG vboxsf $USER

   
   - Y así ya te aparece en esa nueva carpeta lo que hay en tu carpeta host
   - Ahora, cualquier cambio dentro de la vm se refleja directamente en el host
  
  - Insertar CD de Guest Additions :
      - En la ventana de la VM -> menú superior -> Devices -> Insert Guest Aditions CD image
      - En terminal de la VM:

              sudo apt update
              sudo apt install -y build-essential dkms linux-headers-$(uname -r)
    
      - Montar el disco:
   
              sudo mkdir -p /mnt/cdrom
              sudo mount /dev/cdrom /mnt/cdrom

      - Comprobar:
   
            ls /mnt/cdrom

        Debería estar `VBoxLinuxAdditons.run`


      - Ejecutar el instalador
   
            sudo /mnt/cdrom/VBoxLinuxAdditions.run

      - Reiniciar VM
   
              sudo reboot

      - Comprobación tras reiniciar:
   
            lsmod | gep vbox

        Si aparece `vbpxsf` las shared folders deberían funcionar.

### Crear estructura del proyecto
  7. Crear estructura del proyecto en local
   
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

QUÉ CARPETAS HAY QUE SUBIR, CUÁLES NO???
Archivos que no han de subirse a github, ni compartirse:
- `.env`: contiene contraseñas y datos sensibles
     
8. Crea las carpetas del host que luego montarás como volúmenes / estructura de directorios

       mkdir -p /home/<login>/data/wordpress
       mkdir -p /home/<login>/data/mariadb

       #Ajustar permisos para que Docker pueda escribir
       sudo chown -R <login>:<login> /home/<login>/data

        
### Archivo .env
El archivo `.env` contiene las variables de entorno. No es código, no se ejecuta, solo define valores.  
Docker y docker compose leen este archivo y lo cargan como variables de entorno.  
Esas variables luego pueden usarse en `docker-compose.yml`, dentro de los containers, en scripts y en configuraciones.  
¿Por qué se usa `.env` en Inception?  
- Porque no hay qu hardcodear contraseñas
- La configuración tiene que ser dinámica
- Para poder cambiar valores sin tocar el código.
- ESTE ARCHIVO NO HA DE SUBIRSE A NINGÚN SITIO!!

    DOMAIN_NAME=amacarul.42.fr #dominio que usará NGINX para TLS y wordpress

    MYSQL_HOSTNAME=mariadb
    MYSQL_DATABASE=database
    MYSQL_USER=amacarul
    MYSQL_PASSWORD=passusersql
    MYSQL_ROOT_USER=root
    MYSQL_ROOT_PASSWORD=blablapasswordsql
    
    WORDPRESS_TITLE=myWebsite
    WORDPRESS_ADMIN_USER=boss
    WORDPRESS_ADMIN_PASSWORD=blablapasswordpress
    WORDPRESS_ADMIN_EMAIL=boss@inception.fr
    WORDPRESS_USER=user1
    WORDPRESS_USER_EMAIL=user1@inception.fr
    WORDPRESS_USER_PASSWORD=passuserwordpress

Hay cosas de estas que tienen que ir a secrets, creo... las contraseñas, por ejemplo, no deberian estar como variables de entorno, no?

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

## Configuración de la red
- Creación de red Docker
- Registros en docker-compose

## Configuración de volúmenes
- Mapeo de `/home/<login>/data/...
- Permisos y usuario correcto

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
- Revisión de logs

## Limpieza y validación final


## Resources
[Forstman1 repo](https://github.com/Forstman1/inception-42)  
[gemartin99 repo](https://github.com/gemartin99/Inception?tab=readme-ov-file)  
[Grademe tutorial](https://tuto.grademe.fr/inception/)  
[dockerdocs](https://docs.docker.com/)  
[dockerdocs - Building best practices](https://docs.docker.com/build/building/best-practices/)  
[Comandos del docker compose](https://iesgn.github.io/curso_docker_2021/sesion5/comando.html) 
[Comandos de docker](https://kinsta.com/es/blog/comandos-docker/)
