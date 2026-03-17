NAME = inception

COMPOSE_FILE = srcs/docker-compose.yml

DATA_PATH = /home/amacarul/data
WP_DATA = $(DATA_PATH)/wordpress
DB_DATA = $(DATA_PATH)/mariadb

CYAN = \033[0;36m
RESET = \033[0m

all: dirs build up

dirs:
	@echo "$(CYAN)Creating data directories... $(RESET)"
	@mkdir -p $(DATA_PATH)
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)

build:
	@echo "$(CYAN)Building images... $(RESET)"
	docker compose -f $(COMPOSE_FILE) build

up:
	@echo "$(CYAN)Launching containers... $(RESET)"
	docker compose -f $(COMPOSE_FILE) up -d

stop:
	@echo "$(CYAN)Stopping containers... $(RESET)"
	docker compose -f $(COMPOSE_FILE) stop
down:
	@echo "$(CYAN)Shutting down containers... $(RESET)"
	docker compose -f $(COMPOSE_FILE) down

status:
	@echo "$(CYAN)Checking status... $(RESET)"
	docker compose -f $(COMPOSE_FILE) ps

clean:
	@echo "$(CYAN)Cleaning containers, networks, and images... $(RESET)"
	docker compose -f $(COMPOSE_FILE) down --rmi all

fclean: clean 
	@echo "$(CYAN)Deleting persistent data... $(RESET)"
#	@docker compose -f $(COMPOSE_FILE) down --volumes
	@docker volume rm -f $(docker volume ls -q) || true
#	@docker volume prune -f
	@sudo rm -rf $(DATA_PATH)
	@docker system prune -a --force

re: fclean all

.PHONY: all build up down clean re
