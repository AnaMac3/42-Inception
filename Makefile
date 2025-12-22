
DOCKER_COMPOSE=docker compose -f srcs/docker-compose.yml

# Build mariadb
mariadb-build:
	$(DOCKER_COMPOSE) build mariadb
up:
	$(DOCKER_COMPOSE) up mariadb

# Construir todas las imágenes
# build:
# 	$(DOCKER_COMPOSE) build
# up:
# 	$(DOCKER_COMPOSE) up -d
#
# stop:
# 	$(DOCKER_COMPOSE) stop
# 
# clean:
# 	$(DOCKER_COMPOSE) down
