NAME = inception

COMPOSE_FILE = srcs/docker-compose.yml

DATA_PATH = /home/amacarul/data
WP_DATA = $(DATA_PATH)/wordpress
DB_DATA = $(DATA_PATH)/mariadb

CYAN = \033[0;36m
RESET = \033[0m

all: dirs build up

# Create directories for bind mounts
# set ownership to mariadb user (UID 999)
dirs:
	@echo "$(CYAN)Creating data directories... $(RESET)"
	@mkdir -p $(DATA_PATH)
	@mkdir -p $(WP_DATA)
	@mkdir -p $(DB_DATA)
	sudo chown -R 999:999 /home/amacarul/data

# Build Docker images
build:
	@echo "$(CYAN)Building images... $(RESET)"
	docker compose -f $(COMPOSE_FILE) build

# Start all services
up:
	@echo "$(CYAN)Launching containers... $(RESET)"
	docker compose -f $(COMPOSE_FILE) up -d

# Stop running containers
stop:
	@echo "$(CYAN)Stopping containers... $(RESET)"
	docker compose -f $(COMPOSE_FILE) stop

# Shut down all containers 
down:
	@echo "$(CYAN)Shutting down containers... $(RESET)"
	docker compose -f $(COMPOSE_FILE) down

# Show status of running containers
status:
	@echo "$(CYAN)Checking status... $(RESET)"
	docker compose -f $(COMPOSE_FILE) ps

# Remove containers, networks and images created by compose
# Also remove any leftover containers
clean:
	@echo "$(CYAN)Cleaning containers, networks, and images... $(RESET)"
	docker compose -f $(COMPOSE_FILE) down --rmi all
	@docker ps -aq | xargs -r docker rm -f

# Full cleanup
# Remove volumes
# Deletes persistent data from host
# Prunes unused Docker resources (images, cache...)
fclean: clean 
	@echo "$(CYAN)Deleting persistent data... $(RESET)"
	@docker volume ls -q | xargs -r docker volume rm -f
	@sudo rm -rf $(DATA_PATH)
	@docker system prune -a --force

re: fclean all

.PHONY: all build up down clean re
