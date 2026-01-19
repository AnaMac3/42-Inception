# 42-Inception - Developer Documentation

This document describes the technical architecture of the *Inception* project. It focuses on how the system is built, deployed, configured, persisted and inspected, and is intended for developers and evaluators.  

## Table of Contents
- [Set up the environment from scratch](set-up-the-environment-from-scratch)
  - [Virtual Machine setup (VirtualBox + Debian)](#virtual-machine-setup-virtualbox-debian)
  - [Installing Debian inside the VM](#installing-debian-inside-the-vm)
  - [Basic VM management](#basic-vm-management)
  - [Installing Docker, Docker Compose and build tools](#installing-docker-docker-compose-and-build-tools)
  - [Shared folders between host and VM](#shared-folders-between-host-and-vm)
  - [Persistent volumes](#persistent-volumes)
  - [Environment variables (`.env` file)](#environment-variables-env-file)
  - [Domain configuration and SSH tunneling](#domain-configuration-and-ssh-tunneling)
- [Build and launch the project using the Makefile and Docker Compose](#build-and-launch-the-project-using-the-makefile-and-docker-compose)
- [Relevant commands to manage the containers and volumes](#relevant-commands-to-manage-the-containers-and-volumes)
- [Project data storage and persistence](#project-data-storage-and-persistence)
  - [Persistent data locations](#persistent-data-locations)
  - [Volume mounting and container paths](#volume-mounting-and-container-paths)
  - [Persistent behaviour (`make` rules)](#persistent-behaviour-make-rules)
  - [WordPress-MariaDB data model](#wordpress-mariadb-data-model)
  - [Inspecting persistent data](#inspecting-persistent-data)

-----------------------------------------------------

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

**VM settings before installation**:  
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

### Installing Debian inside the VM
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

### Basic VM management
| Task | Command / Explanation |
|------|-----------------------|
| Disable graphical mode permanently | `sudo systemctl set-default multi-user.target`|
| Reboot VM | `reboot`|
| Get VM IP address | `ip a` |
| SSH from host | `ssh <login>@<IP_VM>` |
| Switch to root | `su -` |
| Return to user | `su - <login> |

⚠️ AÑADIR MÁS COSAS ÚTILES!!

Using `sudo` is recommended, but switching to root is also acceptable for this project.  ⚠️ ES NECESARIO DECIR ESTO?? QUÉ IMPLICA?

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

Example structure: ⚠️ EXPLICAR QUÉ HACE CADA COSA, QUÉ ES CADA COSA...

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
⚠️ QUIZÁS DEBA DE USAR SECRETS TB!!! PARA LAS CONTRASEÑAS, NO??

### Domain configuration and SSH tunneling
⚠️ PARA PODER ACCEDER DESDE LE NAVEGADOR DEL HOST A HTTPS://LOGIN.42.FR 
#### `/etc/hosts`  
Inside the VM:

      sudo nano /etc/hosts

Add:

    127.0.0.1 <login>.42.fr

Save with `Ctrl+O`, Enter, exit with `Ctrl+X`.  
Verify with:

       ping <login>.42.fr

If it responds from 127.0.0.1, it is well configurated.  

#### SSH tunneling (VM -> host browser)
Because the services run inside a VM, HTTPS traffic must be forwarded to the host browser.   
##### Windows / WSL

  - Pulsar tecla Windows y escribir block de notas
  - Click dcho, seleccionar Ejecutar como admin
  - Dentro de block de notas ir a Archivo -> Abrir
  - Ruta: C:\Windows\System32\drivers\etc
  - Cambiar filtro de documentos de texto txt a Todos los archivos
  - Abrir el arhcivo host
  - Añadir al final del archivo la línea: 127.0.0.1 amacarul.42.fr
  - Guardar y cerrar

In the shell:

      ssh -L 443:localhost:443 <login>@<IP_VM>

> Mientras esta ventana se mantenga abierta, el tunneling está activo (?)

Access:

    https://<login>.42.fr


##### 42 iMacs (no sudo) ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ -> HAY QUE HACER K TB SE PUEDA ACCEDER A HTTPS://LOGIN.42.FR DESDE EL NAVEGADOR
Port 443 cannot be used locally:

      ssh -L 8443:localhost:443 <login>@<VM_IP>

Access:

      https://localhost:8443

⚠️ SOCKS proxy alternative is still under investigation!! AVERIGUAR ESTO!!!

## Build and launch the project using the Makefile and Docker Compose
The Makefile orchestrates Docker Compose commands to simplify stack management.  
Ir provides a single interface to:
- build images
- start containers
- stop containers
- clean resources

Although no source code is compiled, `make` orchestrates the build of the Docker images and the deployment of the stack.
What `make` does is:

      docker compose build
      docker compose up -d

⚠️ PONER BIEN ESTA EXPLICACIÓN...

| Command | What it does |
|---------|--------------|
| `make` | builds docker images and the deployment of the stack - it does `docker compose build` and `docker compose up -d` |
| `make stop` | Stops the containers, sin eliminar ni los contenedores ni los volúemenes |
| `make down` | Para y elimina los contenedores, redes y los volúmenes interos de docker-compose (los declarados dentro de docker-compose) (QUÉ VOLÚMENES SON ESTOS?), pero conserva los datos persistentes en las carpetas montadas en el host. Las imágenes no se eliminan. ¿QUÉ IMPLICA QUE NO SE ELIMINEN LAS IMÁGENES? ¿QUE SI SE HACEN CAMBIOS EN EL SETUP.SH DE LAS DIFERENTES APPS, NO SE VERÁN REFLEJADOS O ALGO ASÍ? |
| `male clean` | Para y elimina contenedores, redes y volúmenes interos de Docker, pero no borra los volúemenes que datos que creamos en `/home/<login>/data/...`. También elimina las imágenes generadas. |
| `make fclean` | Hace `clean` y borra completamente los datos persistentes en `/home/<login>/data/...` y hace un `docker system prine -a --force`: ⚠️ esto resetea completamente el proyecto. |

## Relevant commands to manage the containers and volumes
⚠️⚠️⚠️
Common commands:

         docker ps
         docker logs nginx
         docker logs wordpress
         docker logs mariadb
         
         docker volume ls
         docker compose down

- Entrar a un contenedor:

        docker exec -it mariadb bash
        docker exec -it wordpress bash

  EXPLICAR PARA QUÉ SE HACE ESTO... UNA VEZ CONECTADO PUEDES HACER QUÉ MÁS COSAS?

- Conectarte a MariaDB

          mysql -u root -p database

      PARA QUÉ SE HACE ESTO? PARA ENTRAR A LA BASE REAL DE WORDPRESS
          

⚠️  CREO QUE HABRIA QUE EXPLICAR MÁS COMANDOS... hacer una lista ordenada y coherente, con sentido.  
ALGUNOS DE ESTOS ESTÁN RECOGIDOS DIRECTAMENTE EN EL MAKEFILE -> decir cuales...
EXPLICAR QUÉ HACE CADA UNO?? CREO QUE TENGO MÁS EXPLICACIONES EN README NORMAL '??  
QUIZÁS DEBERIA DIFERENCIAR ENTRE COMANDOS DE DOCKER COMPOSE Y COMANDOS DE DOCKER A SECAS?  o igual los comandos de docker compose ya se han explicado en el apartado anterior de build and launch the project...??  

## Project data storage and persistence
### Persistent data locations
All persistent data is stored explicitly on the VM filesystem: 

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

- MariaDB stores its database files in the mariadb volume
- WordPress stores uploads, plugins, and themes in `wp-content`

This are **Docker bind mounts**, defined in `docker-compose.yml`, and ensure that data survives container restarts and rebuilds.  
As long as these directories are preserved, all WordPress content, configuration and database state survive container restarts and rebuilds.  

### Volume mounting and container paths
The persistent volumes are mounted as follows:  
#### MariaDB
- Host path: `/home/login/data/mariadb`
- Container path: `/var/lib/mysql`
- This directory contains all MariaDB database files, meaning:
  - WordPress users
  - Roles and permissions
  - Posts, pages, revisions
  - Comments
  - WordPress options
  In short: all logically important WordPress data.
#### WordPress
- Host path: `/home/login/data/wordpress`
- Container path: `/var/www/html`
- This directory contains:
  - WordPress core
  - `wp-config.php`
  - Themes and plugins
  - Uploads
  This ensures WordPress content and configuration persist across restarts.

⚠️ COMPROBAR TODOS ESTOS ARCHIVOS... REPASAR  
ABAJO: ESPECIFICACIONES SOBRE CÓMO FUNCIONA LA CONFIG Y TAL

### Persistent behaviour (`make` rules)
⚠️ AÑADIR CÓDIGO DEL MAKEFILE PARA VER CÓMO ESTOY HACIENDO TODO ESTO ⚠️ ⚠️ 
- `make down`:
  - Stops and removes containers
  - Persistent data remains: volumes under `/home/login/data/...` are untouched
- `make clean`:
  - Stops and removes:
    - containers
    - Docker networks
    - Docker-managed volumes
    - built images
  - Does not delete the bind-mounted directories / the persistent volumes
- `make fclean`:
  - Removes everything:
    - containers
    - images
    - networks
    - persistent data directories

⚠️ **Important distinction:**  
`clean`preserves data, `fclean` deletes it entirely.

### WordPress-MariaDB data model
#### WordPress configuration: `wp-config.php`  
`wp-config.php` is the central configuration file that links WordPress with its database and define its runtime behaviour. In this project, it is generated automatically by `wp-clip` in the WordPress `setup.sh` script and stored persistently in the wordpress volume.    
##### Location

          /home/login/data/wordpress/wp-config.php 

##### Role in the WordPress-MariaDB architecture
`wp-config.php` does not store content itself, but it defines how WordPress accesses and interprets persistent data stored in MariaDB.  
It contains:
1. Database connection settings
   These values allow WordPress to connect to the MariaDB container over the Docker network:
   - `DB_NAME`
   - `DB_USER`
   - `DB_PASSWORD`
   - `DB_HOST`  
   WordPress connects to MariaDB via the Docker network, not via `localhost`.

2. Table prefix: `wp_`
3. Security keys and salts
   Used for:
   - authentication
   - cookies
   - session security
   These are generated automatically by `wp-cli` during setup.
4. Debug configuration
   By default, `WP_DEBUG` is not enabled in this project.  
   If enabled, it would:
   - show PHP errors
   - show warnings and notices
   - help detect plugin or SQL errors  
   
   Optional configuration (not required for *Inception*):
   - In `setup.sh`, after `wp config create` block:

             wp config set WP_DEBUG true --allow-root
             wp config set WP_DEBUG_LOG true --allow-root
             wp config set WP_DEBUG_DISPLAY false --allow-root
     
   - ⚠️ Since `wp_config.php` is persistent, existing volumes would need to be removed for this change to take effect.

5. WordPress bootstrap
   At the end of the file:

           define('ABSPATH', __DIR__ . '/');
           require_once ABSPATH . 'wp-settings.php';
   
   This loads and initializes the WordPress core.

#### Database overview
All WordPress logical data is stored in a single MariaDB database, which persists independently from container lifecycles. This includes users, roles, content, configuration and metadata.  

#### Users and roles (data model)
User accounts are stored in the `wp_users` table.  
Each user entry contains basic identity information such as:
- login name
- email
- hashed password
Additional information such as roles and permissions is stored in the related table `wp_usermeta`.
Roles are stored under the `wp_capabilities` meta key as PHP serialized data, for example:

      a:1:{s:13:"administrator";b:1;}
      a:1:{s:10:"subscriber";b:1;}

#### Posts, pages, uploads and revisions
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
The `post_author` filed references `wp_users.ID`:  
- A positive value corresponds to the user who created the content: `1` usually correspondos to the admin user
- `0` indicates system-generated content

#### Global WordPress configuration
Global WordPress condiguration is stored in the `wp_options` table.  
This table includes:
- site URL
- active theme
- enabled plugins
- internal WordPress settings

### Inspecting persistent data
How to verify and inspect the persistent data described above.  

#### Accessing MariaDB
      
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

#### Inspecting databases and tables

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

#### SQL inspection keywords
| Keyword | Purpose |
|---------|---------|
| SHOW | List databases or tables |
| USE | Select a database |
| DESCRIBE | Show table structure |
| SELECT | Query table contents |
| FROM | Specify source table |

#### Logs
WordPress does not store logs in MariaDB by default.  
Existing logs:
- PHP-FPM logs -> inside WordPress container (not persistent)
- MariaDB logs -> `/var/log/mysql` (not persistent)
⚠️ COMPROBAR ESTO!!! VER DONDE SE GUARDA
Persistent logging would require explicit configuration, which is not required for *Inception*. ❌❌ CREO QUE NO HACE FATLA HACER ESTO








