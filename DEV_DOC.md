# 42-Inception - Developer Documentation

This document describes the technical architecture of the *Inception* project. It focuses on how the system is built, deployed, configured, persisted and inspected. It is intended for developers and evaluators.  

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
  - [Environment variables (`.env` file)](#environment-variables-env-file)
  - [Secrets](#secrets)
  - [Domain configuration and SSH tunneling](#domain-configuration-and-ssh-tunneling)
    - [`/etc/hosts`](#etchosts)
    - [SSH tunneling and SOCKS proxy (VM to host browser)](#ssh-tunneling-and-socks-proxy-vm-to-host-browser)
      - [Windows / WSL host](#windows--wsl-host)
      - [42 iMacs / Linux (no sudo)](#42-imacs--linux-no-sudo)
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
  - [Project Structure](#project-structure)
  - [Services and Dockerfiles](#services-and-dockerfiles)
    - [MariaDB](#mariadb)
    - [WordPress](#wordpress)
    - [NGINX](#nginx)
  - [Docker Compose Orchestration](#docker-compose-orchestration)
    - [Service, internal network, and volumes](#service-internal-network-and-volumes)
    - [Startup flow and dependencies](#startup-flow-and-dependencies)
    - [Key `docker-compose.yml` directives](#key-docker-composeyml-directives)
  - [Data Persistence](#data-persistence)
    - [Persistent data locations](#persistent-data-locations)
    - [Volume contents](volume-contents)
    - [Relation with `make down / clean / fclean`](#relation-with-make-down--clean--fclean)
  - [WordPress - MariaDB Data Model](#wordpress---mariadb-data-model)
    - [`wp-config.php`](#wp-configphp)
    - [Database structure and tables](#database-structure-and-tables)
- [Inspection and testing](#inspection-and-testing)
  - [Infrastructure and clean state verification](#infrastructure-and-clean-state-verification)
  - [Container access (interactive debugging)](#container-access-interactive-debugging)
  - [Container state and Debug access](#container-state-and-debug-access)
  - [Network verification](#network-verification)
  - [MariaDB verification](#mariadb-verification)
  - [WordPress testing](#wordpress-testing)
  - [NGINX + HTTPS testing](#nginx-https-testing)
  - [Persistent layer test](#persistent-layer-test)
  - [Restart and Resilience](#restart-and-resilience)
 
--------

## Set up the environment from scratch

This sections explains how to prepare a complete development environmet to run the *Inception* project from scratch.  
The stack is deployed inside a **Debian Virtual Machine** using **Docker and Docker Compose**, with persistent volumes stored on the VM filesystem.  
The setup includes:
- VirtualBox virtual machine
- Debian installation
- Network and SSH access
- Docker and Docker Compose
- Shared folders (optional)
- Environment variables (`.env`)
- Secrets
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
- Name: `inception`
- Folder: `sgoinfree` (on 42 computers)
- OS: Linux
- OS Distribution: Debian
- OS Version: Debian (64-bit)
- RAM: minimum 2048 MB (recommended 4096 MB)
- Number of CPUs: 2

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
- Mount point: `/home/login/inception` 
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

### Environment variables (`.env` file)
The `.env` file defines all configuration values used by Docker Compose and the containers.  
- It contains no executable code
- It must NOT be committed to version control
- It avoids hardcoding configuration values in source files
- It must be located in `./srcs` 

Example:  

      DOMAIN_NAME=<login>.42.fr

      MYSQL_HOSTNAME=mariadb
      MYSQL_DATABASE=database
      MYSQL_USER=<login>
      MYSQL_ROOT_USER=root
      
      WORDPRESS_TITLE=MyWebsite
      WORDPRESS_ADMIN_USER=boss
      WORDPRESS_ADMIN_EMAIL=boss@inception.fr 
      WORDPRESS_USER=user1
      WORDPRESS_USER_EMAIL=user1@inception.fr

Environment variables allow containers to be configured dynamically without modifying source files.  

### Secrets
Docker secrets is a file securely mounted inside a container **at runtime only**, specifically designed to sotre confidential information.    
Docker mounts secrets inside the container at:

        /run/secrets/<secret_name>

Applications reads credentials directly from these fies instead of environmental variables.  
Secrets directory structure in this project:

            inception/secrets/
              ├── mysql_root_password.txt
              ├── mysql_password.txt
              ├── wp_admin_password.txt
              └── wp_user_password.txt

The structure of the project must be like [this](#project-structure).   
Each fie contains only one password on a single line.  
Docker Compose mounts these files securely into the containers during startups.  

### Domain configuration and SSH tunneling
Because the project runs inside a virtual machine, additional configuration is requried to access the HTTPS website from the host browser.  
This section explains how to map the custom domain locally and forward HTTPS traffic from the VM to the host using SSH tunneling.  

#### `/etc/hosts`
Open the VM terminal and edit the hosts file:

      sudo nano /etc/hosts

Add the following line:

    127.0.0.1 <login>.42.fr

Save with `Ctrl+O`, press Enter, exit with `Ctrl+X`.  
Verify that the domain resolves inside the VM:

       ping <login>.42.fr

If it responds from `127.0.0.1`, the domain is configurated correctly inside the VM.  

#### SSH tunneling and SOCKS proxy (VM to host browser)
Since the services run inside a VM, HTTPS traffic cannot be accessed directly from the host browser. To reach the website at `https://login.42.fr`, use **SSH tunneling** if you have sudo privileges, or a **SOCKS proxy** if you do not (42 iMacs).  

##### Windows / WSL host  
1. Edit the host machine's `hosts` file (`C:\Windows\System32\drivers\etc\host`) as Administrator:
   - Open Notepad as Administrator
   - File -> Open
   - Navigate to: `C:\Windows\System32\drivers\etc`
   - Change file filtero to *All files*
   - Open `hosts`
   - Add: 

        127.0.0.1 <login>.42.fr

   - Save and close

2. Forward port 443 from the VM to the host:

      ssh -L 443:localhost:443 <login>@<IP_VM>

> ⚠️ The tunnel remains active while the SSH session is open. 

3. Access from the host browser:

        https://<login>.42.fr


##### 42 iMacs / Linux (no sudo)  
Because you cannot bind to port 443 without sudo, you must use a **SOCKS proxy** to access the VM services without forwarding specific ports:  
1. Open a terminal on the host machine and run:

        ssh -D 8080 <login>@<IP_VM>

This opens a SOCKS5 proxy on `localhost:8080`. Keep this terminal open while browsing.  
**What is a SOCKS proxy?**  
A SOCKS proxy acts as a tunnel for your network traffic. Your browser sends requests to `localhost:8080`, which are then forwarded through the VM. This allows your hot browser to access the HTTPS website exactly as if you were inside the VM, without needing to forward specific ports.  

2. Configure Firefox (or another browser) to use the SOCKS proxy:
   - Settings -> Network -> Manual proxy configuration
   - SOCKS Host: `localhost`
   - Port:`8080`
   - SOCKS v5
   - Enable "Proxy DNS when using SOCKS v5"

3. Access the project domain in Firefox:

          https://login.42.fr


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

### Makefile shortcuts
The Makefile wraps the Docker Compose commands above and defines the project's persistence policy.  
| Makefile command | Description |
|---------|--------------|
| `make` | Creates required host directories for persistent storage, sets correct permissions (required for MariaDB UID alignment), builds Docker images if needed, and starts the full stack in detached mode.|
| `make stop` | Stops all running containers without removing them. Containers, networks, images, and volumes remain intact. |
| `make down` | Stops and removes containers and Docker Compose networks. Persistent data stored in bind-backed host directories is preserved. Docker volumes are not removed. Images are not deleted. |
| `make clean` | Stops and removes containers, networks, and project images.Persistent data stored in bind-backed host directories is preserved. |
| `make fclean` | Performs `clean`, then deletes all persistent host data directories, removes all Docker volumes, and runs `docker system prune -a --force`. This fully resets the project to a fresh state.|


⚠️ **Implication regarding images:**  
If images are not removed (`make down`), changes in `Dockerfile` or `setup.sh` will not be applied unles `docker compose build` (or `make`) is run again.  

## Theory - Fundamental Concepts
This section explains the theoretical foundations required to understand how the *Inception* project works internally.  
It focuses on **how Docker containers behave**, how their lifecycle is managed, and why certain design choices are mandatory to ensure correctness, stability, and compliance with the subject.  

### Container execution model
This project uses a **multi-container architecture**, where each service runs inside its **own isolated container** with a **single responsibility**.  
Containers communicate through a **private Docker bridge network**.    
Persistent application state is stored outside containers using Docker volumes configured with bind-backed storage on the host system.   

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
> **Images define infrastructure - containers manage state**

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
Docker containers are designed to run **one main process**.  
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
2. Waits a short grace period
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

##### What happens if PID 1 exits
If PID 1 exits:
- The container stops immediately
- Docker considers the container terminated
- Restart policies may trigger a restart
This is why PID 1 must always be the real service.  


## Applied Architecture in Inception
This section describes **how the theoretical Docker concepts explained earlier are applied concretely in the Inception project**.  
It focuses on the **practical implementation choices**, the role of each service, how containers are built and started, how Docker Compose orchestrates the system, and how data persistence is ensured.  

### Project Structure

             inception/
                  │
                  ├── Makefile
                  ├── README.md
                  ├── DEV_DOC.md
                  ├── USER_DOC.md
                  ├── secrets/
                  │    ├── mysql_root_password.txt
                  │    ├── mysql_password.txt
                  │    ├── wp_admin_password.txt
                  │    └── wp_user_password.txt
                  └── srcs/
                      ├── .env
                      ├── docker-compose.yml
                      └── requirements/
                          ├── nginx/
                          │   ├── Dockerfile
                          │   └── conf/
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

### Services and Dockerfiles
Each service runs in its own container, built from a dedicated Dockerfile.  
#### MariaDB 
##### Build time
During image construction, the MariaDB Dockerfile prepares the **database infrastructure**:
- Installs the MariaDB server packages
- Copies a custom MariaDB configuration file (`my.conf`)
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
- MariaDB is launched **temporarily in background** (only used during initialization, terminted before the final foreground exeuction begins)  
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
Application-specific configuration is handled by WordPress through `wp-config.php`, not by PHP-FPM.  
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
- environment variable preservation (`clear_env = no`)   
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

          CMD ["nginx", "-g", "daemon off;"]

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
Three services compose the stack:
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

Two **persistent bind-backed Docker volumes** are defined:

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
- WordPress implements an explicit wait mechanism for MariaDB availability (for example, `mysqladmin ping`)  
- NGINX does not require such a mechanism, as it only needs to listen on the corresponding port. When a PHP request is received, NGINX attempts to forward it to `wordpress:9000`. If WordPress is not yet ready, a temporary error may occur until the service becomes available.

##### Key `docker-compose.yml` directives

| Keyword | Description |
|-----|------|
| `services` | Defines the containers that compose the application (`nginx`, `wordpress`, `mariadb`). |
|  `build` | Specifies the path to the Dockerfile used to build the image. |
| `container_name` | Assigns a specific name to the container created from the service. |
| `env_file` | Specifies a file containing environment variables that are injected into the container at runtime. |
| `image` | Specifies an existing image to use. In *Inception*, custom images are built instead, as required by the subject. |
| `ports` | Maps ports from the host to the container (`HOST_PORT:CONTAINER_PORT`) |
| `volumes` | Defines persistent storage using Docker volumes. |
| `depends_on` | Defines startup order between services, but does not ensure service readiness. |
| `networks` | Specifies the networks the container is connected to. |
| `restart` | Defines the container restart policy in case of failure. |
| `bridge` driver | Allows containers on the same host to communicate through an isolated internal network. |


#### Data Persistence
##### Persistent data locations
All persistent data is stored explicitly on the VM filesystem: 

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

- MariaDB stores its database files in a Docker volume that is **bind-backed** to `/home/<login>/data/mariadb` 
- WordPress stores its core files, uploads, plugins, and themes in a Docker volume **bind backed** to `/home/<login>/data/wordpress`  
- These **bind-backed Docker volumes** ensure data survives container removal, rebuilds, and restarts.  

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
    - built images
  - Does not delete the bind-backed directories nor docker volumes
- `make fclean`:
  - Removes everything:
    - executes `clean`
    - explicitly deletes all persistent bind-backed data and Docker volumes
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

## Inspection and testing
This section explains how to **inspect, verify, and debug** the running *Inception* infrastructure.  

### Infrastructure and clean state verification
- Before starting the project, ensure a clean environment:

        make fclean

- Verify no leftover resources exist:

      docker ps -a
      docker images
      docker volume ls
  
  Expected result:
  - No project container (neither stopped ones)
  - No project images
  - No project volumes
  
- Start the project

      make

- Verify created resources:

      docker ps

  Expected containers:
  - `mariadb`
  - `wordpress`
  - `nginx`

- Check network:

      docker network ls

  Expected:
  - `inceptionnet` (bridge network)    

- Check volumes:

      docker volume ls

  Expected:
  - MariDB volume
  - WordPress volume

- Check host directories_

      ls -l /home/<login>/data

  Expected:
  - `mariadb/`
  - `wordpress/`
  And must contain data.

### Container state and Debug access

        docker inspect <container>
        docker exec -it <container> bash

Used to verify:
- runtime files
- mounted storage
- secrets
- environment variables

### Network verification
All containers must communicate through the same Docker bridge network.  

      docker network inspect inceptionnet

Expected:
- All containers attached  

Test internal DNS resolution:
- Docker provides an embedded DNS system that allows containers to resolve each other by service name instead of IP

      docker exec wordpress getent hosts mariadb
      docker exec nginx getent hosts wordpress

  Expected:
  - Returns internl Docker IPs (172.x.x.x mariadb)
  - No manual IP configuration required
  - Services resolves each other using containers/services names

### MariaDB verification
- Access MariaDB:

        docker exec -it mariadb bash
        mysql -u root -p
 
> User authentication model:
> MariaDB users are defined using `'user'@'host'`.
> In this project:

>        CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '...';
>        CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '...';

> Meaning:
>  - `'user'@'%'` -> allows connections from other containers on the Docker network (WordPress)
>  - `'user'@'localhost'` -> allows local inspection from inside the MariaDB container.

> - Root vs application user:
>  - Root user is used for administration (manage users, inspect system tables, full database access)

>           mysql -u root -p

>  - Application user: access only the WordPress database.

>          mysql -u <user> -p
 
 >   Check privileges:

>        SHOW GRANTS FOR 'user'@'localhost';
 
- Basic database checks:

        SHOW DATABASES;
        USE database;
        SHOW TABLES;

  Typicall databases:
  - `mysql` -> users and privilege system tables
  - `information_schema` -> database metadata
  - `performance_schema`-> performance metrics
  - `sys` -> diagnostic views
  - `test` -> default testing database
  - `database`-> WordPress database
 

- Important WordPress tables (`database`):
  - `wp_users` -> users
  - `wp_usermeta` -> roles and permissions
  - `wp_posts`-> post, pages, revisions, attachments
  - `wp_postmeta` -> post metadata
  - `wp_comments`, `wp_commentmeta`
  - `wp_options` -> global configuration
  - `wp_terms`, `wp_term_taxonomy`, `wp_term_relationships`, `wp_termmeta`
 
- Example inspections:
  - List users:

          DESCRIBE wp_users;
          SELECT ID, user_login, user_email FROM wp_users;

  - View roles:

          SELECT user_id, meta_key, meta_value
          FROM wp_usermeta
          WHERE meta_key LIKE '%capabilities%';

  - View posts:
 
        SELECT ID, post_title, post_type, post_status
        FROM wp_posts;  


### WordPress testing
- Enter the WordPress container:

        docker exec -it wordpress bash

- Inspect WordPress directory:

      ls /var/www/html

  This directory is bind-backed from the host:

      /home/<login>/data/wordpress

  It contains:
  - WordPress core file
  - `wp-config.php`
  - themes
  - plugins
  - uploads
  - configuration files  

- Check uploads:

        ls /var/www/html/wp-content/uploads

- Check users:

      wp user list --allow-root

- Modify roles using WP-CLI:

      wp user set-role <username> <role> --allow-root
  
  Default roles:
  - `administrator` -> full access
  - `editor` -> manage posts/pages
  - `author` -> write own posts
  - `contributor` -> write posts but cannot publish
  - `subscriber` -> read only

  Verify the change with:

        wp user get <username> --field=roles --allow-root
  
- Check WordPress configuration:

        cat var/www/html/wp-config.php

  Check:
  - DB host =`mariadb`
  - database name
  - database user
  - table prefix

  > ⚠️ `wp config create` generates `wp-config.php` using provided environment variables. Even when the password originates fron Docker secrets, the generated file stores it as a PHP constant. Therefore:
  > - Secrets protect passwords during container startup
  > - WordPress requires the password in plaintext at runtime
  > - The password becamos embedded in `wp-config.php`   

### NGINX + HTTPS testing
- Check service listening:

        nc -zv localhost 443

  Expected:
  - Success on 443
  - Failure on other ports

- Test browser

      https://<login>.42.fr

- Verify TLS certificate:
  The browser will show a security warning, because the project  uses a self-signed TLS certificate.
  This is expected behavior in a development environment.
  To validate TLS is correctly configured:
  1. Access the site using HTTPS:

           https://<login>.42.fr
     
  3. Confirm that:
     - The connection uses HTTPS (not HTTP)
     - The certificate is present
     - The browser warns about trust (expected)

  4. CLI verification:

           openssl s_client -connect localhost:443 -servername <login>.42.fr

     Expected:
     - TLS handshake is successful
     - Certificate is shown (self-signed is valid) 


- Enter the NGINX container:

          docker exec -it nginx bash

- Inspect logs:

          cat /var/log/nginx/acces.log
          cat /var/log/nginx/error.log

  Used to verify:
  - incoming HTTPS requests
  - TLS termination
  - FastCGI forwarding to WordPress

      
### Persistent layer test
- Check host storage

      ls /home/<login>/data

  Expected:
  - data persist

- Verify Docker volumes

        docker volume ls
        docker volume inspect <volume_name>

- Persistent test procedure:
  1. Create WordPress post/user
  2. Restart the stack
  
            make down
            make
  
  3. Verify data still exists

- Persistent storage mapping:

  | Service | Host Path | Container Path / Docker volume |
  |-----|-----|-----|
  | WordPress | `/home/login/data/wordpress` | `/var/www/html` |
  | MariaDB | `/home/login/data/mariadb` | `var/lib/mysql` |

  
### Restart and Resilience

      docker compose restart

  or

      make down
      make

  Check:
  - Service auto-restat
  - no data loss

- Verify restart policy:

        docker inspect nginx | grep RestartPolicy

  Expected:
  - `always`


### Security Checks
 
- Secrets verification

        docker exec mariadb ls /run/secrets

  Expected:
  - password files

- Verify secrets are NOT exposed as environment variables:

        docker inspect mariadb | grep -i password

  Expected:
  - no passwords visible.

### Clean Shutdown Verification
- Stop containers:  

        docker stop <container>

- Then, inspect container:

              docker inspect <container> | grep ExitCode

  Exit codes:
  - `0` -> clean shutdown
  - `137` -> Forced stop (SIGKILL)
 
- Start the container again:

        docker start <container>


