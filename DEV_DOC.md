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
Persistent data locations:

        /home/<login>/data/mariadb
        /home/<login>/data/wordpress

- MariaDB stores its database files in the mariadb volume
- WordPress stores uploads, plugins, and themes in `wp-content`

Persistence behaviour:
- `make down`: containers are removed, data remains
- `make fclean`: containers, volumes, and data are deleted
- `make clean`: Para y elimina contenedores, redes y volúmenes interos de Docker, pero no borra los volúemenes que datos que creamos en `/home/<login>/data/...`. También elimina las imágenes generadas.
  
INSISTIR EN LA DIFERENCIA ENTRE FCLEAN Y CLEAN  


⚠️ NO SÉ SI ESTO ESTÁ BIEN EXPRESADO:  
Los volúmenes persistentes de mariadb y wordpress están montados en `/var/lib/mysql` y `/var/www/html` respectivamente, lo cual se hace/establece en el `docker-compose.yml`.  
- MariaDB
  - Host: `/home/login/data/mariadb`
  - Container: `/var/lib/mysql`
  - Aquí está toda la base de datos real, persistente (usuarios, roles y permisos, posts, páginas, revisiones, comentarios, opciones del sitio...), todo lo importante a nivel lógico.
- WordPress
  - Host: `/home/login/data/wordpress`
  - Container: `/var/www/html`
  - Aquí están:
    - Archivos de WordPress: LOS ARCHIVOS SUBIDOS?
    - `wp-config.php`: Archivo de configuración central de Wordpress, que define cómo se conecta a la base de datos, su seguridad, su modo de ejecución y que arranca el core. Contiene:
      - datos de conexión a la base de datos (DB_NAME, DB_USER, DB_PASSWORD, DB_HOST), que conectan WordPress al contenedor mariadb
      - prefijo de tablas (wp_)
      - claves de seguridad (las genera wp-cli automáticamente)
      - configuración de depuración (WP_DEBUG) -> si lo pusiera en TRUE -> mostraria los errores PHP, los warnings... deberia ver cosas tipo un plugin mal escrito, una variable no definda, errores SQL...
        > Note: No hace falta activar WP_DEBUG en Inception porque lo que estamos haciendo no es entorno de desarrollo interactivo.
        > Pero podría activarlo si quisiera así:
        > - Modificar `wp-config.php`: en `setup.sh` de WordPress, después delo bloque `wp config create`, añadir:
        >
        >         wp config set WP_DEBUG true --allow-root
        >         wp config set WP_DEBUG_LOG true --allow-root
        >         wp config set WP_DEBUG_DISPLAY false --allow-root
        >   Esto modifica `wp-config.php` y queda persistente en el volumen. ⚠️ PROBABLEMENTE DEBERÍA BORRAR LOS VOLÚMENES PERSISTENTES PARA HACER EFECTIVO ESTE CAMBIO!

      - ABSPATH + carga de WordPress
    - uploads
    - themes, plugins

Cómo ver las databases de MariaDB: 

        #entrar en el contenedor
        docker exec -it mariabd bash
        # conectarse con root
        mysql -u root -p
        # meter contrasela
        SHOW DATABASES;

Databases que tengo:
- mysql -> sistema
- information_schema
- performance_schema
- database <- wordpress
- sys
- test

⚠ AÑADIR:  
TODO ESTO ES INFOR GUARDADA EN WORDPRESS O EN MARIADB?
- Dónde se guardan los usuarios -> `wp_users`

        docker exec -it mariadb bash
        mysql -u root -p
        USE database;
        SHOW TABLES;

  > Note: tal como he configurado mariadb (setup.sh), el usuario amacarul puede acceder a wordpress desde red, no como localhost. amacarul@% no es lo mismo que amacarul%localhost. Así que para acceder a data de mariadb/wordpress, usar root.
  > '%' es un wildcard (comodín) que significa "Desde cualquier host". 'login'@'%' puede conectarse desde:
  > - wordpress
  > - nginx
  > - 172.18.0.5
  > - cualquier IP de la red Docker
  > - Pero, al parecer, '%' no incluye 'localhost'... Cuando ahces mysql -u amacarul -p, mariaDB interpreta 'amacarul'@'localhost', y este usuario no existe
  > WordPress se conecta por MariaDB por red Docker, no por localhost
  > `nginx -> php -> wordpress -> mariadb`
  > ergo... sigo sin entender por qué puedo usar root para acceder a la database y no amacarul.
  > En MariaDB los usuarios están definidos como user@localhost; el wildcard % permite conexiones desde la red Docker pero no desde localhost, lo cual es adecuado apra WordPress en contenedores separados.

  Esto muestra algo como: EXPLICAR QUÉ HAY EN CADA TABLE

          wp_users
          wp_posts
          wp_usermeta
          wp_postmeta
          wp_commentmeta
          wp_comments
          wp_links
          wp_options
          wp_term_relationships
          wp_term_taxonomy
          wp_termmeta
          wp_terms
          

  Ver usuarios:

        SELECT ID, user_login, user_email FROM wp_users;


  > cómo ver las columnas de una tabla: `DESCRIBE wp_users;`
  
- Dónde se guardan los logs: WordPress no guarda logs en MariaDB por defecto.
  Los logs que existen, son:
  - Logs de PHP-FPM: dentro del contenedor Wordpress, no persistentes si no los montas.
  - Logs de MariaDB: normalmente se guarda en /var/log/mysql. No persistentes en tu volumne.
  Para que wordpress guardara los logs habría que configurarlos explícitamente ❌❌ CREO QUE NO HACE FATLA HACER ESTO
- Dónde se guardan las creaciones de posts, las actualizaciones, los archivos que se han subido, etc: `wp_posts`

          SELECT ID, post_title, post_type, post_status
          FROM wp_posts;

  Important types:
  - `post`: entrada
  - `page`: página
  - `revision`: historial de cambios
  - `attachment`: imágenes
  - 
  Más cosas de wp_post:
  - post_author: corresponde al wp_users.ID, referencia al ID del usuario en `wp_users` (suele ser 1 para el administrador, 2 para mi user; el valor 0 indica contenido no asociado a un usuario - elementos generados por el sistema). Me aparecen post_author = 1 porque creo que mi user1 es solo un subscriber, no genera posts.
  - DEBERIA CAMBIARLE LOS PERMISOS AL USER1? ❌
 
  > Actualizaciones de posts: Wordpress no sobrescribe, crea una nueva fila con `post_type = revision`.


- Si doy formato a la web, dónde se guarda eso? eso ya no sería un volumen persistente, no? sería algo que se tendría que ejecutar al runnear el wordpress, el servicio en sí, no?
- Dónde se guardan los roles y permisos: `wp_usermeta` 

      SELECT user_id, meta_key, meta_value
      FROM wp_usermeta
      WHERE meta_key LIK '%capabilities%'

  Verás algo como:

            a:1:{s:13:"administrator";b:1;}
            a:1:{s:10:"subscriber";b:1;}

Esto es PHP serialized data

- Configuración global de WordPress: `wp_options`
  - URL del sitio
  - Tema activo
  - Plugins
  - Opciones internas

Uploaded files and WordPress content survive restarts as long as volumes are preserved.

