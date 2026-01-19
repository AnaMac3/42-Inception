# 42-Inception - Developer Documentation

⚠️ CÓMO TIENE QUE SER: contiene lo técnico pesado. Indicar cómo está construido, cómo se despliega y cómo se mantiene.

## Table of Contents
- [Set up the environment from scratch](set-up-the-environment-from-scratch)
  - [Virtual Machine setup (VirtualBox + Debian)](#virtual-machine-setup-virtualbox-debian)
  - [Creating the Virtual Machine](#creating-the-virtual-machine)
  - [Installing Debian inside the VM](#installing-debian-inside-the-vm)
  - [Basic VM management](#basic-vm-management)
  - [Installing Docker, Docker Compose and build tools](#installing-docker-docker-compose-and-build-tools)
  - [Shared folders between host and VM](#shared-folders-between-host-and-vm)
  - [Persistent volumes](#persistent-volumes)
  - [Environment variables (`.env` file)](#environment-variables-env-file)
  - [Domain configuration and SSH tunneling](#domain-configuration-and-ssh-tunneling)
- [Build and launch the project using the Makefile and Docker Compose](#build-and-launch-the-project-using-the-makefile-and-docker-compose)
- [Use relevant commands to manage the containers and volumes](#use-relevant-commands-to-manage-the-containers-and-volumes)
- [Identify where the project data is stored and how it persist](#identify-where-the-project-data-is-stored-and-how-it-persist)

-----------------------------------------------------

## Set up the environment from scratch

This sections explains how to prepare a complete development environmet to run the *Inception* project from scratch.  
The stack is deployed inside a **Debian Virtual Machine** using **Docker and Docker Compose**, with persistent volumes stored on the host filesystem.  
The setup includes:
- VirtualBox virtual machine
- Debian installation
- Network and SSH access
- Docker and Docker Compose
- Shared folders (optional)
- Persistent volumes
- Environment variables (`.env`)
- Domain configuration and SSH tunneling
- Platform-specific notes (Windows / WSL / 42 iMacs -> TENER EN CUENTA QUE EN 42 SÍ, SON IMACS, PERO USAMOS LINUX!!)

### Virtual Machine setup (VirtualBox + Debian)
#### Virtualization tool
The project is developed inside a virtual machine created with [Oracle VirtualBox](https://www.softonic.com/descargar/virtualbox/windows/post-descarga?dt=internalDownload)

> ⚠️ On 42 computers, the VM disk is usually stored in `sgoinfree` to avoid quota issues ⚠️COMPROBAR QUÉ SIGNIFICA ESTO EXACTAMENTE

#### Debian ISO
A [Debian GNU/Linux ISO](https://www.debian.org/download.es.html) is used to install the operating system inside the VM.

Clarification:
- The Debian OS installed in the VM is **independent** from the Debian/Alpine images used inside Docker containers.
- The ISO is only used to install the host operating system of the VM.

> La **ISO Debian** es un archivo de imagen de disco que contiene todo el sistema de instalación del sistema operativo **Debian GNU/Linux**. Una ISO es un archivo que representa el contenido de un CD/DVD; en lugar de grabarlo en un disco físico, se puede montar en una VM como si fuera un disco real.
  
>   - ¿Qué hace la ISO en la VM?
     - Arranca la VD desde la ISO, igual que si arrancaras un PC desde un DVD
     - Inicia el instalador de Debian, que te guía para instalar el SO dentro del disco virtual de la VM
     - Permite particionarl el disco virtual, seleccionar el entorno de escritorio, instalar paquetes básicos, configurar red, usuarios, etc

### Creating the Virtual Machine
In VirtualBox -> `New`:
- Name: inception
- Folder: sgoinfree (??)
- ISO Image: --
- OS: Linux
- OS Distribution: Debian
- OS Version: Debian (64-bit)
- RAM: minimum 2048 MB, recommended 4096 MB
- Number of CPU: 2

> Using 2 CPUs is a reasonable compromise: enough for Docker without overloading the host.

**VM settings before installation**:  
System -> Motherboard
- Boot order: Optiocal first (to boot from ISO)
- Chipset: default  
System->Processor  
- CPUs: 2 (or more if available)
- Enable PAE/NX
  - This allows access to extended CPU features and is recommended for modern Linux kernels.  
Display
- Video memory: 16-64 MB (no critical, no GUI required)
Storage
- Attach the Debian ISO as an optical disk
- The virtual hard disk (`.vdi`) is used for the system installation

      > Controlador: SATA, hacer click en el icono del CD y selecciona **elegir un archivo de disco óptico virtual** y apunta a la ISO de Debian que necesitas descargar. Tengo que tener el .vdi como Hard Diskj y el debian como optical disk

Network
- Adapter 1: Bridged Adapter
  - This allows the VM to obtain an IP address on the local network
  - Required to access the VM via SSH from the host

### Installing Debian inside the VM
Start the VM and follow the Debian installer:
- Language, keyboard, timezone
- Partitioning: *Guided - use entire disk*
- Hostname: `debian-inception` (example)
- Domain name: can be left empty or set to `<login>.42.fr`
- Root password: set a secure password //blablapassword
- User:
  - Username: 42 login
  - Password: user password //passuser
- Software selection:
  - Do not install GNOME or any graphical desktop (optional - YO NO LO INSTALO PORQUE ME LIA... PERO CREO QUE NO ESTÁ PROHIBIDO)
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

> Using `sudo` is recommended, but switching to root is also acceptable for this project. ¿??¿¿?¿

### Installing Docker, Docker Compose and build tools
Inside the Debian VM:

    sudo apt update
    sudo apt install -y docker.io docker-compose

Install also other essentials such as make, gcc...

    sudo apt install build-essential

Enable Docker and add the user to the docker group:

    sudo systemctl enable --now docker
    sudo usermod -aG docker <login>

Log out and log back in (or reboot), then verify:

    docker --version
    docker compose version
    groups <login>

### Shared folders between host and VM
Shared folders allow editing files on the host while running them inside the VM. YO LO HE HECHO SOBRE TODO PORQUE EL REPO DE GITHUB NO LO PUEDO CREAR EN LA VM... NO? SE ME CREA EN LOCAL... O NO ESTOY SEGURA...

Steps:  
- VM Settings -> Shared Folders
- Folder Path: local host directory
- Mount point: `/home/<login>/inception´
- Enable auto-mount and make permanent

Inside the VM:

      sudo mkdir -p /home/<login>/inception
      sudo mount -t vboxsf -o uid=$(id -u),gid=$(id -g) inception /home/<login>/inception

Add user to `vboxsf` group:

    sudo usermod -aG vboxsf $USER

Guest Additions must be installed for shared folders to work correctly:
En la ventana de la VM -> menú superior -> Devices -> Insert Guest Aditions CD image
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
-

### Persistent volumes
Persistent data is stored on the VM filesystem and mounted into containers.

       mkdir -p /home/<login>/data/wordpress
       mkdir -p /home/<login>/data/mariadb

       #Ajustar permisos para que Docker pueda escribir
       sudo chown -R <login>:<login> /home/<login>/data

These directories are later mounted as Docker volumes  
FALTA EXPLICAR PERMISOS Y MONTAJE! AQUÍ SOLO DIGO QUE SE CREAN LOS DIRECTORIOS Y QUÉ SIGNIFICAN ESTOS PERMISOS?? NO FALTA ALGO PARA INDICAR QUE SON PERSISTENTES?? SU PERSISTENCIA DEPENDE DE QUE NO SE BORREN EN EL MAKEFILE, NO? DEPENDE DE QUE HACER DOCKER COMPOSE DOWN BORRA LOS CONTAINERS PERO NO ESTOS VOLÚEMENS... DEBERÍA EXPLICAR ESO AQUÍ? MÁS ADELANTE HAY UN APARTADO QUE ES IDENTIFY WHERE THE PROJECT DATA IS STORED AND HOW IT PERSIST... NO DEBERIA IR TOOD JUNTO?

### Environment variables (`.env` file)
The `.env` file defines all configuration valeus used by Docker Compose and the containers.  
- It contains no executable code
- It must NOT be committed to version control
- It avoids hardcoding secrets in configuration files

Indicar que este arhcivo .env tiene que estar en el directorio ./srcs.  

My example:

      #Dominio que usará NGINX para TLS y wordpress (explicar ...)
      DOMAIN_NAME=amacarul.42.fr

      #Explicar cada cosa!
      MYSQL_HOSTNAME=mariadb
      MYSQL_DATABASE=database
      MYSQL_USER=amacarul
      MYSQL_PASSWORD=***
      MYSQL_ROOT_USER=root
      MYSQL_ROOT_PASSWORD=***
      
      WORDPRESS_TITLE=amacarulsWebsite
      WORDPRESS_ADMIN_USER=boss
      WORDPRESS_ADMIN_PASSWORD=***
      WORDPRESS_ADMIN_EMAIL=boss@inception.fr #llego a usar el mail? para qué lo necesito?
      WORDPRESS_USER=user1
      WORDPRESS_USER_EMAIL=user1@inception.fr
      WORDPRESS_USER_PASSWORD=***

¿Por qué se usa `.env` en Inception?  
- Porque no hay qu hardcodear contraseñas
- La configuración tiene que ser dinámica
- Para poder cambiar valores sin tocar el código.

> Note: Docker secrets would be more secure, but environment variables are acceptable for Inception. ???? TENGO QUE AÑADIR SECRETS !!!

### Domain configuration and SSH tunneling
`/etc/hosts`  
Inside the VM:

      sudo nano /etc/hosts

Add:

    127.0.0.1 <login>.42.fr

Save with `Ctrl+O`, Enter, exit with `Ctrl+X`.  
Verify with:

       ping <login>.42.fr

Si responde desde 127.0.0.1, está bien configurado.

#### SSH tunneling (VM -> host browser)
Because the services run inside a VM, HTTPS traffic must be forwarded to the host browser.   
##### Windows / WSL
⚠️ PARA PODER ACCEDER DESDE EL NAVEGADOR PONIENDO HTTPS://LOGIN.42.FR::

  - Pulsar tecla Windows y escribir block de notas
  - Click dcho, seleccionar Ejecutar como admin
  - Dentro de block de notas ir a Archivo -> Abrir
  - Ruta: C:\Windows\System32\drivers\etc
  - Cambiar filtro de documentos de texto txt a Todos los archivos
  - Abrir el arhcivo host
  - Añadir al final del archivo la línea: 127.0.0.1 amacarul.42.fr
  - Guardar y cerrar

En terminal de windows / wsl:

      ssh -L 443:localhost:443 <login>@<IP_VM>

> Mientras esta ventana se mantenga abierta, el tunneling está activo (?)

Access:

    https://<login>.42.fr


##### 42 iMacs (no sudo) ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ 
Port 443 cannot be used locally:

      ssh -L 8443:localhost:443 <login>@<VM_IP>

Access:

      https://localhost:8443

⚠️ SOCKS proxy alternative is still under investigation!! AVERIGUAR ESTO!!!

## Build and launch the project using the Makefile and Docker Compose

Although no source code is compiled, `make` orchestrates the build of the Docker images and the deployment of the stack.
What `make` does is:

      docker compose build
      docker compose up -d

The Makefile provides a simplified interface to manage the lifecycle of the stack without typing logn Docker commands.  
AÑADIR RESUMEN DE COSAS QUE HACE EL MAEFILE???

| Command | What it does |
|---------|--------------|
| `make` | qué hace esto |
| `make stop` | Stops the containers, sin eliminar ni los contenedores ni los volúemenes |
| `make down` | Para y elimina los contenedores, redes y los volúmenes interos de docker-compose (los declarados dentro de docker-compose) (QUÉ VOLÚMENES SON ESTOS?), pero conserva los datos persistentes en las carpetas montadas en el host. Las imágenes no se eliminan. ¿QUÉ IMPLICA QUE NO SE ELIMINEN LAS IMÁGENES? ¿QUE SI SE HACEN CAMBIOS EN EL SETUP.SH DE LAS DIFERENTES APPS, NO SE VERÁN REFLEJADOS O ALGO ASÍ? |
| `male clean` | Para y elimina contenedores, redes y volúmenes interos de Docker, pero no borra los volúemenes que datos que creamos en `/home/<login>/data/...`. También elimina las imágenes generadas. |
| `make fclean` | Hace `clean` y borra completamente los datos persistentes en `/home/<login>/data/...` y hace un `docker system prine -a --force`: ⚠️ esto resetea completamente el proyecto. |

## Use relevant commands to manage the containers and volumes

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

          mysql -u <login> -p database

      PARA QUÉ SE HACE ESTO? PARA ENTRAR A LA BASE REAL DE WORDPRESS
          

⚠️  CREO QUE HABRIA QUE EXPLICAR MÁS COMANDOS... hacer una lista ordenada y coherente, con sentido.  
ALGUNOS DE ESTOS ESTÁN RECOGIDOS DIRECTAMENTE EN EL MAKEFILE -> decir cuales...
EXPLICAR QUÉ HACE CADA UNO?? CREO QUE TENGO MÁS EXPLICACIONES EN README NORMAL '??  
QUIZÁS DEBERIA DIFERENCIAR ENTRE COMANDOS DE DOCKER COMPOSE Y COMANDOS DE DOCKER A SECAS?  o igual los comandos de docker compose ya se han explicado en el apartado anterior de build and launch the project...??  

## Identify where the project data is stored and how it persist
### Persistent data locations
In this project, all persistent data is stored explicitly on the host machine (the VM) under: 

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
  - The WordPress core files
  - `wp-config.php`
  - Themes and plugins
  - Uploaded files (`wp-content/uploads`)
  This ensures WordPress content and configuration persist across restarts.
⚠️ COMPROBAR TODOS ESTOS ARCHIVOS... REPASAR  
ABAJO: ESPECIFICACIONES SOBRE CÓMO FUNCIONA LA CONFIG Y TAL

### Persistent behaviour (`make` rules)
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

### WordPress configuration: `wp-config.php`  

`wp-config.php` is the central configuration file of WordPress. In this project, it is generated automatically by `wp-clip` in the WordPress `setup.sh` script.  
#### Location

          /home/login/data/wordpress/wp-config.php 
          
#### What contains
1. Database connection settings
   This values allow WordPress to connect to the MariaDB container: `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`  
   WordPress connects to MariaDB via the Docker network, not via `localhost`.
   > ⚠️ IMPORTANTE A LA HORA DE ACCEDER A LA DATABASE -> CON ROOT, NO CON LOGIN/USER

2. Table prefix: `wp_`
3. Security keys
   Used for:
   - authentication
   - cookies
   - session security

   These are generated automatically by `wp-cli`.
4. Debug configuration (`WP_DEBUG`) 
   By default, `WP_DEBUG` is not enabled in this project.  
   If enabled, it would:
   - show PHP errors
   - show warnings and notices
   - help detect plugin or SQL errors  
   
   **How it could be enabled (optional):** 
   - In `setup.sh`, after `wp config create` block:

             wp config set WP_DEBUG true --allow-root
             wp config set WP_DEBUG_LOG true --allow-root
             wp config set WP_DEBUG_DISPLAY false --allow-root
     
   - ⚠️ Since `wp_config.php` is persistent, existing volumes would need to be removed for this change to take effect.

5. WordPress bootstrap
   At the end of the file:

           define('ABSPATH', __DIR__ . '/');
           require_once ABSPATH . 'wp-settings.php';
   
   This boots the WordPress core.

### MariaDB access and databases

#### Entering MariaDB

      docker exec -it mariadb bash
      mysql -u root -p

Root access is required for inspection.  
> - In MariaDB, users are defined as 'user'@'host'.
> - In this project (`setup.sh` of `mariadb\tools\`):

>      CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

>  - `%` is a wildcard meaning "any host on the network"
>  - This allows WordPress (in another container) to connect
>  - However, `%` does not include `localhost`
>  - When running `mysql -u login -p`, MariaDB tries `login@localhost`, and that user does not exist
>  - Therefore, WordPress connects via Docker networking -> works
>  - Manual inspection should be done as `root`

#### Listing databases

      SHOW DATABASES;

Databases:
- `mysql` -> system database
- `information_schema`
- `performance_schema`
- `sys`
- `test`
- `database`-> WordPress database

### Some SQL keywords

| Keyword | Description |
|---------|-------------|
| DESCRIBE | |
| SELECT | |
| FROM | |
| SHOW | |
| USE | |


### WordPress database tables
After selecting the WordPress database:

      USE database;
      SHOW TABLES;

Main tables:
- `wp_users` -> users
- `wp_usermeta` -> roles and permissions
- `wp_posts`-> post, pages, revisions, attachments
- `wp_postmeta` -> post metadata
- `wp_comments`, `wp_commentmeta`
- `wp_options` -> global configuration
- `wp_terms`, `wp_term_taxonomy`, `wp_term_relationships`, `wp_termmeta`

#### Users 
Stored in `wp_users`.  
Example:

        SELECT ID, user_login, user_email FROM wp_users;

#### Logs
WordPress does not store logs in MariaDB by default.  
Existing logs:
- PHP-FPM logs -> inside WordPress container (not persistent)
- MariaDB logs -> `/var/log/mysql` (not persistent)
⚠️ COMPROBAR ESTO!!! VER DONDE SE GUARDA
Persistent logging would require explicit configuration, which is not required for Inception ❌❌ CREO QUE NO HACE FATLA HACER ESTO

#### Roles and permissions
Stored in `wp_usermeta`.  
Key: `wp_capabilities`.
Example:

        SELECT user_id, meta_key, meta_value
        FROM wp_usermeta
        WHERE meta_key LIKE '%capabilities%';

Values are PHP serialized data, e.g.:

      a:1:{s:13:"administrator";b:1;}
      a:1:{s:10:"subscriber";b:1;}

#### Posts, pages, uploads and revisions
All content is stored in `wp_posts`.  
Example:

      SELECT ID, post_title, post_type, post_status
      FROM wp_posts;

Important `post_type` values:
- `post` -> blog post
 - `page` -> page
 - `revision` -> update history
 - `attachment` -> uploaded files (images, etc.)

WordPress does not overwrite posts. Each update creates a new row with `post_type = revision`.  
`post_author`:  
- References `wp_users.ID`
- `1` usually correspondos to the admin user
- `2` would be a normal user ⚠️⚠️⚠️ EXPRESAR ESTO BIEN, NORMAL USER ES POCO ESPECIFICO
- `0` means system-generated content

#### Permissions
PRIMERO EXPLCIAR LOS ROLES QUE EXISTEN EN WORDPRESS!! 
⚠️ FALTAN MAS ROLES??  
- `subscriber`:
- `contributor`: write, not publish
- `author`: write and publish
- `editor`: edit other's posts

Roles can be changed:
- From WordPress admin panel
  - Users -> user1 -> change role (COMPROBAR CÓMO SE HACE ESTO!)
- From the WordPress container

        wp user set-role user1 author --allow-root

This updates:
- `wp_capabilities`
- `wp_user_level`
⚠️ COMPROBAR TB ESTO!
    

#### Global WordPress configuration
Stored in `wp_options`.  
Includes:
- site URL
- active theme
- enabled plugins
- internal WordPress settings



