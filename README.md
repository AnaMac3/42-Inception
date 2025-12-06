# 42-Inception
42 Common Core Inception 
- de qué va??
- System administration
- Docker technology

## Table of Contents
- [How to use](#how-to-use)
- [Fixed-point numbers](#fixed-point-numbers)
- [More info](#more-info)

----------------------------------------

## How to use

## Notes
- Hay que hacer el proyecto en una máquina virtual -> Docker Compose
- cada imagen de Docker tiene que tener el mismo nombre que su servicio correspondiente
- Cada servicio debe correr en un dedicater container
- Los contenedores deben construirse desde la penultima versión estable de Alpine o Debian ???
- Tienes que escribir tu propio Dockerfiles, uno por servicio. Los Dockerfiles debe llamarse en tu docker-compose.yml por tu Makefile
- Esto significa que debes construir las iamgenes Docker para el proyecto por tu cuenta. Está prohibido subir imagenes de Docker que ya estén hechas de servicios como DockerHub (Alpine/Debian se excluyen de esta norma) -> Cómo se comprueba eso en la evaluación?
- Hay que set up:
  - Un contenedor de Docker que contenga NGINX con TLSv1.2 o TLSv1.3 solo
  - Un contenedor Docker que contenga WordPress con php-fpm (debe ser instalado y configurado) solo, sin nginx
  - Un contenedor Docker que contenga solo MariaDB, sin nginx
  - Un volumen que contenga tu database WordPress
  - Un segundo volumen que contenga tus archivos de website de WordPress
  - un docker-network que establezca la conexión entre los contenedores
- Tus contenedores deben reiniciarse automaticamente en caso de crash

-> leer sobre como trabaja daemons y si es buena idea usarlos !!
-> está prohibido usar host o --link o links. The network line tiene que estar presente en tu docker-compose.yml file. Tus containers no deben iniciarse con un comando que corra en un bucle infinito. Esto se aplica a todo comando que se use como entrypoint, o usado en scripts de entrypoint. Está prohibido: tail -f, bash, sleep infinity, while true

-> leer sobre PID 1 y buenas prácticas de Dockerfiles

- En tu database WordPress tiene que haber dos usuarios: uno de ellos ha de ser el administrador, su username no puede contener 'admin', 'Admin', 'administrator, o 'Administrator'

-> tus volumenes estarán disponibles en la carpeta /home/login/data de la host machine que use Docker. Tienes que reemplazar el login por el tuyo.

- para simplificar el proceso, debes configurar tu domain name to point a tu local IP address
- Este domain name debe ser login.42.fr. usa tu propio login. amacarul.42.fr redirigirá a la dirección IP que apunta a la website de amacarul

-> the latest tag is prohibited ??
-> no tiene que haber contraseñas
> hay que usar obligatoriamente environment variables
> se recomienda usar .env file para guardar las variables de entorno y para usar Docker secrets para almacenar infor confidencial
> tu contenedor NGINX debe ser el unico entry poiny a tu infraestructura, accesible solo via port 443, usando TLSv1.2 o TLSv1.3
>
....

## More info
Other repos &rarr; [HERE](https://github.com/Forstman1/inception-42)
Grademe tutorial &arr; [HERE](https://tuto.grademe.fr/inception/)
