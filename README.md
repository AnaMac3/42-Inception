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
  - [Docker image and Dockerfile](#docker-image-and-dockerfile)
  - [Docker Compose](#docker-compose)
  - [Docker Network - cómo se comunican los contenedores](docker-network-cómo-se-comunican-los-contenedores)
  - [Volúmenes - persistencia de datos](#volúmenes---persistencia-de-datos)
  - [Variables de entorno y secretos](variables-de-entorno-y-secretos)
  - [NGINX, WordPress and MariaDB](#nginx-wordpress-and-mariadb)
  - [Cómo se relacionan todos los conceptos](cómo-se-relacionan-todos-los-conceptos) 
- [Guía paso a paso](#guía-paso-a-paso)
  - [Preparar la Virtual Machine](#preparar-la-virtual-machine)
    - [Instalar Docker y Docker Compose](#instalar-docker-y-docker-compose)
    - [Cómo compartir carpetas entre la VM y el host](cómo-compartir-carpetas-entre-la-VM-y-el-host)
  - [Crear estructura del proyecto](#crear-estructura-del-proyecto)
  - [Archivo .env](#archivo-.env)
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
### Docker: concepto y propósito
**Docker** es una herramienta que permite ejecutar aplicaciones en **contenedores**.  

Un **contenedor** es un entorno aislado y reproducible, es una especie de mini-sistema aislado que ejecuta una aplicación con solo las **dependencias necesarias**. No es una máquina virtual completa: es más ligero y rápido.  

#### Contenedor vs Máquina Virtual
| Virtual Machine | Contenedor Docker |
|-----------------|-----------|
| Incluye un sistema operativo completo con su kernel | Comparte el kernel del host |
| Pesada y lenta en arrancar | Muy ligero y arranca en milisegundos |
| Cada VM consume mucha RAM/CPU | Cada contenedor usa solo lo imprescindible |
| Diseñada para aislamiento total | Diseñado para despliegue rápido ; aislamiento de procesos y red, pero comparte kernel |

**Problemas que resuelve Docker:**
- Dependencias que son incompatibles con tu versión de software
- Dependencias en versiones diferentes
- Dependencias incompatibles entre proyectos
- Necesidad de reproducir entornos exactamente iguales
- Aislamiento de bases de datos, servidores web, etc.

#### Qué contiene un contenedor
- La aplicación (p.ej. WordPress, NGINX, MariaDB...)
- Sus dependencias (librerías, binarios
- Archivos de configuración
- El entorno de ejecución mínimo necesario
Un contenedor es la **instancia ejecutable de una imagen Docker**, no un sistema operativo ni una máquina virtual.

### Docker Images and Dockerfile
#### Imágenes
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
  
#### PID1 y ENTRYPOINT
- En Linux, **PID1** es el primer proceso que se ejecuta; gestiona señales y zombies.
- En Docker, el proceso definido como ENTRYPOINT se convierte en PID1.
- Algunos programas necesitan ajustes para funcionar correctamente como PID1, lo que causa:
  - Contenedores que no se apagan correctamente
  - Procesos zombie
  - Comportamientos inesperados
  - Contenedores que se cierran solos o crashean
  Por eso está prohibido en este ejercicio usar bucles infinitos. NGINX sí está preparado para ejecutarse directamente como PID1, por eso se usa `daemon off`. -> YA VERÉ QUÉ PASA CON ESTO



 /*En este proyecto, como base de cada imagen, se puede usar:
          - **Debian**: FROM debian:bookworm
          - **Alpine**: FROM alpine:3.18
          - 
          En *Inception* está prohibido usar imágenes prefabricadas como:
          
                FROM nginx:latest
                FROM mariadb:latest
                FROM wordpress:latest*/

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

#### WordPress
**WordPress** es un CMS (Content Management System) escrito en PHP. Permite crear con facilidad:
- páginas
- blogs
- usuarios
- plugins
- temas
En este proyecto debe ejecutarse con PHP-FPM (no con Apache) porque:
- NGINX no ejecuta PHP directamente
- PHP-FPM gestiona procesos PHO como un servicio separado

El flujo es:

Navegador -> NGINX (443) -> PHP-FPM (9000) -> WordPress -> MariaDB (3306)

#### MariaDB
**MariaDB** es un sistema de bases de datos SQL (alternativa a MySQL). WordPress lo usa para guardar:
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
    - Carpetas compartidas (opcional): puedes configurar una carpeta compartida si quieres transferir archivos desde tu host sin usar scp/git. ??¿?¿?
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

        
## Archivo .env
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
      MYSQL_DATABASE= #nombre de la db que mariadb va a crear
      MYSQL_USER=amacarul
      MYSQL_PASSWORD=passuser
      MYSQL_ROOT_USER=root
      MYSQL_ROOT_PASSWORD=blablapassword
      
      WORDPRESS_TITLE=Inception #titulo del sitio wordpress
      WORDPRESS_ADMIN_USER= #creo que no puede ser admin
      WORDPRESS_ADMIN_PASSWORD=
      WORDPRESS_ADMIN_EMAIL= #creo que no puede ser admin
      WORDPRESS_USER=
      WORDPRESS_USER_EMAIL=
      WORDPRESS_USER_PASSWORD=

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

## Configuración del dominio
- `/etc/hosts`-> `login.42.fr`

## Pruebas del sistema
- Comprobación de que todos los contenedores arrancan
- Conexión entre servicios
- Acceso HTTPS
- Persistencia de datos
- Revisión de logs

## Limpieza y validación final


## Resources
[Forstman1 repo](https://github.com/Forstman1/inception-42)  
[gemartin99 repo](https://github.com/gemartin99/Inception?tab=readme-ov-file)  
[Grademe tutorial](https://tuto.grademe.fr/inception/)  
[dockerdocs - Building best practices](https://docs.docker.com/build/building/best-practices/)  
