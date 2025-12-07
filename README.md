# 42-Inception
42 Common Core Inception 
- de qué va??
- System administration
- Docker technology

## Table of Contents
- [How to use](#how-to-use)
- [Teoría](#teoría)
  - [Docker](#docker)
- [Paso a paso](#paso-a-paso)
  - [Virtual Machine: instalación y creación de una VM](#virtual-machine-instalación-y-creación-de-una-vm)
  - [Instalar Docker y Docker Compose](#instalar-docker-y-docker-compose)
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


       

- Cada ordenador necesita su propia máquina virtual con Docker instalado. El proyecto es portable (los archivos), pero Docker no se sincroniza entre máquinas.
- En cada ordenador hay que tener:
  - Una VM
  - Docker Engine
  - Docker Compose
  - carpetas de volúmenes:

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

## Resumen del Subject / Introducción
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


## Base de cada imagen: Alpine o Debian
Se puede usar:
- **Debian**: FROM debian:bookworm
- **Alpine**: FROM alpine:3.18


## Teoría - Conceptos fundamentales
### Docker
**Docker** es una herramienta que permite ejecutar aplicaciones en **contenedores**. 

Un **contenedor** es un entorno aislado y reproducible, es una especie de mini-sistema aislado que ejecuta una aplicación con solo las **dependencias necesarias**. No es una máquina virtual completa: es más ligero y rápido.  

**Máquina Virtual vs Contenedor**
| Virtual Machine | Contenedor Docker |
|-----------------|-----------|
| Incluye un sistema operativo completo con su kernel | Comparte el kernel del host |
| Pesada y lenta en arrancar | Muy ligero y arranca en milisegundos |
| Cada VM consume mucha RAM/CPU | Cada contenedor usa solo lo imprescindible |
| Diseñada para aislamiento total | Diseñado para despliegue rápido |

Problemas que resuelve Docker:
- Dependencias que son incompatibles con tu versión de software
- Dependencias en versiones diferentes
- Dependencias incompatibles entre proyectos
- Necesidad de reproducir entornos exactamente iguales
- Aislamiento de bases de datos, servidores web, etc.

Un contenedor, tiene:
- La aplicación (p.ej. WordPress, NGINX, MariaDB)
- Sus dependencias
- Binarios necesarios
- Archivos de configuración
Un contenedor es la ejecución **de una imagen Docker**

### Imagen Docker
Una **imagen** es una *plantilla* de un sistema con:
- Ficheros
- Dependencias
- Configuraciones
- Comandos de arranque

Una **imagen**:
- No se ejecuta
- No cambia
- No tiene estado
Un **contenedor**:
- Es una instancia de la imagen
- Se ejecuta
- Puede modificarse durante su uso
- Puede morir y recrearse

Una imagen se crea con un **Dockerfile** (archivo que define cómo construir una imagen). 

Ejemplo de Dockerfile que crea una imagen que al ejecutarse arranca NGINX:

      FROM debian:bookworm
      RUN apt update && apt install -y nginx
      COPY ./config/default.conf /etc/nginx/conf.d/
      ENTRYPOINT ["nginx", "-g", "daemon off;"]

Palabras clave de Dockerfile
 
| Keyword | Definition |
|---------|------------|
| FROM | Indica a Docker en qué sistema operativo debe ejecutarse tu máquina virtual. Serán `debian:buster?bookworm?` para Debian o `alpine:x:xx` para Linux. |
| RUM | Eejcuta un comando en tu máquina virtual. Equivale a conectarse por SSH y escribir un comando bash. |
| COPY | Copia un archivo. Especificar la ubicación del archivo a copiar desde el directorio que contiene tu Dockerfile y luego especificar dónde se quiere copiar dentro de la máquina virtual.  |
| EXPOSE | Indica los puertos de red específicos en los que se escucha durante la ejecución. No permite que el host acceda a los puertos del contenedor; expone el puerto especificado y lo hace disponible solo para la comunicación entre contenedores.  |
| ENTRYPOINT | Especifica el comando para iniciar el contenedor. |
| CMD | Argumentos por defecto del ENTRYPOINT |

En *Inception* está prohibido usar imágenes prefabricadas como:

      FROM nginx:latest
      FROM mariadb:latest
      FROM wordpress:latest

[Palabras clave de Dockerfile](https://www.nicelydev.com/docker/mots-cles-supplementaires-dockerfile#:~:text=Le%20mot%2Dcl%C3%A9%20EXPOSE%20permet,utiliser%20l'option%20%2Dp%20.)

**Imagen -> contenedor en ejecución -> corre un único servicio**.
En este proyecto se piden tres servicios principales:
  
| Servicio | Contenedor | Qué contiene |
|----------|------------|--------------|
| NGINX | `nginx` | Servidor web con TLS |
| WordPress+PHP-FPM | `wordpress`| PHP + WordPress, sin nignx |
| MariaDB | `mariadb` | Database |

Una imagen de Docker es una carpeta: contiene el Dockerfile en la raíz y puede contener otros archivos que se pueden copiar directamente en tu máquina virtual. ES NECESARIO PONER ESTO AQUÍ??


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

Compose los levanta todos juntos:

      docker compose up --build

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

????

### Volúmenes - persistencia de datos
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

### Cómo se relacionan todos los conceptos
1. **Dockerfiles** construyen imágenes para cada servicio
2. **Compose** define cómo se conectan: redes, volúmenes, puertos
3. **Compose levanta los contenedores** en el orden necesario
4. **NGINX** recibe tráfico HTTPS y lo pasa a PHP-FPM (WordPress)
5. **WordPress** consulta la base de datos en MariaDB
6. **Los volúmenes** garantizan que WordPress y MariaDB persistan datos
7. **Las varaibles de entorno** configuran credenciales y dominio
8. El sistema funciona como una infraestructura real

## Guía paso a paso
### Preparar la Virtual Machine
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
      - Enable PAE/NX
    - Pantalla -> Video Memory: 16-64MB (no crítico)
    - Almacenamiento:
      - Controlador: SATA, hacer click en el icono del CD y selecciona **elegir un archivo de disco óptico virtual** y apunta a la ISO de Debian que necesitas descargar. Tengo que tener el .vdi como Hard Diskj y el debian como optical disk
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
     - Domain name: `login.42.fr` no??
     - Root password: blablapassword
     - Usuario y contraseña: Crea un usuario con login de 42 -> amacarul, passuser
     - Particionado: guided - use entire disk -> el instalador se crea automaticamente el en disco virtual inception.vdi -> /swap
     - Instala el sistema base y el paquete SSH server si quieres acceder por SHH -> Sí -> permite conectarte a la vm desde tu host usando `ssh`, facilita trabajar en la vm sin abrir interfaz gráfica todo el tiempo. Acceder a la máquina virtual via SSH
       - Arrancar la VM
       - Averiguar la IP de la VM -> dentro de la VM (en terminal) ejecutar `ip a`
       - Buscar la interfaz que esté conectada a la red, usualmente `enp0s3` o `eth0` y apunta la IP que aparece después de `inet` -> esa es la IP que usarás para SSH
       - En tu host:
      
             ssh <login>@<IP_VM>
  
       - Primer acceso: la primera vez te pedirá confirmar la huella digital del host -> yes; luego te pedirá contraseña del usuario de la VM
   - No instalar software adicional innecesario, se pueden añadir herramientas lueg
   - Finaliza y reinicia. 

5. Dentro de Debian, se instala Docker, Docker Compose, Make, Git
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

6. Crea las carpetas del host que luego montarás como volúmenes / estructura de directorios

       mkdir -p /home/<login>/data/wordpress
       mkdir -p /home/<login>/data/mariadb

       #Ajustar permisos para que Docker pueda escribir
       sudo chown -R <login>:<login> /home/<login>/data

   ESTAS CARPETAS HAY QUE CREARLAS DÓNDE? OSEA QUIERO QUE SEAN ACCESIBLES DESDE EL HOST, TAMBIÉN, NO? SON LAS COSAS QUE HE DE SUBIR AL REPOSITORIO.... Y LA ESTRUCTURA DE DATOS QUE TENGO NO HAY NINGUNA CARPETA DATA
 
8. Red y cómo apuntar el dominio local: Averiguar IP de la VM (si usamos bridged):

       ip a show
       # ó
       hostname -I

   - En tu máquina host añade el /etc/hosts
  
           <IP_VM> <login>.42.fr

   - Con esto, cuando desde tu PC accedas a https://amacarul.42.fr se redigirá a la VM.
  
9. Firewall (recomendable): Si usas `ufw` o `iptables`, abre puerto 443

        sudo apt install -y ufw
        sudo ufw allow OpenSSH
        sudo ufw allow 443/tcp
        sudo ufw enable

## Crear estructura del proyecto
           
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

## Construcción de cada imagen
1. NGINX
   - Dockerfile
   - Configuración TLS
   - Exposición del puerto 443
   - Configuración de fastcgi_pass
   - Scripts necesarios
2. WordPress + PHP-FOM
   - Dockerfile
   - Instalación manual de PHP, PHP-FPM
   - Descarga de WordPress
   - Configuración dinámica con variables de entorno
   - Script de setup
3. MariaDB
   - Dockerfile
   - Instalación de la base de datos
   - Inicialización de usuarios y permisos
   - Configuración persistente del volúmen

## Configuración de la red
- Creación de red Docker
- Registros en docker-compose

## Configuración de volúmenes
- Mapeo de `/home/<login>/data/...
- Permisos y usuario correcto

## COnfiguración del dominio
- `/etc/hosts`-> `login.42.fr`

## Pruebas del sistema
- Comprobación de que todos los contenedores arrancan
- Conexión entre servicios
- Acceso HTTPS
- Persistencia de datos
- Revisión de logs

## Limpieza y validación final


## More info
[Forstman1 repo](https://github.com/Forstman1/inception-42)  
[gemartin99 repo](https://github.com/gemartin99/Inception?tab=readme-ov-file)  
[Grademe tutorial](https://tuto.grademe.fr/inception/)
