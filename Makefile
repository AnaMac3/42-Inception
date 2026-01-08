NAME = inception

COMPOSE_FILE = srcs/docker-compose.yml

CYAN = \033[0;36m
RESET = \033[0m

all: build up

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
	@echo "$(CYAN)Cleaning containers, networks, and volumes... $(RESET)"
	docker compose -f $(COMPOSE_FILE) down --volumes --rmi all

fclean: clean
	@sudo rm -rf /home/amacarul/data/wordpress/*
	@sudo rm -rf /home/amacarul/data/mariadb/*
	@docker system prune -a --force

re: fclean all

.PHONY: all build up down clean re
