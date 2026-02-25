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
  - [Service Architecture](#service-architecture)
    - [MariaDB](#mariadb)
    - [WordPress](#wordpress)
    - [NGINX](#nginx)
    - [Networking](#networking)
      - [Request flow](#request-flow)
      - [Docker Network vs Host Network](docker-network-vs-host-network)
  - [Volumes and Data Persistence](#volumes-and-data-persistence)
    - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
- [Resources](#resources)

----------------------------------------

## Description
⚠️ CREO QUE ES MÁS IMPORTANTE INTRODUCIR INCEPTION COMO UN PROYECTO DE DOCKER ANTES QUE MENCIONAR LOS SERVICIOS... NO?? REPASAR ESTO
OPCION 2:
*Inception* is a **multi-container project** that deploys a persistent **WordPress website** with MariaDB as its database and **NGINX** as a reverse proxy with HTTPS support.  
The project runs **Docker containers inside a Virtual Machine**. Containers handle the application runtime, while persistent data is stored on the VM filesystem.  
The purpose of this project is:
- To provide a fully functional WordPress website running inside a reproducible Docker environment.
- To ensure persistent storage of website content, configuration, and database data across container restarts and rebuilds.
- To demonstrate proper container architecture, service orchestration, and persistent data management.

OPCION 1: 
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

## Instructions
⚠️ This sections explains ....   

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
This sections explains the core concepts and architecture of the *Inception* project:    
- Introduction to Docker and containers
- Docker images and Dockerfile
- General stack architecture (services and their responsibilities)
- How containers / services communicate (networking)
- Data persistence and storage
- Configuration via environment variables and secrets

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

### Service Architecture
The project stack consists of three isolated services, each running its own container:  
| Service | Container |  Role | Exposed port |
|---------|-----------|-------|--------------|
| NGINX | `nginx` | TLS termination, reverse proxy - entry layer | 443 |
| WordPress (PHP-FPM) | `wordpress` | Application logic, PHP execution - application layer | 9000 |
| MariaDB | `mariadb`| Persistent data storage - data layer | 3306 |  

-------------------
VERSION LARGA - DEV_DOC (QUE IGUAL HAY QUE TRASLADAR AQUI)
###
This project follows a **multi-container architecture**, where each service runs inside its **own isolated container** with a **single responsibility**.  
- **NGINX** handles HTTPS connections and acts as reverse proxy (entry layer)
- **WordPress (PHP-FPM)** executes PHP application logic (application layer)
- **MariaDB** stores persistent application data (data layer)

Each container runs **one main process only**, and containers communicate through a **private Docker bridge network**. 

Persistent application state is stored outside containers using **bind-mounted volumes** on the host system.  

------------------------------

##### MariaDB
**MariaDB** is a relational SQL database server (MySQL-compatible).  
WordPress uses it to store:
- Post and pages
- Users and passwords
- Configuration
- Plugins and metadata
MariaDB does not serve HTTP requests and is never exposed directly to the user.  

##### WordPress
**WordPress** is a PHP-based **Content Management System (CMS)**.  
It allows easy creation and management of websites, blogs, users, plugins, and themes.  
In this project, WordPress does not handle HTTP requests directly via Apache. Instead, it runs with **PHP-FPM**, while **NGINX** acts as the web server and reverse proxy.  
- **PHP-FPM (PHP FastCGI Process Manage)** is a service that executes PHP scripts and manages PHP worker processes. It receives PHP requests from NGINX using the FastCGI protocol and returns the generated reponse.
- **WP-CLI (WordPress Command-Line Interface)** is a command-line tool used to install, configure, and manage WordPress. In this project, WP-CLI is used at container startup tp perform the initial WordPress installation and configuration automatically.  

##### NGINX
**NGINX** is a high-performance web server and reverse proxy.  
In this project, it handles:  
- TLS termination (HTTPS)
- Routing requests to PHP-FPM, proxying PHP requests to PHP-FPM
- Serving static files

NGINX runs as a **single, foreground process** inside its container. It does not manage application state or interact directly with the database. This separation allows NGINX to start directly as PID 1 without requiring intermediate setup scripts.  

##### Networking
###### Request flow

        Browser -> NGINX (443) -> PHP-FPM (9000) -> WordPress (PHP) -> MariaDB (3306)

- **NGINX** receives all incoming HTTPS requests, serves static files, forwards `.php` requests to PHP-FPM via the FastCGI protocol
- **PHP-FPM** executes PHP scripts
- **WordPress** processes the PHP scripts and queries the MariaDB
- **MariaDB** stores, retrieves and returns persistent application data
- **WordPress** generates HTML
- **NGINX** returns response to browser

> Note: Docker Compose orchestrates this flow: defines services, networks, volumes, ports, and container dependencies.  

###### Docker Network vs Host Network
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

### Project Structure -> NO SE SI PASAR ESTO A DEV_DOC PARA PODER EXPLICAR EN ÉL UN POCO EL CÓDIGO DE CADA FILE, DE QUÉ SE ENCARGA...
   
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
                          │       └── nginx.conf
                          │
                          ├── wordpress/
                          │   ├── Dockerfile
                          │   ├── conf/
                          │   │   └── www.conf
                          │   └── tools/
                          │       └── setup.sh
                          │
                          └── mariadb/
                              ├── Dockerfile
                              ├── conf/
                              │   └── my.conf
                              └── tools/
                                  └── setup.sh


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
