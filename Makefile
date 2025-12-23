
DOCKER_COMPOSE=docker compose -f srcs/docker-compose.yml

# Build mariadb
mariadb-build:
	$(DOCKER_COMPOSE) build mariadb

wordpress-build:
	$(DOCKER_COMPOSE) build wordpress

build:
	$(DOCKER_COMPOSE) build mariadb wordpress


up:
	$(DOCKER_COMPOSE) up mariadb wordpress

logs:
	$(DOCKER_COMPOSE) logs -f mariadb wordpress


stop:
	$(DOCKER_COMPOSE) stop mariadb wordpress


clean:
	$(DOCKER_COMPOSE) down
