
DOCKER_COMPOSE=docker compose -f srcs/docker-compose.yml

mariadb-build:
	$(DOCKER_COMPOSE) build mariadb

wordpress-build:
	$(DOCKER_COMPOSE) build wordpress

nginx-build:
	$(DOCKER_COMPOSE) build nginx

build:
	$(DOCKER_COMPOSE) build mariadb wordpress


up:
	$(DOCKER_COMPOSE) up mariadb wordpress

logs:
	$(DOCKER_COMPOSE) logs mariadb wordpress

status:
	$(DOCKER_COMPOSE) ps


stop:
	$(DOCKER_COMPOSE) stop mariadb wordpress


clean:
	$(DOCKER_COMPOSE) down
