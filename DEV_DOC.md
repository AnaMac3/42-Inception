# 42-Inception - Developer Documentation

Describe how a developer can:
- Set up the environment from scartch (prerequisites, configiration files, secrets...)
- Build and launch the project using the Makefile and Docker Compose
- Use relevant commands to manage the containers and volumes
- Identify where the project data is stored and how it persist

## Set up the environment from scratch
Quizás es aquí donde deberia añadir todo esto??:

### Preparar la VM:
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
    - Carpetas compartidas (opcional) -> lo configuramos más adelante
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

### Instalar Docker y Docker Compose
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

### Cómo compartir carpetas entre la VM y el host
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

### Volúmenes persistentes

 Crea las carpetas del host que luego montarás como volúmenes / estructura de directorios

       mkdir -p /home/<login>/data/wordpress
       mkdir -p /home/<login>/data/mariadb

       #Ajustar permisos para que Docker pueda escribir
       sudo chown -R <login>:<login> /home/<login>/data

### Archivo .env
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
    MYSQL_DATABASE=database
    MYSQL_USER=amacarul
    MYSQL_PASSWORD=passusersql
    MYSQL_ROOT_USER=root
    MYSQL_ROOT_PASSWORD=blablapasswordsql
    
    WORDPRESS_TITLE=myWebsite
    WORDPRESS_ADMIN_USER=boss
    WORDPRESS_ADMIN_PASSWORD=blablapasswordpress
    WORDPRESS_ADMIN_EMAIL=boss@inception.fr
    WORDPRESS_USER=user1
    WORDPRESS_USER_EMAIL=user1@inception.fr
    WORDPRESS_USER_PASSWORD=passuserwordpress

Hay cosas de estas que tienen que ir a secrets, creo... las contraseñas, por ejemplo, no deberian estar como variables de entorno, no?

# Configuración del dominio ¿esto deberia ir aquí, no?? en developer documentation
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

## Build and launch the project using the Makefile and Docker Compose

¿Habría que explicar primero como conectarse vía ssh desde terminal normal a la VM o eso sobra?
- `make`: hace build y up
- `stop`: para los contenedores
- `down`: destruye los contenedores pero no los volúmenes persistentes de data
- `clean`:
- `fclean`:

## Use relevant commands to manage the containers and volumes
no entiendo qué tiene que ir aquí

## Identify where the project data is stored and how it persist
no sé qué parte de todo esto debe ir aquí o en otro sitio: - Comprobación de que todos los contenedores arrancan
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
