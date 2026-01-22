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
  - [Build & Run](#build--run)
  - [Stop & Clean](#stop--clean)
- [Project description](#project-description)
  - [Docker](#docker)
    - [Virtual Machine vs Docker](#virtual-machine-vs-docker)
  - [Docker images and Dockerfile](#docker-images-and-dockerfile)
    - [Docker Images](#docker-images)
      - [Image vs Container](#image-vs-container)
    - [Dockerfile](#dockerfile)
  - [Container lifecycle, ENTRYPOINT and PID 1](#container-lyfecicle-entrypoint-and-pid-1)
  - [Service Architecture](#service-architecture)
    - [Request flow and PHP execution](#request-flow-and-php-execution)
    - [MariaDB](#mariadb)
    - [WordPress](#wordpress)
    - [NGINX](#nginx)
  - [Docker Compose](#docker-compose)
    - [The `docker-compose.yml` file in *Inception*](#the-docker-composeyml-file-in-inception)
  - [Data Persistence](#volúmenes---persistencia-de-datos)
    - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  - [Docker Network](docker-network)
    - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
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
- Prohibido usar: `latest`, `host`, `--link`, `links`, bucles infinitos (`sleep infinity`, `tail - f`, `bash`, `while true`, etc.) ⚠️ CÓMO EVITO USAR ESTO?? -> Creo que esto se evita usar utilizando scripts de espera en los scripts de arranque...?? setup.sh..., porque las instrucciones de dependencia de docker-compose.yml no aseguran que el contenedor del que dependen esté listo, simplemente que haya empezaod...
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
This sections explains ....   

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
This sections explains ....   
NO SÉ SI ESTO PEGA AQUÍ O EN OTRO LUGAR, PERO PARA EXPLICAR EL CÓDIGO, EL PROYECTO ENTERO, EN ORDEN, LO IDEAL SERIA SEGUIR ESTA ESTRUCTURA:
- DOCKER_COMPOSE.YML -> ARQUITECTURA GLOBAL, FLUJO DE ARRANQUE, RELACIÓN ENTRE SERVICIOS
- DOCKERFILES -> QUÉ SE INSTALA, QUÉ SE COPIA... CÓMO SE CONSTRUYE CADA IMAGEN
- SCRIPTS DE ENTRYPOINTS / SETUP -> QUÉ OCURRE CUANDO EL CONTENEDOR ARRANCA, POR QUÉ NO SE HACE TODO EN EL DOCKERFILE, DIFERENCIA ENTRE BUILD TIME Y RUN TIME
- CONFIGURACIONES Y .ENV -> VARIABLES, SEGURIDAD, TLS, COMUNICACIÓN INTERNA ENTRE CONTENEDORES

### Docker and Containers
**Docker** es una herramienta que permite ejecutar aplicaciones en **contenedores**.  
Un **contenedor** es un entorno aislado y reproducible, es una especie de mini-sistema aislado que ejecuta una aplicación con solo las **dependencias necesarias**. No es una máquina virtual completa: es más ligero y rápido.  

Containers are isolated processes for each of your app's components. Each component runs in its own isolated environment, completely isolated from everything else on your machine.  

#### Problemas que resuelve Docker
- Dependencias que son incompatibles con tu versión de software
- Dependencias en versiones diferentes
- Dependencias incompatibles entre proyectos
- Necesidad de reproducir entornos exactamente iguales
- Aislamiento de bases de datos, servidores web, etc.

#### Qué contiene un contenedor
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
#### Docker Images
A **Docker image** is an **inmutable blueprint** used to create containers. It contains everything required to run a service:
- Application files
- System dependencies
- Configuration files
- Startup instructions  
Images are built once and reused to create one or multiple containers.  

##### Image vs Container
| Image | Container |
|--------|------------|
| Immutable template | Running instance of an image |
| Built at build time | Exists at runtime |
| Stateless | Has runtime state |
| Cannot change | Can modify its filesystem during execution |

When a container is removed, all its runtime state is lost unless persistent volumes are used.  

#### Dockerfile

> ⚠️ -> HAY QUE RESUMIR ESTO EN EL README, PASAR COSAS A DEV_DOC...
> README:
> - Arquitectura general
> - request flow
> - explicación de PID 1 / exec resumida
> - qué hace cada servicio
> DEV_DOC
> - PID 1 en profundidad
> - Shell vs exec form
> - Señales
> - inicialización vs runtime
> - wp-config.php y modelo de datos
> - decisiones de diseño
> - ????

A **Dockerfile** is a text file that defines **how a Docker image is built**.  
It describes:
- The base operating system
- Which packages are installed
- Which configuration files are copied
- Which command is executed when container starts
A Dockerfile mainly operates at **build time**, preparing the execution environment.
The **runtime behaviour** of the container is defined by its `ENTRYPOINT` (and optionally `CMD`).

> In *Inception*, each service uses a **custom Dockerfile**, as required by the subject.  

A core Docker principle is: 
> **One container = one main service**

In *Inception*, the architecture is split into three containers: `mariadb`, `wordpress`, `nginx` ([see Service Architecture](#service-architecture)).

Each container:
- Runs **one foreground process**
- Has its own Dockerfile
- Has a clearly defined responsibility

##### Dockerfile keywords
| Keyword | Definition |
|---------|------------|
| FROM | Defines the base image used to build the Docker image. This specifies the operating system and initial environment (e.g. `debian:bookworm`, `alpine:3.19`) |
| RUN | Executes a command **at build time** inside the image. Each `RUN` instruction creates a new image layer. It is similar to running a command in a shell during image creation |
| COPY | Copies files or directories from the build context (the directory containing the Dockerfile) into the image filesystem |
| EXPOSE | Documents which network ports the container listens on at runtime. It does **not** publish the port to the host, but makes it available for inter-container communication |
| ENTRYPOINT | Defines the executable that is run when the container starts. It is typically used to define the main service of the container |
| CMD | Provides default arguments to `ENTRYPOINT`, or defines the startup command if no `ENTRYPOINT` is specified |

### Container lifecycle, ENTRYPOINT and PID 1
⚠️ SE PUEDEN ACORTAR O JUNTAR APARTADOS? SON DEMASIADOS APARTADOS Y MUY CORTOS... O SPLITEAR EL RESTO DE APARTADOS, PARA QUE TODO QUEDE CON ESTÉTICA SIMILAR
#### Containers and Processes
A Docker container is **not a virtual machine**.  
It does not run a full system, nor multiple independent services.  
A container lives **as long as its main process is running**.  
This main process is called **PID 1**.  

#### PID 1 in Linux and Docker
In Linux, **PID 1** is the first process started by the kernel.  
It has special responsibilities:
- Receiving and handling system signals
- Reaping zombie processes
- Managing child processes
In Docker:
- Each container has its own **isolated PID namespace**
- Each container therefore has its **own PID 1**.  
PID 1 is defined by:  
- The command specified by `ENTRYPOINT`
- Or by `CMD` if no `ENTRYPOINT` is provided

#### PID 1 and Container Lifetime
- The process running as PID 1 **keeps the container alive**
- If PID 1 exits, the container stops
- Docker monitors **only PID 1**  
Because of this, the following patterns cause **incorrect behaviour**:
- Running the real service in background
- Letting the startup script exit
- Using fake "keep-alive" loops  

##### Why infinite loops are forbidden  
A common anti-pattern is:

          service mysql start
          while true; do sleep 1; done

This is **explicitly forbidden** in *Inception*.  
- The loop becomes PID 1 instead of the real service
- Signals sent by Docker are not forwarded correctly
- The real service cannot shut down cleanly
- Zombie processes may accumulate

#### Foreground vs background
A process running in **foreground**:
- Is not started with `&`
- Does not return control to the shell
- Remains attached to PID 1
- Keeps the container alive
A process running in **background**
- Is started with `&`
- Allows the script to continue and exit
- Is **not** PID 1
- Will be terminated when the container stops
If the startup script finishes and no foreground process remains, the container exits.

#### `exec`, PID 1 and service startup
When a container starts a **shell or a script** (for example via `ENTRYPOINT ["setup.sh"]), the shell becomes PID 1 by default.  
In this case, using `exec` INSIDE THE STARTED SHELL O SCRIPT is **mandatory** to replace the shell process with the real service.  

Example: 

      exec mysql
      exec php-fpm -F

What `exec` does:
- Replaces the current shell process
- Turns the executed program into **PID 1**
- Allows Docker to send signals directly to the service
- Ensures proper shutdown behavior

Without `exec`, the shell remains PID 1 and the real service runs as a child process, which breaks signal handling.

##### When `exec` is NOT required
If the container starts the binary **directly**, this is the **exec form** of `CMD` or `ENTRYPOINT`, no shell is involved.  

In the NGINX container, the service is started IN THE DOCKERFILE as:

        CMD ["nginx", "-g", "daemon off;"]

This is the exec form of `CMD`, which means:
- No shell is spawned
- `nginx`  becomes PID 1 directly
- Signal handling works correctly

> `ENTRYPOINT["nginx", "-g", "daemon off;"]` would also be valid, but `CMD` is sufficient here.

#### One main process per container
Docker containers are designed to run a single main proces.  
In *Inception*:

| Container | PID 1 process |
|------------|---------------|
| `mariadb` | MariaDB server |
| `wordpress` | php-fpm |
| `nginx` | nginx |

Some containers require an **initialization phase** before starting the main service:
- **MariaDB** initializes databases and users
- **WordPress** generates configuration and installs the application
These containers use setup scripts as `ENTRYPOINT`.
Once initialization is complete, the real service is started with `exec`.
NGINX does not require initialization:
- No application state
- No database dependency
- No runtime configuration generation  
It can therefore start directly as PID 1.  

#### Container Shutdown
When running:

          docker compose stop

Docker performs the following steps:
1. Sends `SIGTERM` to PID 1
2. Wits a short grace period
3. Sends `SIGKILL` if the process does not exit

Services handle shutdown internally:
- MariaDB closes connections and flushes data
- PHP-FPM stops workers
- NGINX closes sockets

If the process:
- Runs in foreground
- Is PID 1
- Handles signals correctly  
then, the container shuts down cleanly.  

⚠️ ESTA VERIFICACIÓN DEBERIA IR EN ALGUNA OTRA PARTE...
To verify clean shutdown:  

        docker inspect <container> | grep ExitCode

- `0` -> clean exit
- `137` -> SIGKILL (bad) 

### Service Architecture
The project is composed of **three isolated services**, each running in its own container and connected through a Docker network.  
| Service | Container |  Role | Exposed port |
|---------|-----------|-------|--------------|
| NGINX | `mariadb` | TLS termination, reverse proxy | 443 |
| WordPress (PHP-FPM) | `wordpress` | Application logic, PHP execution | 9000 |
| MariaDB | `nginx`| Persistent data storage | 3306 |  

Each service has a single responsibility and communicates with the others through a well defined network interfaces.  
#### Request flow and PHP execution

        Browser -> NGINX (443) -> PHP-FPM (9000) -> WordPress (PHP) -> MariaDB (3306)

- **NGINX** handles HTTPS and forwards PHP requests
- **FastCGI** is protocol used by NGINX to send PHP request to PHP-FPM
- **PHP-FPM** executes PHP scripts
- **WordPress** processes the PHP scripts and queries the database
- **MariaDB** stores WordPress data

⚠️ AÑADIR PÁRRAFO EXPLICATIVO SENCILLO EJEMPLIFICANDO CÓMO INTERACTUAN LOS SERVICIOS ENTRE SÍ. EJ: NGINX RECIBE / REGISTRA UNA REQUEST (EJEMPLO: ALGUIEN QUIERE ACCEDER A LA WEB O A X PÁGINA...) -> ESTA REQUEST SE TRANSPITE / TRADUCE CON ... -> PHP SCRIPT  QUE PASA A WORDPRESS -> WORDPRESS QUERIES THE DATABASE (ESTO QUÉ SIGNIFICA? QUE HACE UNA CONSULTA SQL A MARIADB?) -> MARIADB TIENE LAS DATABASES CON LA DATA... NO ENTIENDO MUY BIEN CÓMO VA ESTO...

#### MariaDB
**MariaDB** is an SQL database server (a MySQL-compatible fork).  
WordPress uses it to store:
- Post and pages
- Users and passwords
- Configuration
- Plugins and metadata

⚠️ CREO QUE TODA ESTA PARTE DEL BUILD TIME / RUNTIME YA ES ALGO QUE DEBERIA IR EN DEV_DOC.MD
##### MariaDB - Build time (Dockerfile)
During image construction, the MariaDB Dockerfile performs the following steps:
- Uses a minimal Debian base image
- Installs the MariaDB server packages
- Copies a custom MariaDB configuration file
- Copies an initialization script (`setup.sh`)
- Exposes port `3306` for internal container communication
- Defines `setup.sh` as the container `ENTRYPOINT`

###### Custom configuration (`my.conf`)
The default MariaDB configuration binds the server to `127.0.0.1`, which would prevent connections from other containers.  
The custom configuration overrides this behaviour:
- MariaDB listens on `0.0.0.0`
- This allows WordPress to connect through the Docker bridge network
- The database remains inaccessible from the host unless explicitly exposed (???POR ESO PARA ACCEDER A LA DATABASE TENEMOS QUE ENTRAR CON mysql -u root -p??)
This configuration enables inter-container communication while preserving isolation.  
##### MariaDB - Runtime (setup.sh)
The `setup.sh` script is executed **every time the MariaDB container starts**, because it is defined as the `ENTRYPOINT`.  
Its responsibilities are:
- Prepare required runtime directories
- Detect whether the database has already been initialized
- Initialize the database only on the first container startup
- Create the applciation database and user
- Start MariaDB as the main foreground process
This logic is essential when using **persistent volumes**, because containers may be restarted while data must remain intact.  

###### Background vs Foreground MariaDB
During the first startup, MariaDB is launched **temporarily in background**:
- This allows execution of SQL commands (`CREATE DATABASE`, `CREATE USE`)
- The server does not need to remain running permanently at this stage
Once initialization is complete:
- The temporary MariaDB process is stopped
- MariaDB is restarted in **foreground mode**
- The foreground MariaDB process becomes **PID 1**, which is required for Docker to:
  - Track the container lifecycle
  - Send signals correctly
  - Keep the container running

#### WordPress
**WordPress** is a PHP-based **Content Management System (CMS)**.  
It allows easy creation and management of:
- Pages and posts
- Blogs
- Users and roles
- Plugins and themes
In this project, WordPress runs with **PHP-FPM** (not Apache). For details about how PHP requests are processed, [see Request flow and PHP execution](#request-flow-and-php-execution).

⚠️ CREO QUE TODA ESTA PARTE DEL BUILD TIME / RUNTIME YA ES ALGO QUE DEBERIA IR EN DEV_DOC.MD
##### WordPress - Build time (Dockerfile)
During **image construction**, the WordPress Dockerfile does **not install WordPress** itself. Instead, it prepares an environment capable of running WordPress.  
Reasoning:
- Installing WordPress at build time would embed application state into the image:
  - Files and configuration would become part of the image, not stored in persistent volumes
  - Updates or database.specific configuration could be overwritten on container restart
  - Persistence would break: WordPress state (plugins, uploads, settings) must live in volumes, not the image
    
Build time prepares **tools and environment only**:
  - **PHP and PHP-FPM**
  - **WP-CLI** (WordPress Command-Line Interface):
    - Used to download WordPress core
    - Create `wp-config.php`
    - Install WordPress automatically
    - Create admin and additional users
    - Manage plugins and themes
  - Custom PHP-FPM configuration (`www.conf`)
  - Runtime directory for PHP-FPM
  - The setup script (`setup.sh`)  
The Dockerfile sets `ENTRYPOINT` to `setup.sh`, which will handle application state at runtime  

> Key principle:  
> - **Build time = infrastructure**
> - **Runtime = application state**
> WordPress installation is application state, so it occurs at runtime.

###### PHP-FPM configuration (`www.conf`)
The PHP-FPM pool configuration is provided at build time via custom `www.conf` file. This file defines how PHP-FPM listens for incoming requests and how worker processes are managed.  
Key aspects of the configuration:
- PHP-FPM runs under the `www-data` user and group, matching NGINX expectations
- Listens on port `9000` for FastCGI request from NGINX
- Uses a dynamic process manager (`pm = dynamic`)
- Limits the number of PHP worker proesses to avoid resource exhaustion
- Keeps env variables (`clear_env =  no`) so that configuration passed through Docker environment variables is available to PHP.
This configuration is part of the infraestructure and does not change at runtime, which is why it is defined during image build.  

##### WordPress - Runtime (setup.sh)
The `setup.sh` script is executed **every time the container starts**. Its responsibilities are:
- File permissions: ensures `/var/www/html` is owned by `www-data` and has correct permissions
- Wait for MariaDB
- First-time WordPress installation: checks for `wp-config.php`; if missing, runs installation commands
- Preserve state: if the container restarts, skips installation, leaving volumes untouched
- Start PHP-FPM: runs in **foreground** using `exec`, makinf PHP-FPM **PID 1**. This ensures Docker can manage container lifecycle and signals correctly.

##### `wp-config.php` 
At runtime, PHP-FPM uses the previously defined pool configuration and focuses on executing PHP scripts.  
Application-specific configuration, such as database credentials and WordPress settings, is not handled by PHP-FPM itself but by WordPress through `wp-config.php`, which is generated dynamically at container startup.  
`wp-config.php` contains the runtime configuration of WordPress, including:
- Database connection parameters
- Authentication keys and salts
- Table prefix and environment-specific settings

`wp-config.php` is generated at runtime, durinf the first container startup, in `setup.sh` using WP-CLI and environment variables, ensuring that sensitive data is not baked into the image and that configuration persist correctly across container restarts.  

#### NGINX

### Docker Compose
**Docker Compose** is a tool that allows defining and running multiple Docker containers together, along with their networks and volumes. It is managed through a `docker-compose.yml` file, which acts as the **architectural blueprint** of the project.  
Using Docker Compose, we can define:
- Which services are part of the system
- How they communicate
- Where persistent data is stored
- Which ports are exposed
- How containers are built and restarted
- The startup order of the services
In this project, the `Makefile` is responsible for executing Docker Compose commands.

#### The `docker-compose.yml` file in *Inception* 
This file defines the complete architecture of the project.  
##### Services
The system is composed of three services:
- `mariadb` -> data layer (database)
- `wordpress` -> application layer (PHP)
- `nginx` -> entry layer (reverse proxy + TLS)
Each service corresponds to one Docker container built from a custom Dockerfile.

##### Network
A single internal Docker network is defined. This private bridge network allows containers to communicate with each other using their service names and hostnames, without exposing internal traffic to the host.  

> Note: unlike the `host` network mode, which exposes containers directly to the host network, a bridge network provides isolation and controlled communication between services. This approach is more secure and better suited for multi-container architectures. For more infor, [see Docker Network](#docker-network).

##### Volumes and data persistence
Two persistent volumes are used:
- WordPress (`/var/www/html`)
- MariaDB (`/var/lib/mysql`)  
These volumes are implemented as [**bind mounts**](#data-persistence) to the host filesystem.

              /home/login/data/wordpress
              /home/login/data/mariadb

This ensures that:
- Website files and database data persist across container restarts.
- Data is not lost when containers are removed or rebuilt.

##### Main `docker-compose.yml` keywords

| Keyword | Description |
|-----|------|
| `services` | Defines the containers that compose the application (`nginx`, `wordpress`, `mariadb`). |
|  `build` | Specifies the path to the Dockerfile used to build the image. |
| `container_name` | Assigns a specific name to the container created from the service. |
| `env_file` | Specifies a file containing environment variables that are injected into the container at runtime. |
| `image` | Specifies an existing image to use. In *Inception*, custom images are built instead, as required by the subject. |
| `ports` | Maps ports from the host to the container (`HOST_PORT:CONTAINER_PORT`) |
| `volumes` | Defines persistent storage by mounting host directories into containers. |
| `depends_on` | Defines startup order between services, but does not ensure service readiness. |
| `networks` | Specifies the networks the container is connected to. |
| `restart` | Defines the container restart policy in case of failure. |
| `bridge` driver | Allows containers on the same host to communicate through an isolated internal network. |

##### Startup flow
When running:

        docker-compose up

Docker performs the following steps:
1. Creates the network
2. Builds the images if they do not already exist
3. Starts the containers following the dependency order:
   - `mariadb`
   - `wordpress`
   - `nginx`
   
   > ⚠️ The `depends_on` directive only ensures startup order. It does **NOT** guarantee that service is ready to accept connections.
   > For this reason, WordPress includes a waiting mechanism in its startup script to ensure MariaDB is available before continuing the installation process.
   > NGINX does not require such a mechanism, as it only needs to listen on port 443. When a PHP request is received, NGINX attempts to forward it to `wordpress:9000`. If WordPress is not yet ready, a temporary error may occur until the service becomes available.  

##### Communication between services
Thanks to the internal Docker network:  
- WordPress connects to MariaDB using `mariadb` as the database host (defined in `wp-config.php`)
- NGINXforwards PHP requests to Wordpress using:

                fastcgi_pass wordpress:9000

( defined in `/nginx/conf/nginx.conf`)

Overall request flow:

          Internet → NGINX → WordPress → MariaDB


### Data Persistence
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
Estos datos se borran con ... ⚠️ : docker-compose... con el MAKE FCLEAN

+ APARTE DE CON LA CREACION DE LAS VOLUMENES, QUÉ MÁS COSAS HACEMOS PARA ASEGURAR LA PERSISTENCIA DE DATOS?
+ DOCKERFILES -> WORDPRESS NO SE INSTALA EN EL DOCKERFILE, PORQUE SI NO SU ESTADO SERIA PARTE DE LA IMAGEN, SE INSTALA EN EL SCRIPT
+ DOCKERFILE -> TB HACEMOS ALGO EN EL DE MARIADB... (CREO QUE COMPROBAR SI EXISTE EL VOLUMEN, SI EXISTE NO REINSTALAMOS, O ALGO ASÍ, NO?)
+ en los setups ->  la filosofia de first container startup only tb aboga por la persistencia de volumenes de datos.

#### Docker Volumes vs Bind Mounts
Los contenedores son efímeros: si borras un contenedor, se borra su filesystem, es decir, se pierden las bases de datos, uploads, etc.  
Para evitarlo, Docker permite la **persistencia de datos fuera del contenedor** de dos maneras diferentes:
- Docker volumes
- Bind mounts
EXPLICAR BIND MOUNTS
¿POR QUÉ SI HEMOS GUARDADO TODO EN LOS VOLUMENES PERSISTENTES EN LOCAL, EN LOS SCRIPTS DE SETUP Y EN EL RESTO DEL CÓDIGO HACEMOS REFERENCIA TODO EL RATO A LOS DIRECTORIOS POR DEFECTO DE MARIABD Y WORDPRESS..?

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
Unlike the `host` network mode, which exposes containers directly to the host network, a bridge network provides isolation and controlled communication between services. This approach is more secure and better suited for multi-container architectures. 

### Secrets vs Environment Variables
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
