# Variables
IMAGE_NAME := udx-worker/udx-worker
TAG := latest
DOCKER_IMAGE := $(IMAGE_NAME):$(TAG)
CONTAINER_NAME := udx-worker-container
ENV_FILE := .udx
WORKER_CONFIG := ./src/configs/worker.yml
FORCE ?= false
DEBUG ?= true

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Usage:"
	@echo "Build the Docker image:"
	@echo "  make build"
	@echo ""
	@echo "Run the Docker container:"
	@echo "  make run"
	@echo ""
	@echo "Exec into the running container:"
	@echo "  make exec"
	@echo ""
	@echo "View the container logs:"
	@echo "  make log"
	@echo ""
	@echo "Delete the running container:"
	@echo "  make clean"
	@echo ""
	@echo "Generate the .udx environment file:"
	@echo "  make generate-env"
	@echo ""
	@echo "Generate the worker.yml configuration file:"
	@echo "  make generate-config"
	@echo ""
	@echo "Run the development pipeline (generate env, generate config, build, test):"
	@echo "  make dev-pipeline"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME (default: udx-worker/udx-worker)"
	@echo "  TAG (default: latest)"
	@echo "  CONTAINER_NAME (default: udx-worker-container)"
	@echo "  ENV_FILE (default: .udx)"
	@echo "  DOCKER_IMAGE (default: udx-worker/udx-worker:latest)"
	@echo "  WORKER_CONFIG (default: ./src/configs/worker.yml)"
	@echo "  FORCE (default: false)"
	@echo "  DEBUG (default: true)"

# Build the Docker image
build:
	@echo "Building Docker image..."
	@if [ "$(DEBUG)" = "true" ]; then \
		docker build -t $(DOCKER_IMAGE) .; \
	else \
		docker build -t $(DOCKER_IMAGE) . > /dev/null 2>&1; \
		echo "Docker image build completed."; \
	fi

# Run Docker container in interactive mode
run-interactive:
	@echo "Running Docker container in interactive mode..."
	@make run INTERACTIVE=true

# Run Docker container
run: clean
	@echo "Running Docker container..."
	@if [ "$(INTERACTIVE)" = "true" ]; then \
		docker run -it --env-file $(ENV_FILE) --name $(CONTAINER_NAME) -v $(WORKER_CONFIG):/home/udx/.cd/configs/worker.yml $(DOCKER_IMAGE) /bin/sh; \
	elif [ "$(DEBUG)" = "true" ]; then \
		docker run -d --env-file $(ENV_FILE) --name $(CONTAINER_NAME) $(DOCKER_IMAGE); \
		docker logs -f $(CONTAINER_NAME); \
	else \
		docker run -d --env-file $(ENV_FILE) --name $(CONTAINER_NAME) -v $(WORKER_CONFIG):/home/udx/.cd/configs/worker.yml $(DOCKER_IMAGE) > /dev/null 2>&1; \
		echo "Docker container run completed."; \
	fi

# Exec into the running container
exec:
	@echo "Executing into Docker container..."
	@if [ "$(DEBUG)" = "true" ]; then \
		docker exec -it $(CONTAINER_NAME) /usr/local/bin/test.sh; \
	else \
		docker exec -it $(CONTAINER_NAME) /usr/local/bin/test.sh > /dev/null 2>&1; \
		echo "Executed into Docker container."; \
	fi

# View the container logs
log:
	@echo "Viewing Docker container logs..."
	@if [ "$(DEBUG)" = "true" ]; then \
		docker logs $(CONTAINER_NAME); \
	else \
		docker logs $(CONTAINER_NAME) > /dev/null 2>&1; \
		echo "Docker container logs viewed."; \
	fi

# Delete the running container
clean:
	@echo "Deleting Docker container..."
	@if [ "$(DEBUG)" = "true" ]; then \
		docker rm -f $(CONTAINER_NAME); \
	else \
		docker rm -f $(CONTAINER_NAME) > /dev/null 2>&1; \
	fi

# Generate the .udx environment file
generate-env:
	@if [ -f $(ENV_FILE) ] && [ $(FORCE) = false ]; then \
		echo ".udx file already exists and FORCE is false. Not overwriting."; \
	else \
		echo "Generating .udx environment file..."; \
		echo "Enter key:value pairs for environment variables (leave key empty to finish):"; \
		touch $(ENV_FILE); \
		while true; do \
			read -p "Key: " key; \
			if [ -z "$$key" ]; then break; fi; \
			read -p "Value: " value; \
			echo "$$key=$$value" >> $(ENV_FILE); \
		done; \
		echo ".udx environment file generated successfully."; \
	fi

# Generate the worker.yml configuration file
generate-config:
	@if [ -f $(WORKER_CONFIG) ] && [ $(FORCE) = false ]; then \
		echo "worker.yml file already exists and FORCE is false. Not overwriting."; \
	else \
		echo "Generating worker.yml configuration file..."; \
		mkdir -p $(dir $(WORKER_CONFIG)); \
		touch $(WORKER_CONFIG); \
		echo "kind: workerConfig" > $(WORKER_CONFIG); \
		echo "version: udx.io/worker-v1/config" >> $(WORKER_CONFIG); \
		echo "config:" >> $(WORKER_CONFIG); \
		echo "  env:" >> $(WORKER_CONFIG); \
		echo "Enter key:value pairs for environment variables (leave key empty to finish):"; \
		while true; do \
			read -p "Key: " key; \
			if [ -z "$$key" ]; then break; fi; \
			read -p "Value: " value; \
			read -p "Is this a reference to an environment variable? (y/n): " ref; \
			if [ "$$ref" = "y" ]; then \
				echo "    $$key: \$$$${value}" >> $(WORKER_CONFIG); \
			else \
				echo "    $$key: $$value" >> $(WORKER_CONFIG); \
			fi; \
		done; \
		echo "  workerSecrets:" >> $(WORKER_CONFIG); \
		echo "Enter key:value pairs for workerSecrets (leave key empty to finish):"; \
		while true; do \
			read -p "Key: " key; \
			if [ -z "$$key" ]; then break; fi; \
			read -p "Value: " value; \
			echo "    $$key: $$value" >> $(WORKER_CONFIG); \
		done; \
		echo "  workerActors:" >> $(WORKER_CONFIG); \
		echo "Enter worker actors (type, subscription, tenant, application, password) (leave type empty to finish):"; \
		while true; do \
			read -p "Type: " type; \
			if [ -z "$$type" ]; then break; fi; \
			read -p "Subscription: " subscription; \
			read -p "Tenant: " tenant; \
			read -p "Application: " application; \
			read -p "Password: " password; \
			echo "    - type: $$type" >> $(WORKER_CONFIG); \
			echo "      subscription: $$subscription" >> $(WORKER_CONFIG); \
			echo "      tenant: $$tenant" >> $(WORKER_CONFIG); \
			echo "      application: $$application" >> $(WORKER_CONFIG); \
			echo "      password: $$password" >> $(WORKER_CONFIG); \
		done; \
		echo "worker.yml configuration file generated successfully."; \
	fi

# Run the validation tests
test: build run clean
	@echo "Validation tests completed."

# Development pipeline
dev-pipeline: generate-env generate-config build test
	@if [ "$(DEBUG)" = "true" ]; then \
		echo "Development pipeline completed successfully."; \
	else \
		echo "Development pipeline completed."; \
	fi