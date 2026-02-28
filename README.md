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
  - [Docker and Containers](#docker-and-containers)
    - [Why Docker?](#why-docker?)
    - [Virtual Machine vs Docker](#virtual-machine-vs-docker)
  - [Docker images and Dockerfile](#docker-images-and-dockerfile)
  - [Architecture Overview](#architecture-overview)
      - [Services and responsibilities](#services-and-responsibilities)
      - [Request flow](request-flow)
      - [Docker Network vs Host Network](docker-network-vs-host-network)
  - [Data Persistence](#data-persistence)
    - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
- [Resources](#resources)

----------------------------------------

## Description

**Inception** is a Docker-based infrastructure project focused on building and orchestrating a complete web service stack using containerization.  
The project consist of designing a modular and reproducible environment where each service runs inside its own container, built from scratch using Dockerfiles and managed with Docker Compose.  
The deployed stack includes:
- **NGINX** as the secure HTPPS entry point
- **WordPress + PHP-FPM** as the application layer
- **MariaDB** as the database service  

All services communicate through an internal Docker network, while persistent data is stored on the host system.  
The goal of the project is to demonstrate fundamental DevOps concepts such as container isolation, service orchestration, networking, and data persistence in a controlled environment.  


## Instructions
This sections explains how to set up, build, and run the *Inception* project from scratch.  
For more detailed explanations about development environment configuration, refer to the [DEV_DOC](./DEV_DOC.md). 

### Prerequisites:
  - Acces to a Linux machine / VM ([see DEV_DOC](./DEV_DOC.md#virtual-machine-setup-virtualbox-debian))
  - Dockera and Docker Compose installed ([see DEV_DOC](./DEV_DOC.md#installing-docker-docker-compose-and-build-tools))

### Installation
   - Clone the repository:
     
            git clone git@github.com:AnaMac3/42-Inception.git
     
     Options:
     - Clone on your local machine and share the folder with the VM via VirtualBox Shared Folders ([see DEV_DOC](./DEV_DOC.MD#shared-folders-between-host-and-vm))
     - Clone directly inside the VM (requires installing `git` in the VM)

   - Create the `.env` file in `srcs/` ([see DEV_DOC](./DEV_DOC.md#environment-variables-env-file))
   - Create the persistent volume folders in the VM:

         mkdir -p /home/<login>/data/mariadb
         mkdir -p /home/<login>/data/wordpress

### Build & Run
   - Start all services:

         make

  > Note: `make` builds thee Docker images and starts all containers in the stack.

  - Networking / SHH tunneling:
    - As services run inside the VM, HTTPS traffic must be forwarded to your host to access the site from the browser.
    - Domain configuration and SSH tunneling: [see DEV_DOC](./DEV_DOC#domain-configuration-and-ssh-tunneling).

   - Access to the website
     - Open in your browser:

               https://<login>.42.fr

### Stop & Clean

| Makefile command | Description |
|---------|--------------|
| `make stop` | Stops all running containers without removing them. Containers, networks, images, and volumes remain intact. |
| `make down` | Stops and removes containers and Docker Compose networks. Docker-managed volumes are removed, but bind-mounted persistent data in `/home/login/data/...` is preserved. Images are not deleted. |
| `male clean` | Stops and removes containers, networks, Docker-managed volumes, and project images. Persistent data directories in `/home/login/data/...` are not deleted. |
| `make fclean` | Performs `make clean`, then deletes all persistent data in `/home/login/data/...` and runs `docker system prune -a --force`. This fully resets the project to a fresh state.|

> **Important**: Persistent data and `.env` files with sensitive credentials should **never** be pushed to Github. Only Makefile, Dockerfiles, docker-compose.yml, scripts, and configuration files are versioned.   

## Project description
*Inception* is a containerized web infrastructure built with Docker and Docker Compose.  
The project deploys a complete WordPress stack composed of independent services that cooperate through an isolated network while keeping persistent application data outside contianers.  
This section provides a high-level overview of the technologies used, the system architecture, how services communicate, and how data persistence is achieved.  
For detailed theoretical explanations and implementation details, see the [DEV_DOC](./DEV_DOC.md). 

### Docker and Containers
**Docker** is a platform to run applications inside **containers** - isolated, lightweight, and reproducible environments that include only the necessary dependencies.  
A **container** is an isolated, self-contained runtime instance of a **Docker image**. Each container includes:
- The application (e.g., WordPress, NGINX, MariaDB)
- Dependencies and libraries
- Configuration files
- Minimal runtime environment

Containers are isolated processes for each component of your app. Containers provide process, filesystem, and network isolation.  

#### Why Docker?
- Avoids dependency conflicts between projects
- Ensures reproducible environments
- Isolates services (web server, database, PHP) from the host system
- Fast startup and low resource usage compared to full VMs

#### Virtual Machine vs Docker
| Virtual Machine | Contenedor Docker |
|-----------------|-----------|
| Complete OS with kernel | Shares host kernel |
| Heavy and slow to start | Lightweight, starts in milliseconds |
| High RAM/CPU usage | Minimal resource usage |
| Full isolation | Process & network isolation, but shared kernel |

> In *Inception*, **Docker containers run inside a Debian VM**. The VM provides an isolated host environment, while containers manage the application runtime. This combination allows efficient resource use while maintaining isolation and reproducibility.  

### Docker Images and Dockerfile
A **Docker image** is an inmutable blueprint used to create containers. It contains:
- Application files
- System dependencies
- Configuration files
- Startup instructions.

Images are built once and reused to create one or multiple containers.   
A **container** is a running instance of an image. Containers are ephemeral by default: removing a container deletes all runtime data unless persisted externally.  

A **Dockerfile** is a text file that defines **how a Docker image is built**, specifying:
- Base Operating System (OS)
- Packages to install
- Configuration files to copy
- Commands to run at container start (`ENTRYPOINT`, `CMD`)  

> A core Docker best practice is:   
> **One container = one main service**  
> In *Inception*, each service (`mariadb`, `wordpress`, `nginx`) runs in its own container, each with a dedicated Dockerfile.  

### Architecture Overview
The project follows a **layered multi-container architecture**, where each service has a single responsibility and runs in its own Docker container.  

| Service | Role |
|---|----|
| **NGINX** | HTTPS reverse proxy and public entry point |
| **WordPress (PHP-FPM)** | Application logic and PHP execution |
| **MariaDB** | Persistent database storage |

Services communicate through a private Docker network, while only one service is exposed to the outside world.  

#### Service responsibilities
- **NGINX**
  - Terminates HTTPS connections
  - Serves static files
  - Forwards PHP requests to WordPress via FastCGI
- **WordPress / PHP-FPM**
  - Executes PHP scripts
  - Generates dynamic content
  - Queries the database
- **MariaDB**
  - Stores users, posts, configuration, and metadata
  - Provides persistent storage for the application

#### Request flow

          Browser
             ↓ HTTPS (443)
          NGINX
             ↓ FastCGI (9000)
          WordPress (PHP-FPM)
             ↓ SQL (3306)
          MariaDB

1. The browser connect to NGINX via HTTPS
2. NGINX serves static files or forwards PHP request
3. PHP-FPM executes WordPress code
4. WordPress queries MariaDB when data is required
5. The generated HTML response is returned to the browser  

#### Docker Network vs Host Network
Containers communicate over networks. There are two main types:  
- **Bridge network (default)**: private network for containers, allows secure communication using service names. Internal ports are not exposed to the host unless explicitly mapped.  
- **Host network**: container shares the host's network stack; ports are exposed directly.

> In *Inception*, all services uses a bridge network for security and isolation. This network is defined in the `docker-compose.yml` file.  

Thanks to the internal bridge network:
- WordPress connects to MariaD using the service name `mariadb` (`setup.sh`)
- NGINX forwards PHP requests to WordPress using `fastcgi_pass wordpress:9000` (defined in `nginx.conf`)
This ensures internal traffic is isolated, secure, and predictable.  

### Volumes and Data Persistence
Containers are ephemeral: deleting a container removes its filesystem. To avoid this, Docker allows the **data persistant outside the container** by two different ways:
  - **Docker volumes**: managed by Docker, path hidden, recommended in production because they are safer.
  - **Bind mounts**: host-controlled path, easy to inspect, allows explicit paths. 

#### Docker Volumes vs Bind Mounts
| Feature | Docker Volume | Bind Mount |
|-----|------|------|
| **Advantages** | - Easy to use <br> - Docker manages permissions (less human error) <br> - Portable <br> - Recommended for production | - Full control over host path <br> - Easy to inspect files directly |
| **Disadvantages** | - Location on host is not directly visible <br> - Subject requires specific path <br> - Harder to demonstrate persistence in a specific directory | - More prone to permission issues <br> - Less portable <br> - Host interference possible |

In this project, data persistance is implemented using **bind mounts** to host directories:

              /home/login/data/wordpress  -> /var/www/html (WordPress files)
              /home/login/data/mariadb    -> /var/lib/mysql (database files)

> This ensures that website files and database data persist across container restarts and rebuilds. Docker volumes could be used in production, but bind mounts give precise control over paths for this project.  

### Secrets vs Environment Variables
- Non-sensitive configuration (DB name, users, site title) is stored in `.env`.
- Sensitive data (passwords) should use **Docker secrets** in production
- `.env` must **never** be commited to GitHub
- Docker secrets are **not committed**; they are provided to containers at runtime and securely managed by Docker.

> This separation ensures credentials and configuration data are handled securely and follow best practices.  

QUÉ SON LOS DOCKER SECRETS?  
Un `secrets` es un archivo montado dentro del contenedor solo en **runtime**, pensado para datos sensibles.  
Diferencias clave:
| `.env` | `secrets` |
|---|----|
| Variables visibles | Archivos protegidos |
| Acaban en `docker inspect` qué significa esto???? | NO visibles |
| Buenas para condig | Buenas para passwords |
| Persisten en logs/env | No se exponen |

Qué debe ir en secrets?:
- root password y database user password de MariaDB
- password del admin y del user de wordpress

Qué debe ir en .env?:
- domain name
- db name
- db username
- wordpress title
...

Cómo funcionan técnicamente los secretos?  
- Docker monta un archivo en `/run/secrets/<secret_name>
- No es una variable de entorno, es un archivo.

recomendado: carpeta secrets con un txt por password  

En docker compose: añadir:

          secrets: 
            password1:
              file: ./secrets/password.txt
            password2:-...


Y luego en servicio:

          services:
            mariadb:
              secrets:
                - password1
                - password2...


MariaDB espera variables, pero los secrets son archivos ->  
Antes hacíammos:

          MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD

Ahora, en entrypoint script:

        MYSQL_ROOT_PASSWORD=$(cat /run/secrets/password)

Cuando tenga secrets, cómo mostrar que no aparecen:

        docker inspect mariadb

-> password no visible

Mostrar existencia:

        docker exec -it mariadb ls /run/secrets

Mostrar lectura

        docker exec mariadb cat /run/secrets/password

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
