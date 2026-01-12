# 42-Inception - User Documentation

⚠️ CÓMO TIENE QUE SER: orientado al usuario final / administrador. Que indique qué se puede hacer con esta web y cómo se usa. Indicar uso funcional.

Explain how an end user or administrator can:
- Understand what services are provided by the stack
- Start and stop the project
- Access the website and the administrator panel
- Locate and manage credentials
- Check that the services are running correctly

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

## Check that services are running correctly
- Hacer login
- Crear una entrada/post
- Subir imagen
- Ver cambios en la web

    

