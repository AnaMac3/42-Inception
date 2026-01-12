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
1. Start the project:

      make

   `make` hace `build` y `up` de los containers.

2. Stop and clean

         make stop

   `make stop` para los contenedores

         make down

   `make down` borra los contenedores


         make clean

   explicar qué limpia!!!

         make fclean

   explicar qué limpia!!!

## Access the website and the administrator panel

Acceso al sitio web, en el navegador:

      https://<login>.42.fr
      
Acceso al panel del administrador:

      https://<login>.42.fr/wp-admin

## Locate and manage credentials

EXPLICAR:
- Las credenciales están definidas en el archivo `.env`
- Admin WordPress (SE TRATA DE EXPLICAR QUÉ PERMISOS HE DADO A CADA CATEGORÍA??)
- Usuario WordPress
- Base de datos (sin entrar en SQL)

No explicar comandos SQL aquí
ME FALTA AVERIGUAR CÓMO FUNCIONA ESTO BIEN...

⚠️ SE SUPONE QUE LO QUE SE PIDE EN ESTE APARTADO ES: ¿DÓNDE ENCUENTRA UN USUARIO/ADMIN LAS CREDENCIALES Y CÓMO LAS USA? 

En Inception las credenciales existen en dos niveles:
1. Credenciales de WordPress (usuario final y administrador): estas sí son las relevantes para el USER_DOC:
Están definidas en el `.env`:

               WORDPRESS_ADMIN_USER
               WORDPRESS_ADMIN_PASSWORD
               WORDPRESS_USER
               WORDPRESS_USER_PASSWORD

Las credenciales iniciales de WordPress se definen durante el despliegue.  
Existen dos tipos de cuentas:
- Administrador (acceso a `/wp-admin`)
- Usuario estándar

El administrador puede:
- Crear, editar y borrar contenido
- Subir archivos
- Gestionar usuarios desde el panel de WordPress
  ⚠️ COMPROBAR CÓMO SE HACENE STAS COSAS Y DÓNDE SE VEN ESOS PERMISOS

2. Credenciales de base de datos (NO EXPLICAR EN USER_DOC!!!, ESTO VA EN DEVELOPER DOC)
Database credentials are handled internally by the stack and are not required for normal usage.

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


    

