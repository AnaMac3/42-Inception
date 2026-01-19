# 42-Inception - User Documentation

⚠️ CÓMO TIENE QUE SER: orientado al usuario final / administrador. Que indique qué se puede hacer con esta web y cómo se usa. Indicar uso funcional.

## Table of Contents

- [Services provided by the stack](#services-provided-by-the-stack)
- [Start and stop the project](#start-and-stop-the-project)
- [Access the website and the administrator panel](#access-the-website-and-the-administrator-panel)
- [Locate and manage credentials](locate-and-manage-credentials)
- [Check that the services are running correctly](check-that-the-services-are-running-correctly)

-------------------------------------------------

## Services provided by the stack

EXPLICAR QUE OFRECE WORDPRESS + NGINX + MARIADB
- Website WordPress accesible por HTTPA
- Panel de administración (`/wp-admin`)
- Sistema de usuarios (admin / user)
- Publicación de entradas
- Subida de archivos (media)
- Persistencia de datos (usuarios, posts, uploads)

NO HACE FALTA HABLAR DE CÓMO CAMBIAR PERMISOS, SOLO QUÉ EXISTE

## Start and stop the project
1. Start the project
   - `make`: hace `build` y `up` de los contenedores.

2. Stop and clean

   - `make stop`: para los contenedores, sin eliminar los contenedores ni los volúmenes
   - `make down`: para y borra los contenedores y redes, pero conserva los volúmenes persistentes
   - `make clean`: para y elimina los contenedores, redes, volúmenes internos de docker y las imágenes, pero conserva los volúmenes persistentes
   - `make fclean`: hace `clean` y borra también los volúmenes persistentes.
     
## Access the website and the administrator panel
⚠️ PONER ENLACE A PREREQUISITO NECESARIO: SSH TUNNELING SI ESTAMOS EN VM... O NO HACE FALTA PORQUE YA LO PONGO EN EL README??  

Acceso al sitio web, en el navegador:

      https://<login>.42.fr
      
Acceso al panel del administrador:

      https://<login>.42.fr/wp-admin

⚠️ EXPLICAR QUÉ SE PUEDE HACER EN EL PANEL DEL ADMINISTRADOR

## Locate and manage credentials
This section explains where the WordPress credentials are defined, how they are used to access the website, and how users and roles can be managed from the WordPress administration interface.  

### WordPress access credentials
The initial WordPress credentials are defined at deployment time via environment variables in the `.env` file.  
The following credentials are created automatically when the stack is deployed:  

         WORDPRESS_ADMIN_USER
         WORDPRESS_ADMIN_PASSWORD
         
         WORDPRESS_USER
         WORDPRESS_USER_PASSWORD

These credentials are used to access the WordPress website and the administration panel.  
- Administrator credentials:
  - Used to access the WordPress admin dashboard at `/wp-admin`
  - Full control over the website
- Standard user credentials
  - Used to log in as a non-administrator user
  - Limited permissions depending on the assigned role

Once WordPress is installed, these users are stored internally by WordPress and persist accross container restarts.  

### Administrator and user roles
WordPress uses a role-based permission system.  
Each user account is assigned exactly one role, which defines what actions the user is allowed to perform.  
The default WordPress roles are:
- Administrator: has access to all the administration features withinn a single site.
- Editor: can publish and manage postst including the postst of other users.
- Author: can publish and manage their own posts.
- Contributor: can write and manage their own posts but cannot publish them.
- Subscriber: can only manage their profile.

In this project, WordPress is initially deployed with:
- one administrator account
- one standard user account with limited permissions

### Managing users from the admin panel
User and role maangement is done directly from the WordPress administration interface.  
To manage users:
1. Log in as administrator at:

            https://<login>.42.fr/wp-admin

2. Navigate to:

         Users -> All Users

3. Select a user
4. Change the assigned role using the Role dropdown
5. Save changes

Role changes take effect immediately and define what actions the user can perform on the website.  

### Database credentials (internal)
Database credentials are handled internally by the Docker stack and are not required for normal usage of the website.  
They are:
- defined in the `.env` file
- used automatically by WordPress to connect to MariaDB
- never required to be entered manually by users or administrators
For these reasons, database credentials are documented in the Developer Documentation, not in this user guide.  
CREO QUE ESTO SOBRA...

## Check that services are running correctly
1. Acceso a la web:
   - Abrir el navegador
   - Acceder a:

                 https://<login>.42.fr
     
   - La página carga por HTTPS
2. Hacer login como administrador
   - Acceder a:

                 https://<login>.42.fr/wp-admin
     
   - Introducir credenciales de admin
   - Acceso al panel

3. Crear contenido
   - Crear una entrada: PASOS
   - Publicarla: PASOS
   - Verla en la página principal

   Esto demuestra que:
   - Wordpress funciona
   - PHP funciona
   - MariaDB funciona
   - Conexión entre servicios OK


    

