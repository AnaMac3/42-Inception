# 42-Inception
42 Common Core Inception 
- de qué va??
- System administration
- Docker technology

## Table of Contents
- [How to use](#how-to-use)
- [Docker](#docker)
- [Paso a paso](#paso-a-paso)
  - [Virtual Machine](#virtual-machine)
- [Fixed-point numbers](#fixed-point-numbers)
- [More info](#more-info)

----------------------------------------

## How to use

- Esto hay que hacerlo dentro de una máquina virtual... -> utilizar la VM de 42
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

  El repositorio debe contener:

        inception/
        │
        ├── Makefile
        ├── .gitignore
        ├── README.md (opcional)
        └── srcs/
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

- Cada ordenador necesita su propia máquina virtual con Docker instalado. El proyecto es portable (los archivos), pero Docker no se sincroniza entre máquinas.
- En cada ordenador hay que tener:
  - Una VM
  - Docker Engine
  - Docker Compose
  - carpetas de volúmenes:

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

## Subject  
- Hay que hacer el proyecto en una máquina virtual -> Docker Compose
- cada imagen de Docker tiene que tener el mismo nombre que su servicio correspondiente
- Cada servicio debe correr en un dedicater container
- Los contenedores deben construirse desde la penultima versión estable de Alpine o Debian ???
- Tienes que escribir tu propio Dockerfiles, uno por servicio. Los Dockerfiles debe llamarse en tu docker-compose.yml por tu Makefile
- Esto significa que debes construir las iamgenes Docker para el proyecto por tu cuenta. Está prohibido subir imagenes de Docker que ya estén hechas de servicios como DockerHub (Alpine/Debian se excluyen de esta norma) -> Cómo se comprueba eso en la evaluación?
- Hay que set up:
  - Un contenedor de Docker que contenga NGINX con TLSv1.2 o TLSv1.3 solo
  - Un contenedor Docker que contenga WordPress con php-fpm (debe ser instalado y configurado) solo, sin nginx
  - Un contenedor Docker que contenga solo MariaDB, sin nginx
  - Un volumen que contenga tu database WordPress
  - Un segundo volumen que contenga tus archivos de website de WordPress
  - un docker-network que establezca la conexión entre los contenedores
- Tus contenedores deben reiniciarse automaticamente en caso de crash

-> leer sobre como trabaja daemons y si es buena idea usarlos !!
-> está prohibido usar host o --link o links. The network line tiene que estar presente en tu docker-compose.yml file. Tus containers no deben iniciarse con un comando que corra en un bucle infinito. Esto se aplica a todo comando que se use como entrypoint, o usado en scripts de entrypoint. Está prohibido: tail -f, bash, sleep infinity, while true

-> leer sobre PID 1 y buenas prácticas de Dockerfiles

- En tu database WordPress tiene que haber dos usuarios: uno de ellos ha de ser el administrador, su username no puede contener 'admin', 'Admin', 'administrator, o 'Administrator'

-> tus volumenes estarán disponibles en la carpeta /home/login/data de la host machine que use Docker. Tienes que reemplazar el login por el tuyo.

- para simplificar el proceso, debes configurar tu domain name to point a tu local IP address
- Este domain name debe ser login.42.fr. usa tu propio login. amacarul.42.fr redirigirá a la dirección IP que apunta a la website de amacarul

-> the latest tag is prohibited ??
-> no tiene que haber contraseñas
> hay que usar obligatoriamente environment variables
> se recomienda usar .env file para guardar las variables de entorno y para usar Docker secrets para almacenar infor confidencial
> tu contenedor NGINX debe ser el unico entry poiny a tu infraestructura, accesible solo via port 443, usando TLSv1.2 o TLSv1.3


Ejemplo de diagrama del resultado esperado: 
- Recuadro grande llamado COmputer HOST que alberga Docker network y DB y WordPress
- Recuadro de Docker network, contiene:
  - Container DB, que conecta con la DB que está afuera, y el Container WordPress+PHP (que está dentro del Docker network) a través de 3306 y con el WordPress que está fuera
  - Container NGINX que conecta con Container WordPress+PHP mediante 9000 y con el WordPress que está fuera
- Fuera del COmputer HOST está www. www conecta con Container NGINX  a través de 443
-> 443, 3306, 9000: son puertos
-> Container DB, Container WordPress+PHP y Container NGINX son Image docker
-> DB y WordPress son Volume (?)

Ejemplo de la estructura del directorio (`ls -alR` -> muestra archivos, -a incluye ocultos, -l muestra detalles, -R recursivo (subdirectorios))

Por razones de seguridad, las credenciales, API keys, passwords, etc. deben guardarse localmente de varias maneras / en varios archivos y deben ser ignorados por git. Las credenciales almacenadas publicamente suponen el suspenso del proyecto.  
Puedes guardar tus variables (como domain name) en un archivo de variables de entorno cono .env.

## Docker

**Docker** es una herramienta que permite ejecutar aplicaciones en **contenedores** / que permite empaquetar una aplicación y sus dependencias en un contenedor aislado.  
Un **contenedor** es una especie de mini-sistema aislado que ejecuta una aplicación con solo las **dependencias necesarias**. No es una máquina virtual completa: es más ligero y rápido.
Problemas que resuelve Docker:
- Dependencias que son incompatibles con tu versión de software
- Dependencias en versiones diferentes
- Dependencias que no existen en tu sistema operativo
- Dependencias que fallan al iniciarse...
Ventajas de Docker frente a las máquinas virtuales:
- Capacidad de modelar cada contendor como una imagen que se puede almacenar localmente.
- No tiene kernel/núcleo (sistema operativo, gráficos, red...); solo tiene la aplicación y sus dependencias.

### Docker Compose
**Docker Compose** es una herramienta que te permite levantar varios contenedores a la vez junto con sus redes y sus volúmenes / es una herramienta desarrollada para definir y compartir aplicaciones multicontenedor.  
Con Compose se puede crear un archivo YAML para definir servicios e iniciar y detener todo con un solo comando.  
En vez de ejecutar muchos comandos `docker run`, describimos todo en un archivo:

      docker-compose.yml

## Contenedores, Servicios e Imágenes
- **Cada servicio = un contenedor**: el proyecto pide tres servicios principales:
| Servicio | Contenedor | Qué contiene |
|----------|------------|--------------|
| NGINX | `nginx` | Servidor web con TLS |
| WordPress+PHP-FPM | `wordpress`| PHP + WordPress, sin nignx |
| MariaDB | `mariadb` | Database |

Una imagen de Docker es una carpeta: contiene el Dockerfile en la raíz y puede contener otros archivos que se pueden copiar directamente en tu máquina virtual.

- **Cada contenedor debe tener su propio Dockerfile**:
  - **Dockerfile**: archivo principal de tus imágenes Docker.
  - Ejemplo de estructura:

        srcs/
          docker-compose.yml
          requeriments/
            nginx/
              Dockerfile
              conf/
            wordpress/
              Dockerfile
            mariadb/
              Dockerfile

  - Palabras clave de Dockerfile
| Keyword | Definition |
|---------|------------|
| FROM | Indica a Docker en qué sistema operativo debe ejecutarse tu máquina virtual. Serán `debian:buster?bookworm?` para Debian o `alpine:x:xx` para Linux. |
| RUM | Eejcuta un comando en tu máquina virtual. Equivale a conectarse por SSH y escribir un comando bash. |
| COPY | Copia un archivo. Especificar la ubicación del archivo a copiar desde el directorio que contiene tu Dockerfile y luego especificar dónde se quiere copiar dentro de la máquina virtual.  |
| EXPOSE | Indica los puertos de red específicos en los que se escucha durante la ejecución. No permite que el host acceda a los puertos del contenedor; expone el puerto especificado y lo hace disponible solo para la comunicación entre contenedores.  |
| ENTRYPOINT | Especifica el comando para iniciar el contenedor. |

[Palabras clave de Dockerfile](https://www.nicelydev.com/docker/mots-cles-supplementaires-dockerfile#:~:text=Le%20mot%2Dcl%C3%A9%20EXPOSE%20permet,utiliser%20l'option%20%2Dp%20.)

## Base de cada imagen: Alpine o Debian
Se puede usar:
- **Debian**: FROM debian:bookworm
- **Alpine**: FROM alpine:3.18

INVESTIGAR CUÁL ME CONVIENE Y POR QUÉ

No se pueden usar imágenes hechas, excepto Alpine/Debian. Es decir, no se puede hacer:

      FROM wordpress:latest
      FROM mariadb:latest

  Ejemplo aceptado:

      FROM debian:bookworm
      RUN apt install mariadb-server

  **¿Cómo se comprueba esto?**: 
  - Revisar Dockerfiles
  - Revisar docker-compose.yml
  - Ver si el contenedor realmente ejecuta la app instalada a mano
  - Ver que no haga `docker pull wordpress` o `docker pull mariadb`.

## Docker network
Docker crea una red interna que conecta tus contenedores.   
Debe ser declarada explícitamente (yml):

      networks:
        inception:

Esto permite que los contenedores se busquen por nombre:
- NGINX se conecta a PHP -> puerto 9000
- PHP conecta con MariaDB -> puerto 3306

## Volúmenes

El proyecto pide dos volúmenes:
- `mariadb`: contiene base de datos
- `wordpress`: contiene archivos de WordPress

Deben estar montados en:

      /hone/<login>/data/wordpress
      /home/<login>/data/mariadb

## TLS (HTTPS)
Solo se permite TLSv1.2 y TLSv1.3.  
NGINX debe exponer solo el puerto 443.


## Paso a paso
### Virtual Machine: instalación y configuración
1. Descargar [VirtualBox de Oracle](https://www.softonic.com/descargar/virtualbox/windows/post-descarga?dt=internalDownload)
2. Crear la VM en VirtualBox:
   - Abre VirtualBox -> clic en **Nueva**
     - Name: inception
     - Folder: 42-Inception
     - ISO Image: ?
     - OS: Linux
     - OS Distribution: Debian
     - OS Version: Debian (64-bit)
     - Memoria RAM: 2048 minimo, 4096 recomendado
     - Number oc CPU: 1??
     - Disk Size: 20 GB minimo
  - Ajustes recomendados antes de arrancar la VM: **Configuración**
    - Sistema -> Placa Base:
      - Orden de arranque: dejar `Optical` arriba (para instalar desde ISO)
      - Chipset: Default
    - Sistema -> Procesador:
      - CPUS: 2 (si tu equipo tiene >= 4 cores, pon 2 o 4)
      - Enable PAE/NX (no me aparece eso)
    - Pantalla -> Video Memory: 16-64MB (no crítico)
    - Almacenamiento:
      - Controlador: IDE o SATA, hacer click en el icono del CD y selecciona **elegir un archivo de disco óptico virtual** y apunta a la ISO de Debian que necesitas descargar
    - Red:
      - Adaptador 1: Bridged Adapter (conecta la VM a la misma red que tu host; así obtendrá IP en la LAN) (QUEREMOS QUE PASE ESO???)
    - Carpetas compartidas (opcional): puedes configurar una carpeta compartida si quieres transferir archivos desde tu host sin usar scp/git.

3. Instalar Debian (Debian en la VM no es lo mismo que Debian en los contenedores; dentro de cada servicio podemos elegir entre debian o alpine, lo que es independiente del SO de la VM) -> https://www.debian.org/download.es.html
4. Arrancar la VM e instalar Debian:
   - Inicia la VM (Start)
   - Sigue el instalador de Debian:
     - Seleccionar idioma -> zona horaria Europe/Spain
     - Participado: Guided - use entire disk
     - Hostname: debian, inception ... -> es para identificar la máquina dentro de la red local -> debian-inception
     - Domain name: campo opcional en el SO debian que se usa en redes corporativas... dejarlo vacio o poner local
     - Root password: blablapassword
     - Usuario y contraseña: Crea un usuario con login de 42 -> amacarul, passuser
     - Instala el sistema base y el paquete SSH server si quieres acceder por SHH (esto qué era???)
     - No instalar software adicional innecesario, se pueden añadir herramientas luego
    - Finaliza y reinicia. 

### Instalar Docker y Docker Compose
6. Dentro de Debian, se instala Docker, Docker Compose, Make, Git
   - Abrir terminal dentro de debian VM y ejecutar:

         #Actualizar sistema
         sudo apt update && sudo apt upgrade -y

         #Instalar utilidades básicas
         sudo apt install -y sudo curl wget git make vim apt-transport-https ca-certificates gnupg lsb-release

  Si añadiste usuario al instalar, deberias poder usar sudo. Si no, usa root para ejecutar los comandos y crea el usuario apropiado.
  - Instalar Docker y Docker compose:

        #Instalar Docker (paquete docjer.io) y plugin docker-compose
        sudo apt install -y docker.io docker-compose-plugin

        #Habilitar y arrancar el servicio Docker
        sudo systemctl enable --now docker

        #Añadir tu usuario al grupo docker
        sudo usermod -aG docker <login>

        #Nota: es necesario hacer logout/login o reiniciar la VM para aplicar el grupo docker

Después de hacer usermod, sal de la sesión y vuelve a entrar.  
Verifica:

    docker --version
    docker compose version


### Configurar carpetas de datos (volúmenes enlazados)

## More info
Other repos &rarr; [HERE](https://github.com/Forstman1/inception-42)  
Grademe tutorial &arr; [HERE](https://tuto.grademe.fr/inception/)
