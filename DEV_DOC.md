# 42-Inception - Developer Documentation

This document describes the technical architecture of the *Inception* project. It focuses on how the system is built, deployed, configured, persisted and inspected, and is intended for developers and evaluators.  

## Table of Contents
- [Set up the environment from scratch](#set-up-the-environment-from-scratch)
  - [Virtual Machine setup (VirtualBox + Debian)](#virtual-machine-setup-virtualbox--debian)
    - [Virtualization tool](#virtualization-tool)
    - [Debian ISO](#debian-iso)
    - [Creating the Virtual Machine](#creating-the-virtual-machine)
    - [Installing Debian inside the VM](#installing-debian-inside-the-vm)
    - [Basic VM management](#basic-vm-management)
  - [Installing Docker, Docker Compose and build tools](#installing-docker-docker-compose-and-build-tools)
  - [Shared folders between host and VM](#shared-folders-between-host-and-vm)
  - [Persistent volumes](#persistent-volumes)
  - [Environment variables (`.env` file)](#environment-variables-env-file)
  - [Domain configuration and SSH tunneling](#domain-configuration-and-ssh-tunneling)
    - [`/etc/hosts`](#etchosts)
    - [SSH tunneling (VM -> host browser)](#ssh-tunneling-vm--host-browser)
      - [Windows / WSL](#windows--wsl)
      - [42 iMacs / Linux - no sudo](#42-imacs--linux-no-sudo)
- [Build and launch the project using the Makefile and Docker Compose](#build-and-launch-the-project-using-the-makefile-and-docker-compose)
  - [Core Docker Compose commands](#core-docker-compose-commands)
  - [Makefile shortcuts](#makefile-shortcuts)
- [Theory - Fundamental Concepts](#theory---fundamental-concepts)
  - [Container execution model](#container-execution-model)
    - [Build time vs runtime](#build-time-vs-runtime)
    - [PID 1 and Process Management](#pid-1-and-process-management)
    - [Foreground vs background](#foreground-vs-background)
    - [`exec`: replacing shell and signal handling](#exec-replacing-shell-and-signal-handling)
    - [Incorrect container behavior and forbidden patterns](#incorrect-container-behavior-and-forbidden-patterns)
  - [Container lifecycle](#container-lifecycle)
    - [Start, execution, and shutdown](#start-execution-and-shutdown)
    - [Signals and shutdown behavior](#signals-and-shutdown-behavior)
- [Applied architecture in Inception](#applied-architecture-in-inception)
  - [Services and Dockerfiles](#services-and-dockerfiles)
    - [MariaDB](#mariadb)
    - [WordPress](#wordpress)
    - [NGINX](#nginx)
  - [Docker Compose Orchestration](#docker-compose-orchestration)
    - [Service, internal network, and volumes](#service,-internal-network,-and-volumes)
    - [Startup flow and dependencies](#startup-flow-and-dependencies)
    - [Key `docker-compose.yml` directives](#key-docker-compose.yml-directives)
  - [Data persistence](#data-persistence)
    - [Persistent data locations](#persistent-data-locations)
    - [Volume contents](#content-of-each-volume)
    - [Relation with `make down / clean / fclean`](#relation-with-make-down-clean-fclean)
  - [WordPress - MariaDB Data Model](#wordpress-mariadb-data-model)
    - [`wp-config.php`](#wpconfig.php)
    - [Database structure and tables](#database-structure-and-tables)
- [Inspection and testing](#inspection-and-testing)
  - [Useful Docker commands](#useful-docker-commands)
  - [Container access and inspection](#container-acces-and-inspection)
  - [MariaDB inspection](#mariadb-inspection)
  - [Volume persistence verification](#volume-persistence-verification)
  - [Logs and debugging](#logs-and-debugging)
 

---

## Set up the environment from scratch

This sections explains how to prepare a complete development environmet to run the *Inception* project from scratch.  
The stack is deployed inside a **Debian Virtual Machine** using **Docker and Docker Compose**, with persistent volumes stored on the VM filesystem.  
The setup includes:
- VirtualBox virtual machine
- Debian installation
- Network and SSH access
- Docker and Docker Compose
- Shared folders (optional)
- Persistent volumes
- Environment variables (`.env`)
- Domain configuration and SSH tunneling

### Virtual Machine setup (VirtualBox + Debian)

#### Virtualization tool
The project is developed inside a virtual machine created with [Oracle VirtualBox](https://www.softonic.com/descargar/virtualbox/windows/post-descarga?dt=internalDownload)

> ⚠️ On 42 computers, the VM disk is usually stored in `sgoinfree` to avoid quota issues

#### Debian ISO
A [Debian GNU/Linux ISO](https://www.debian.org/download.es.html) is used to install the operating system inside the VM.

> **Clarification:**
> - The Debian OS installed in the VM is **independent** from the Debian images used inside Docker containers.
> - The ISO is only used to install the host operating system of the VM.

The Debian ISO is a disk image containing the full Debian installer. When mounted in VirtualBox, it behaves like a physical installation disk.  

#### Creating the Virtual Machine
In VirtualBox -> `New`:
- Name: inception
- Folder: sgoinfree (on 42 computers)
- OS: Linux
- OS Distribution: Debian
- OS Version: Debian (64-bit)
- RAM: minimum 2048 MB (recommended 4096 MB)
- Number of CPU: 2

##### VM settings before installation  
System -> Motherboard
- Boot order: Optiocal first (to boot from ISO)
- Chipset: default
 
System->Processor  
- CPUs: 2 (or more if available)
- Enable PAE/NX  

Display
- Video memory: 16-64 MB (no critical, no GUI required)  

Storage
- Attach the Debian ISO as an optical disk
- Use a virtual hard disk (`.vdi`) for the system installation  

Network
- Adapter 1: Bridged Adapter
  This allows the VM to obtain an IP address on the local network and enables SSH access from the host.

#### Installing Debian inside the VM
Start the VM and follow the Debian installer:
- Language, keyboard, timezone
- Partitioning: *Guided - use entire disk*
- Hostname: `debian-inception` (example)
- Domain name: can be left empty or set to `<login>.42.fr`
- Root password: secure password //blablapassword
- User:
  - Username: 42 login
  - Password: user password //passuser
- Software selection:
  - Installing a graphical desktop is optional (GNOME)
  - Install SSH server

After instalation, reboot the VM.

#### Basic VM management
| Task | Command / Explanation |
|------|-----------------------|
| Disable graphical mode permanently | `sudo systemctl set-default multi-user.target`|
| Reboot VM | `reboot`|
| Get VM IP address | `ip a` |
| SSH from host | `ssh <login>@<IP_VM>` |
| SSH port forwarding | `ssh -L 443:localhost:443 <login>@<IP_VM>` |
| Switch to root | `su -` |
| Return to user | `su - <login>` |

⚠️ AÑADIR MÁS COSAS ÚTILES!!

### Installing Docker, Docker Compose and build tools
Inside the Debian VM:

    sudo apt update
    sudo apt install -y docker.io docker-compose build-essential

Enable Docker and add the user to the docker group:

    sudo systemctl enable --now docker
    sudo usermod -aG docker <login>

Log out and log back in (or reboot), then verify:

    docker --version
    docker compose version
    groups <login>

### Shared folders between host and VM
Shared folders allow editing files on the host while running them inside the VM.  

Steps:  
- VM Settings -> Shared Folders
- Folder Path: local host directory
- Mount point: `/home/<login>/inception´
- Enable auto-mount and make permanent

- Inside the VM:

      sudo mkdir -p /home/<login>/inception
      sudo mount -t vboxsf -o uid=$(id -u),gid=$(id -g) inception /home/<login>/inception

- Add user to `vboxsf` group:

    sudo usermod -aG vboxsf $USER

- Guest Additions must be installed for shared folders to work correctly:
  - In the VM window -> Devices -> Insert Guest Aditions CD image
  - In the VM shell:

              sudo apt update
              sudo apt install -y build-essential dkms linux-headers-$(uname -r)
    
  - Mount the disk:
   
              sudo mkdir -p /mnt/cdrom
              sudo mount /dev/cdrom /mnt/cdrom

  - Check:
   
            ls /mnt/cdrom

    It must appear: `VBoxLinuxAdditons.run`

  - Run the installer:
   
            sudo /mnt/cdrom/VBoxLinuxAdditions.run

  - Reboot the VM:
   
              sudo reboot

  - Check after reboot:
   
            lsmod | gep vbox

    If `vbpxsf` appears, the shared folders must work. 

### Persistent volumes
Persistent data is stored on the VM filesystem and mounted into containers.

       # Create the directories
       mkdir -p /home/<login>/data/wordpress
       mkdir -p /home/<login>/data/mariadb

       #Adjust the permissions so that Docker can write
       sudo chown -R <login>:<login> /home/<login>/data

These directories are later mounted as Docker bind mounts and store all persistent project data.    

### Environment variables (`.env` file)
The `.env` file defines all configuration values used by Docker Compose and the containers.  
- It contains no executable code
- It must NOT be committed to version control
- It avoids hardcoding secrets in configuration files
- It must be located in `./srcs` 

Example structure:  

      DOMAIN_NAME=amacarul.42.fr

      MYSQL_HOSTNAME=mariadb
      MYSQL_DATABASE=database
      MYSQL_USER=amacarul
      MYSQL_PASSWORD=***
      MYSQL_ROOT_USER=root
      MYSQL_ROOT_PASSWORD=***
      
      WORDPRESS_TITLE=amacarulsWebsite
      WORDPRESS_ADMIN_USER=boss
      WORDPRESS_ADMIN_PASSWORD=***
      WORDPRESS_ADMIN_EMAIL=boss@inception.fr 
      WORDPRESS_USER=user1
      WORDPRESS_USER_EMAIL=user1@inception.fr
      WORDPRESS_USER_PASSWORD=***

Environment variables are used to configure containers dynamically without modifying source files.  
⚠️ HAY QUE USER SECRETS -> PARA LAS CONTRASEÑAS, NO??
⚠️ AÑADIR TABLA EXPLICATIVA !!!

| Variable | Purpose | 
|----------|---------|
| `DOMAIN_NAME` | |
| `MYSQL_HOSTNAME`| |
| `MYSQL_DATABASE` | |
| `MYSQL_PASSWORD` | |
| | |

### Domain configuration and SSH tunneling
Because the project runs inside a virtual machine, additional configuration is requried to access the HTTPS website from the host browser.  
This section explains how to map the custom domain locally and forward port 443 from the VM to the host using SSH tunneling.  

#### `/etc/hosts`  
Inside the VM:

      sudo nano /etc/hosts

Add:

    127.0.0.1 <login>.42.fr

Save with `Ctrl+O`, press Enter, exit with `Ctrl+X`.  
Verify with:

       ping <login>.42.fr

If it responds from `127.0.0.1`, the domain is well configurated inside the VM.  

#### SSH tunneling (VM -> host browser)
Since the services run inside a VM, HTTPS traffic must be forwarded to the host machine.   
##### Windows / WSL
Edit the host machine's `hosts` file (as administrator):
- Open Notepad as Administrator
- File -> Open
- Navigate to: `C:\Windows\System32\drivers\etc`
- Change file filtero to *All files*
- Open `hosts`
- Add: 

        127.0.0.1 <login>.42.fr

- Save and close

In the shell:

      ssh -L 443:localhost:443 <login>@<IP_VM>

> The tunnel remains active while the SSH session is open. 

Access from the host browser:

    https://<login>.42.fr


##### 42 iMacs / Linux (no sudo)
Port 443 cannot be used locally:

      ssh -L 8443:localhost:443 <login>@<VM_IP>

Access:

      https://localhost:8443

⚠️ SOCKS proxy alternative is still under investigation!! AVERIGUAR ESTO!!!

## Build and launch the project using the Makefile and Docker Compose
This section explains how the stack is built and managed using **Docker Compose**, abstracted through a **Makefile**.  
The Makefile provides a single interface to:
- build Docker images
- start and stop containers
- clean Docker resources
- reset the project state

Although no source code is compiled, `make` orchestrates Docker Compose commands to manage the lifecycle of the stack.  

### Core Docker Compose commands
| Command | Description | 
|---------|-------------|
| `docker compose build` | Builds Docker images defined in `docker-compose.yml` | 
| `docker compose up -d`| Creates and astarts containers in detached mode |
| `docker compose stop`| Stops running containers without removing them |
| `docker compose down` | Stops and removes containers and Docker networks |
| `docker compose ps` | Lists containers managed by Docker Compose |
| `docker compose down --volumes --rmi all` | Removes containers, networks, Docker-managed volumes, and images |
| `docker system prune -a --force` | Removes all unused Docker objects (containers, images, networks, cache) |

⚠️ Bind-mounted directories (`/home/login/data/...`) are not removed unless explicitly deleted.  

### Makefile shortcuts
The Makefile wraps the Docker Compose commands above and defines the project's persistence policy.  
| Makefile command | Description |
|---------|--------------|
| `make` | Builds Docker images (if needed) and starts the full stack in detached mode. Internally, runs - it does `docker compose build` followed by `docker compose up -d` |
| `make stop` | Stops all running containers without removing them. Containers, networks, images, and volumes remain intact. |
| `make down` | Stops and removes containers and Docker Compose networks. Docker-managed volumes are removed, but bind-mounted persistent data in `/home/login/data/...` is preserved. Images are not deleted. |
| `make clean` | Stops and removes containers, networks, Docker-managed volumes, and project images. Persistent data directories in `/home/login/data/...` are not deleted. |
| `make fclean` | Performs `make clean`, then deletes all persistent data in `/home/login/data/...` and runs `docker system prune -a --force`. This fully resets the project to a fresh state.|

⚠️ **Implication regarding images:**  
If images are not removed (`make down`), changes in `Dockerfile` or `setup.sh` will not be applied unles `docker compose build` (or `make`) is run again.  

## Theory - Fundamental Concepts
This section explains the theoretical foundations required to understand how the *Inception* project works internally.  
It focuses on **how Docker containers behave**, how their lifecycle is managed, and why certain design choices are mandatory to ensure correctness, stability, and compliance with the subject.  

### Container execution model
This project uses a **multi-container architecture**, where each service runs inside its **own isolated container** with a **single responsibility**.  
Containers communicate through a **private Docker bridge network**.    
Persistent application state is stored outside containers using **bind-mounted volumes** on the host system.   

#### Build time vs runtime
A fundamental concept in Docker is the strict separation between **build time** and **runtime**.
##### Build time
Occurs when an image is created using a `Dockerfile`:
- Base operating system is defined
- Packages and dependencies are installed
- Configuration templates and scripts are copied
- No application state is created

Images must remain **stateless and immutable**.  
##### Runtime
Occurs when a container is started from an image: 
- Application state is initialized if needed
- Configuration is generated dynamically
- Persistent data is read from or written to volumes    

> **Key principle**:
> **Images define infrastruture - containers manage state**

Any operation that depends on:
- Database contents
- Existing users
- Generated credentials
- Runtime configuration

  **must happen at runtime**, never during image build.  

#### PID 1 and Process Management
A Docker container is **not a virtual machine**. It does not run a full system, nor multiple independent services. A container lives **as long as its main process is running**. This main process is known as **PID 1**.  

##### PID 1 in Linux and Docker
In Linux, **PID 1** is the first process started by the kernel.  
It has special responsibilities:
- Receiving and handling system signals (`SIGTERM`, `SIGINT`)
- Reaping zombie child processes
- Managing shutdown behavior  
In Docker:
- Each container has its **own PID namespace**
- Each container therefore has its **own PID 1**.  
PID 1 is defined by:  
- The command specified by `ENTRYPOINT`
- Or by `CMD` if no `ENTRYPOINT` is provided  

If **PID 1 exits**, the container stops immediately.  
Docker **monitors only PID 1**  

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

If the startup script finishes and **no foreground process remains**, the container exits.

#### `exec`: replacing shell and signal handling
When a container starts via a **shell or a script** (for example via `ENTRYPOINT ["setup.sh"]), the shell becomes PID 1 by default.  
In this case, using `exec` inside the script is **mandatory** to replace the shell process with the real service.  

Example: 

      exec mysql
      exec php-fpm -F

What `exec` does:
- Replaces the current shell process
- Turns the executed program into **PID 1**
- Allows Docker to send signals directly to the service
- Ensures proper shutdown behavior

Without `exec`, the shell remains PID 1 and the real service runs as a child process, which breaks signal handling and shutdown.

##### When `exec` is NOT required
If the container starts the binary **directly** using the **exec form** of `CMD` or `ENTRYPOINT`, no shell is involved.  

Example (NGINX container - `Dockerfile`):

        CMD ["nginx", "-g", "daemon off;"]

This is the exec form of `CMD`, which means:
- No shell is spawned
- `nginx`  becomes PID 1 directly
- Signal handling works correctly

#### Incorrect container behavior and forbidden patterns
##### Background services
Running the main service in background (using `&`) is forbidden.  
- The background process does not become PID 1
- Docker cannot forward signals correctly
- The container lifecycle is broken

##### Exiting startup scripts
Letting the startup script exit without replacing itself with the real service causes the container to stop immediately.  
PID 1 must always be the actual service process.  

##### Fake keep-alive loops
A common anti-pattern is:

          service mysql start
          while true; do sleep 1; done

This is **explicitly forbidden** in *Inception*:  
- The loop becomes PID 1 instead of the real service
- Signals sent by Docker are not forwarded correctly
- The real service cannot shut down cleanly
- Zombie processes may accumulate

### Container lifecycle
#### Start, execution, and shutdown
Docker containers are designed to run **one main proces**.  
At a theoretical level, the lifecycle is:  
1. Container starts
2. PID 1 process starts
3. Container runs while PID 1 is alive
4. Docker sends signals on shutdown 
5. PID 1 exists
6. Container stops

In *Inception*:

| Container | PID 1 process |
|------------|---------------|
| `mariadb` | MariaDB server |
| `wordpress` | php-fpm |
| `nginx` | nginx |

Some containers require a **runtime initialization phase** before starting the main service:
- **MariaDB** initializes databases and users
- **WordPress** generates configuration and installs the application
After initialization, the real service **must replace the shell using `exec`**.  
NGINX does not require initialization:
- No application state
- No database dependency
- No runtime configuration generation

It therefore starts directly as PID 1.  

#### Signals and shutdown behavior
When running:

          docker compose stop

Docker performs the following steps:
1. Sends `SIGTERM` to PID 1
2. Wits a short grace period
3. Sends `SIGKILL` if the process does not exit

If PID 1:
- Runs in foreground
- Handles signals correctly
- Is the real service  

Then shutdown is clean:
- MariaDB closes connections and flushes data
- PHP-FPM stops workers
- NGINX closes sockets
If PID 1 does not handle signals properly, Docker is forced to kill the container.  

##### What appens if PID 1 exits
If PID 1 exits:
- The container stops immediately
- Docker considers the container terminated
- Restart policies may trigger a restart
This is why PID 1 must always be the real service.  


## Applied Architecture in Inception
This section describes **how the theoretical Docker concepts explained earlier are applied concretely in the Inception project**.  
It focuses on the **practical implementation choices**, the role of each service, how containers are built and started, how Docker Compose orchestrates the system, and how data persistence is ensured.  
### Services and Dockerfiles
Each service runs in its own container, built from a dedicated Dockerfile.  
#### MariaDB 
##### Build time
During image construction, the MariaDB Dockerfile prepares the **database infrastructure**:
- Installs the MariaDB server packages
- Copies a custom MariaDB configuration file (`my_conf`)
- Copies an initialization script (`setup.sh`)
- Exposes port `3306` for inter-container communication
- Defines `setup.sh` as the container `ENTRYPOINT`.
No database, user or application state is created at build time. This ensures the image remains **stateless and reusable**.    

###### Custom configuration (`my.conf`)
The default MariaDB binds the server to `127.0.0.1`, which prevents connections from other containers.  
The custom configuration overrides this behaviour:
- MariaDB listens on `0.0.0.0`
- This allows WordPress to connect through the Docker bridge network
- The database remains inaccessible from the host unless explicitly exposed
Access from the host is only possible via `docker exec`.  
This configuration allows controlled inter-container communication while preserving isolation from the host system.

##### Runtime initialization
The `setup.sh` script is executed **every time the MariaDB container starts**, as it is defined as the `ENTRYPOINT`.  
Its responsibilities are:
- Preparing runtime directories
- Detecting whether the database has already been initialized
- Initializing the database only on the first container startup
- Creating the application database and user
- Starting MariaDB as the main foreground process  
This logic supports **persistent volumes**.

##### Background vs foreground execution
During first startup:
- MariaDB is launched **temporarily in background**
- This allows execution of SQL commands (`CREATE DATABASE`, `CREATE USE`...)
- The temporary process is stopped
- MariaDB is restarted in **foreground mode** using `exec`  
Running in the foreground ensures that MariaDB becomes **PID 1**, allowing Docker to properly manage lifecycle and signals.

#### WordPress
##### Build time
At build time, the WordPress image **does not install WordPress** itself. Instead, it prepares the execution environment:  
- PHP and required extensions are installed
- WP-CLI is installed  
Installing WordPress at build time would embed application state into the image, breaking persistence and update safety. 
> - **Build time = infrastructure**
> - **Runtime = application state**  

##### Runtime WordPress installation
The `setup.sh` script is executed **every time the container starts**.  
Its responsibilities are:
- ensuring correct file permissions
- waiting for MariaDB availability
- installing WordPress only if not already present
- preserving existing data
- starting PHP-FPM in the **foreground** using `exec` -> PHP-FPM becomes PID 1.

###### `wp-config.php` generation
Application-specific configurations is handled by WordPress through `wp-config.php`, not by PHP-FPM.  
This file contains:
- database connection parameters
- authentication key and salts
- table prefix
- environment-specific settings

`wp-config.php` is generated at runtime using **WP-CLI and environment variables,** ensuring sensitive data is not baked into the image and that configuration persist correctly across container restarts.  

##### PHP-FPM role
WordPress runs using **PHP-FPM (FastCGI Process Manager)**.  
PHP-FPM:
- manages pools of PHP worker processes
- executes PHP scripts
- communicates with NGINX via FastCGI on port `9000`

A custom `www.conf` is provided at build time, defining:  
- execution user and group (`www-data`)
- listening on port `9000`
- dynamic process manager (`pm = dynamic`)
- worker limits to prevent resource exhaustion
- environment variable preservation (`clear_env =  no`)   
This configuration is **static infrastructure** and does not change at runtime.

##### WP-CLI role
**WP-CLI** is the official WordPress command-Line interface.  
It is used at runtime to: 
- download WordPress core
- create `wp-config.php`
- install WordPress
- create admin and additional users
- manage plugins and themes  
WP-CLI allows WordPress installation to be fully automated and reproducible.  

#### NGINX
##### Build time
During **image construction**, the NGINX Dockerfile:
- installs `nginx` and `openssl`:
  - `nginx`: the web server and reverse proxy
  - `openssl`: generates TLS certificates
- creates the folder for SSL certificates: `/etc/nginx/ssl`
- generates a **self-signed TLS certificate** (development use only, in production certificate should be isued by a trusted Certificate Authority - CA)
- copies the custom `nginx.conf` 
- exposes port `443` for HTTPS communication

###### TLS termination
NGINX handles:
- TLS negotiation (TLSv1.2 / TLSv1.3)
- Traffic decryption
- Secure client communication
This isolates cryptographic concerns from the application layer.

###### Reverse proxy role
NGINX:
- serves static files
- forwards PHP request to PHP-FPM
- enables clean WordPress URLs  

###### `nginx.conf` overview
The configuration:
- Listens on IPv4 and IPv6 over HTTPS
- Defines TLS certificates and protocols
- Serves WordPress files from `/var/www/html`
- Redirects non-existing paths to `index.php`
- Forwards `.php` requests to `wordpress:9000` via FastCGI
This allows WordPress to handle "pretty URLs" without physical files.

##### Foreground execution
NGINX does not require a setup script, it is executed **directly in foreground** as PID 1 using:

          CMD["nginx", "-g", "daemon off;"]

> A daemon is a background process detached from the terminal.
> Docker containers must not daemonize their main process. Running NGINX with `daemon off;` forces it to stay in foreground, allowing Docker to propperly track and control the container lifecycle.  

### Docker Compose Orchestration
**Docker Compose** is a tool that allows defining and running multiple Docker containers together, along with their networks and volumes. It is managed through a `docker-compose.yml` file, which acts as the **architectural blueprint** of the project.  
It specifies:
- Which services are part of the system
- How they communicate - networks
- Where persistent data is stored - volumes
- Which ports are exposed
- How containers are built and restarted
- The startup order of the services - dependencies
In this project, the `Makefile` is responsible for executing Docker Compose commands.  

#### Service, internal network, and volumes
Three service compose the stack:
- `mariadb` -> data layer
- `wordpress` -> application layer
- `nginx` -> entry layer

A single private Docker **bridge network** allows containers to communicate securely using service names as hostnames.  
- Only NGINX exposes a port to the host: `443` -> HTTPS entry point
- MariaDB (`3306`) and PHP-FPM (`9000´) remain internal and are accessible only inside the Docker network.
This prevents direct external access to the database and application runtime, enforcing a layered architecture.

        Internet → NGINX → WordPress (PHP-FPM) → MariaDB

This design:
- Isolates internal services
- Reduces attack surface
- Mirrors real-world production architectures

Unlike `host` network, which exposes containers directly to the host network, a bridge network provides isolation and controlled communication between services. This approach is more secure and better suited for multi-container architectures.  

Two **persistent bind mounts** are defined:

              /home/login/data/wordpress
              /home/login/data/mariadb

This ensures that:
- Website files and database data persist across container restarts.
- Data is not lost when containers are removed or rebuilt.

##### Startup flow and dependencies
When running:

        docker-compose up

Docker performs the following steps:
1. Creates the network
2. Builds the images if they do not already exist
3. Starts the containers following the dependency order:
   - `mariadb`
   - `wordpress`
   - `nginx`
  
`depends_on` controls order but not readiness - it does NOT guarantee that service is ready to accept connections.  
- WordPress implements an explicit wait mechanism for MariaDB availability.
- NGINX does nor require such a mechanism, as it only needs to listen on the corresponding port. When a PHP request is received, NGINX attemps to forward it to `wordpress:9000`. If WordPress is not yet ready, a temporary error may occur until the service becomes available.

##### Key `docker-compose.yml` directives

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


#### Data Persistence
##### Persistent data location
All persistent data is stored explicitly on the VM filesystem: 

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

- MariaDB stores its database files in the mariadb volume
- WordPress stores uploads, plugins, and themes in `wp-content`  

Bind mounts ensure data survives container removal and rebuilds.

##### Volume contents
###### MariaDB
- Host path: `/home/login/data/mariadb`
- Container path: `/var/lib/mysql`
- This directory contains all MariaDB database files -> all WordPress logical data:
  - WordPress users
  - Roles and permissions
  - Posts, pages, revisions
  - Comments
  - WordPress options

###### WordPress
- Host path: `/home/login/data/wordpress`
- Container path: `/var/www/html`
- This directory contains:
  - WordPress core
  - `wp-config.php`
  - Themes and plugins
  - Uploads
  This ensures WordPress content and configuration persist across restarts.

##### Relation with `make down / clean / fclean`
- `make down`:
  - Stops and removes containers
  - Persistent data remains: volumes under `/home/login/data/...` are untouched
- `make clean`:
  - Stops and removes:
    - containers
    - Docker networks
    - Docker-managed volumes (if any)
    - built images
  - Does not delete the bind-mounted directories / the persistent volumes
- `make fclean`:
  - Removes everything:
    - executes `clean`
    - explicitly deletes all persistent bind-mounted data
    - performs a full Docker system prune

> ⚠️ **Important distinction:**
> `clean` preserves data, `fclean` deletes it entirely.

#### WordPress - MariaDB Data Model
##### `wp-config.php`  
`wp-config.php` is the central configuration file that links WordPress with its database and define its runtime behaviour.   
It defines:
- Database connection: these values allow WordPress to connect to the MariaDB container over the Docker network:
   - `DB_NAME`
   - `DB_USER`
   - `DB_PASSWORD`
   - `DB_HOST`  
   WordPress connects to MariaDB via the Docker network, not via `localhost`.
- Security keys: used for:
   - authentication
   - cookies
   - session security
   These are generated automatically by `wp-cli` during setup.
- Table prefix: `wp_`
- Runtime behaviour: at the end of the file:

           define('ABSPATH', __DIR__ . '/');
           require_once ABSPATH . 'wp-settings.php';
   
   This loads and initializes the WordPress core.

In this project, `wp-config.php` it is generated automatically by `wp-cli` in the WordPress `setup.sh` script and stored persistently in the wordpress volume:

              /home/login/data/wordpress/wp-config.php 

##### Database structure and tables
Key tables:
- `wp_users`: user accounts
- `wp_usermeta`: roles and permissions
- `wp_posts`: posts, pages, revisions, attachments
- `wp_options`: global configuration

###### Posts, pages, uploads and revisions
All WordPress content is stored in `wp_posts` table.  
This table includes:
- blog posts
- pages
- uploaded files
- revision history

Content types are differentiated using the `post_type` column:
- `post` -> blog post
- `page` -> page
- `revision` -> update history
- `attachment` -> uploaded files (images, media)

WordPress does not overwrite posts. Each update creates a new row with `post_type = revision`, preserving the edit history.  
The `post_author` field references `wp_users.ID`:  
- A positive value corresponds to the user who created the content: `1` usually correspondos to the admin user
- `0` indicates system-generated content

-----------------------------------

### Inspección y testeo
#### Docker useful commands
| Command | Purpose |
|----|----|
| `docker ps` | Lists running containers |
| `docker ps -a` | Lists all containers, including stopped ones |
| `docker logs` | Displays logs from the different containers |
| `docker inspect <container>` | Shows low-level container configuration and runtime details | 
| `docker inspect <container> | grep ExitCode` | PARA VER EXIT CODE: `0` -> salida limpia; `137` -> SIGKILL (mal) |

HABRIA QUE EXPLICAR QUÉ HACEN COMANDOS COMO:
- DOCKER KILL
- DOCKER STOP
- docker exec -it...
- AÑADIR COMANDOS QUE FALTAN

#### Acceso e inspeccion de contenedores
Containers can be accessed interactively using `docker exec`. This is useful for debugging, inspecting files and verifying runtime state.  
Examples:

        docker exec -it mariadb bash
        docker exec -it wordpress bash
        docker exec -it nginx sh

Once inside a container, you can:
- inspect configuration files
- run service-specific CLIs (e.g. `wp`, `mysql`)
- debug permissions and file paths

Poner ejemplis útiles de todo esto...

⚠️ PROBAR TODAS ESTAS COSAS!!! + añadir cosas concretas
- `ls /var/www/html` -> qué permite ver? este es el volumen persistente de wordpress, no?
- `env | grep MYSQL` -> ver variables de entorno
- comprobar wp-config.php...
- docker inspect <container> | grep ExitCode -> ESTO DEBERIA IR AQUÍ??

#### MariaDB database inspection
PONER TODO POR PASOS:
1. ACCEDER A MARIADB DESDE SU CONTENEDORE
2. MOSTRAR BASES DE DATOS, TABLAS, CONTENIDO
3. EJEMPLOS PRÁCTICOS

MariaDB data can be inspected from inside the database container.  
Because the database is not exposed to the host, access is done via `docker exec`.  

Example (inside mariadb container):

        mysql -u root -p 
        SHOW DATABASES;
        USE database;
        SHOW TABLES;

`mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE` -> INTENTAR CONECTAR DESDE WORDPRESS (PREVIAMENTE DOCKER EXEC -IT WORDPRESS BASH) A MARIADB  + añadir mas maneras de comprobar conexiones 

This is used to inspect the real persistent WordPress data stored in MariaDB. For see this in more detail [see Inspecting persistent data](#inspecting-persistent-data).

##### Accessing MariaDB
      
      docker exec -it mariadb bash
      mysql -u root -p

Root access is required for inspection.  
MariaDB users are defined using the format:

        'user'@'host'

In this project, the WordPress database user is created as:

      CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

- `%` is a wildcard meaning "any host on the network"
- This allows WordPress (running in another container) to connect
- However, `%` does not include `localhost`
- When running `mysql -u login -p`, MariaDB attempts `login@localhost`, which does not exists
- Therefore, WordPress connects successfully via Docker networking, while manual inspection must be done as `root`.

##### Inspecting databases and tables

      SHOW DATABASES;
      USE database;
      SHOW TABLES;

Typicall databases present:
- `mysql` -> system database
- `information_schema`
- `performance_schema`
- `sys`
- `test`
- `database`-> WordPress database

Main wordPress tables:
- `wp_users` -> users
- `wp_usermeta` -> roles and permissions
- `wp_posts`-> post, pages, revisions, attachments
- `wp_postmeta` -> post metadata
- `wp_comments`, `wp_commentmeta`
- `wp_options` -> global configuration
- `wp_terms`, `wp_term_taxonomy`, `wp_term_relationships`, `wp_termmeta`

Example inspections:

- PARA VER USUARIOS

      DESCRIBE wp_users;
      SELECT ID, user_login, user_email FROM wp_users;

- PARA VER PERMISOS/roles

      SELECT user_id, meta_key, meta_value
      FROM wp_usermeta
      WHERE meta_key LIKE '%capabilities%';


> How to change permissions from the WordPress contaniner:

>      wp user set-role user1 author --allow-root

> This updates:
>  - `wp_capabilities`
>  - `wp_user_level`


- PARA VER POSTS

      SELECT ID, post_title, post_type, post_status
      FROM wp_posts;

##### SQL inspection keywords
| Keyword | Purpose |
|---------|---------|
| SHOW | List databases or tables |
| USE | Select a database |
| DESCRIBE | Show table structure |
| SELECT | Query table contents |
| FROM | Specify source table |

#### Persistencia de volúmenes
Persistent data is stored using bind-mounted volumes.  
Useful commands:  

| Command | Purpose |
|----|----|
| `docker volume ls` | Lists Docker-managed volumes |
| `docker volume inspect <volume>` | Shows where a Docker-managed volume is stored |
| `du -sh /home/<login>/data/*` | Checks disk usage of persistent bind-mounted data |

PULIR:
- QUÉ VOLUMEN MONTA CADA SERVICIO
- QUÉ DATOS PERSISTEN
- QUÉ PASA EN MAKE FCLEAN...

- explicar más sobre du -sh /home/<login>/data...
- explicar qué datos persisten tras make down / clean / fclean...

#### Logs and debugging
WordPress does not store logs in MariaDB by default.  
Existing logs:
- PHP-FPM logs -> inside WordPress container (not persistent)
- MariaDB logs -> `/var/log/mysql` (not persistent)
⚠️ COMPROBAR ESTO!!! VER DONDE SE GUARDA
Persistent logging would require explicit configuration, which is not required for *Inception*. ❌❌ CREO QUE NO HACE FATLA HACER ESTO
añadir cosas
DÓNDE METO ESTO?
To verify clean shutdown:  

        docker inspect <container> | grep ExitCode

- `0` -> clean exit
- `137` -> SIGKILL (bad)


