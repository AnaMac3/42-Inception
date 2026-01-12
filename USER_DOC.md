# 42-Inception - User Documentation

Explain how an end user or administrator can:
- Understand what services are provided by the stack
- Start and stop the project
- Access the website and the administrator panel
- Locate and manage credentials
- Check that the services are running correctly

## Servicios que provee el stack

Una págin web?  
Se puede entrar con user o como admin  
Se pueden hacer posts como admin (no sé si esto de los permisos es algo que pueda cambiar y cómo...)  
subir archivos  
qué más provee el stack?

## Start and stop the project
¿Qué deberia explicar aquí?:
- conexión desde terminal a la VM (ssh...)
- Configuración de dominio??
- make
- navegador
- make down
- ...??

## Access the website and the administrator panel

En el navegador:

      https://<login>.42.fr/wp-admin

## Check that services are running correctly
- Hacer login
- Crear una entrada/post
- Comprobar qué se modifica cuando haces esto:
  - Ver usuarios:

              #entrar al contenedor mariadb
              docker exec -it mariadb bash
              mysql -u root -p
              #ejecutar SQL
              SHOW DATABASES;
              USE wordpress;
              SELECT user_login, user_registered FROM wp_users;

    - Ver posts

            SELECT ID, post_title, post_status FROM wp_post

    - Ver arhcivos subidos:
   
            ls data/wordpress/wp-content/uploads

    

