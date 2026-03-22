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
      - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Volumes and Data Persistence](#volumes-and-data-persistence)
    - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
    - [Environment variables (`.env`)](#environment-variables-env)
    - [Docker secrets](#docker-secrets)
- [Resources](#resources)

----------------------------------------

## Description

**Inception** is a Docker-based infrastructure project focused on building and orchestrating a complete web service stack using containerization.  
The project consists of designing a modular and reproducible environment where each service runs inside its own container, built from scratch using Dockerfiles and managed with Docker Compose.  
The deployed stack includes:
- **NGINX** as the secure HTTPS entry point
- **WordPress + PHP-FPM** as the application layer
- **MariaDB** as the database service  

All services communicate through an internal Docker network, while persistent data is stored on the host system.  
The goal of the project is to demonstrate fundamental DevOps concepts such as container isolation, service orchestration, networking, and data persistence in a controlled environment.  


## Instructions
This section explains how to set up, build, and run the *Inception* project from scratch.  
For more detailed explanations about development environment configuration, refer to the [DEV_DOC](./DEV_DOC.md). 

### Prerequisites:
  - Access to a Linux machine / VM ([see DEV_DOC](./DEV_DOC.md#virtual-machine-setup-virtualbox-debian))
  - Docker and Docker Compose installed ([see DEV_DOC](./DEV_DOC.md#installing-docker-docker-compose-and-build-tools))

### Installation
   - Clone the repository:
     
            git clone git@github.com:AnaMac3/42-Inception.git
     
     Options:
     - Clone on your local machine and share the folder with the VM via VirtualBox Shared Folders ([see DEV_DOC](./DEV_DOC.MD#shared-folders-between-host-and-vm))
     - Clone directly inside the VM (requires installing `git` in the VM)

   - Create the `.env` file in `srcs/` ([see DEV_DOC](./DEV_DOC.md#environment-variables-env-file))
   - Create `secrets` directory and files ([see DEV_DOC](./DEV_DOC.md#secrets))

### Build & Run
   - Start all services:

         make

  > Note: `make` creates the persistent storage directories on the host, builds the Docker images, creates the container stack, and starts all services defined in docker-compose.  

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
| `make clean` | Stops and removes containers, networks, and project images. Persistent data directories in `/home/login/data/...` are not deleted. |
| `make fclean` | Performs `make clean`, then deletes all persistent data in `/home/login/data/...` and docker volumes and runs `docker system prune -a --force`. This fully resets the project to a fresh state.|

> **Important**: Persistent data,`.env` files and `secrets` with sensitive credentials should **never** be pushed to Github. Only Makefile, Dockerfiles, docker-compose.yml, scripts, and configuration files are versioned.   

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
Containers are ephemeral: deleting a container removes its filesystem. To persist data, Docker provides different storage mechanisms.   
In this project, we use a **hybrid approach based on Docker volumes configured with bind-backed storage**.   
There are two main concepts:  
  - **Docker volumes**: storage objects fully managed by Docker. The physical location on host is abstracted internally by Docker.   
  - **Bind mounts**: direct mapping between a specific directory on the host and a path inside the container. Host-controlled path, easy to inspect.

In this project, we use **Docker volumes with bind-backedn configuration (driver_opts)**. This means Docker volumes are defined and managed by Docker, but physically stored in specific host directories.  

#### Docker Volumes vs Bind Mounts
| Feature | Docker Volume | Bind Mount |
|-----|------|------|
| **Advantages** | - Managed by Docker <br> - Safer abstraction layer <br> - Portable configuration <br> - Standard in containerized apps <br> - Recommended for production | - Full control over host path <br> - Easy direct inspection <br> - Inmediate visibility of files |
| **Disadvantages** | - Location on host is not directly visible, host path is abstracted <br> - Requires Docker tooling to inspect | - More prone to permission issues <br> - Less portable <br> - Strong dependecy on host structure |

> ⚠️ In this project we do not use raw bind mounts directly in services. Instead, we define Docker volumes that are physically stored in specific host paths.


### Secrets vs Environment Variables
This project separates **configuration** data from **sensitive credentials** following Docker best practices.  

#### Environment variables (`.env`)
Non-sensitive configuration (DB name, users, site title) is stored in the `.env` file.  
Examples include:  
- domain name
- database name
- database username
- WordPress site configuration
- email addresses  
The `.env` file:
- contains **configuration only**
- allows dynamic container configuration without modifying source code
- **must NOT be commited** to versiol control  
Environment variables are visible inside containers and may appear in container metadata.
For details about how environment variables are configured in this project, see: [`.env` configuration](./DEV_DOC.md#environment-variables-env-file)  

#### Docker Secrets
Sensitive data such as passwords are managed using Docker secrets.  
A Docker secret is a file securely mounted inside a container **at runtime only**, specially designed to store **confidential information**.  
Secrets protect credentials during container startup.  
In this project, secrets are used for:
- MariaDB root and user passwords
- WordPress admin and user passwords

Unlike enviroment variables:

| Environment variables | Secrets |
|--|--|
| Stored as container variables | Mounted as protected files |
| Visible via container inspection (`docker inspect`) | Not exposed in container metadata |
| Suitable for configuration | Suitable for credentials |
| May appear in logs or environment dumps | Limited runtime exposure |


For implementation details, see: [`secrets` configuration](./DEV_DOC.md#secrets). 

## Resources 
[dockerdocs](https://docs.docker.com/)  
[dockerdocs - Overview](https://docs.docker.com/get-started/docker-overview/)
[dockerdocs - Building best practices](https://docs.docker.com/build/building/best-practices/)  

[hynek - docker signals](https://hynek.me/articles/docker-signals/)  

[Docker compose commands](https://iesgn.github.io/curso_docker_2021/sesion5/comando.html)   
[Docker commands](https://kinsta.com/es/blog/comandos-docker/)  
[Dockerfile keywords](https://www.nicelydev.com/docker/mots-cles-supplementaires-dockerfile#:~:text=Le%20mot%2Dcl%C3%A9%20EXPOSE%20permet,utiliser%20l'option%20%2Dp%20.)  


[SQL keywords](https://www.w3schools.com/sql/sql_ref_keywords.asp)  
[WordPress documentation](https://wordpress.org/documentation/)  

[Grademe tutorial](https://tuto.grademe.fr/inception/)  
[Forstman1 repo](https://github.com/Forstman1/inception-42)  
[gemartin99 repo](https://github.com/gemartin99/Inception?tab=readme-ov-file)  

⚠️ ⚠️  AÑADIR USO DE LA IA!!





