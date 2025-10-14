# ==============================
# Makefile for Docker management
# ==============================

# Docker Compose command shortcut
COMPOSE=docker compose

# Compose profiles
PROFILE_DEV=dev
PROFILE_PROD=prod

# Docker project name (used to group containers)
PROJECT_NAME=reverse-proxy

# Default target (display help)
.DEFAULT_GOAL := help

# Initialize environment file and install local dependencies
help:
	@echo "Available commands:"
	@echo "  make init        -> Initialize local configuration files from .dist templates"
	@echo "  make prod        -> Run Docker in production mode (to get proper signed SSL)"
	@echo "  make dev         -> Run Docker in dev mode (to get self signed SSL for testing)"
	@echo "  make down        -> Stop containers"
	@echo "  make prune       -> Reset the environment of the containers (all of its data)"
	@echo "  make logs        -> Show container logs"

init:
	@if [[ ! -f ./conf-template/vhosts.json ]]; then \
		echo "Creating conf-template/vhosts.json from template..."; \
		cp ./conf-template/vhosts.json.dist ./conf-template/vhosts.json; \
	fi
	@if [[ ! -f ./.env.dev ]]; then \
		echo "Creating .env.dev from template..."; \
		cp ./.env.dev.dist ./.env.dev; \
	fi
	@if [[ ! -f ./.env.prod ]]; then \
		echo "Creating .env.prod from template..."; \
		cp ./.env.prod.dist ./.env.prod; \
	fi

# Run in development mode (builds dev image and runs nodemon)
dev:
	$(COMPOSE) --env-file .env.dev up --build -d
# Run in production mode (builds optimized prod image)
prod:
	$(COMPOSE) --env-file .env.prod up --build -d

# Stop and remove all project containers
down:
	$(COMPOSE) down

# Reset the environment : stop the containers and remove all of its dependencies (image and volumes)
prune:
	$(COMPOSE) down --rmi local --volumes --remove-orphans

# Follow container logs in real time
logs:
	$(COMPOSE) logs -f
