# General Makefile for UDX Worker

# Variables
IMAGE_NAME ?= udx-worker/udx-worker
TAG ?= latest
CONTAINER_NAME ?= udx-worker-container
ENV_FILE ?= ./.udx
DOCKER_IMAGE ?= $(IMAGE_NAME):$(TAG)
WORKER_CONFIG ?= $(if $(wildcard ./etc/configs/worker.yml),./etc/configs/worker.yml,./src/configs/worker.yml)

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "Usage:"
	@echo "  make build                 Build the Docker image"
	@echo "  make run                   Run the Docker container"
	@echo "  make run-interactive       Run the Docker container interactively"
	@echo "  make exec                  Exec into the running container"
	@echo "  make delete                Delete the running container"
	@echo "  make log                   View the container logs"
	@echo "  make gcr-login             Log in to Google Cloud Artifact Registry"
	@echo "  make generate-env          Generate the .udx environment file"
	@echo "  make pull                  Pull Docker image from repository"
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME (default: udx-worker/udx-worker)"
	@echo "  TAG (default: latest)"
	@echo "  CONTAINER_NAME (default: udx-worker-container)"
	@echo "  ENV_FILE (default: ./.udx)"
	@echo "  DOCKER_IMAGE (default: udx-worker/udx-worker:latest)"
	@echo "  WORKER_CONFIG (default: ./etc/configs/worker.yml or ./src/configs/worker.yml)"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make run"
	@echo "  make run-interactive"
	@echo "  make exec"
	@echo "  make delete"
	@echo "  make log"
	@echo "  make gcr-login"
	@echo "  make generate-env"
	@echo "  make pull DOCKER_IMAGE=myrepo/myimage:tag"

# Build the Docker image
build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(TAG) . || { echo "Docker build failed"; exit 1; }

# Run the Docker container
run:
	@echo "Running Docker container..."
	docker run --rm -d --name $(CONTAINER_NAME) --env-file $(ENV_FILE) $(IMAGE_NAME):$(TAG) || { echo "Failed to run Docker container"; exit 1; }

# Run the Docker container interactively
run-interactive:
	@echo "Running Docker container interactively..."
	docker run --rm -it --name $(CONTAINER_NAME) --env-file $(ENV_FILE) $(IMAGE_NAME):$(TAG) /bin/bash || { echo "Failed to run Docker container interactively"; exit 1; }

# Exec into the running container
exec:
	@echo "Executing into Docker container..."
	docker exec -it $(CONTAINER_NAME) bash || { echo "Failed to exec into Docker container"; exit 1; }

# Delete the running container
delete:
	@echo "Deleting Docker container..."
	docker rm -f $(CONTAINER_NAME) || { echo "Failed to delete Docker container"; exit 1; }

# View the container logs
log:
	@echo "Viewing Docker container logs..."
	docker logs $(CONTAINER_NAME) || { echo "Failed to view Docker container logs"; exit 1; }

# Log in to Google Cloud Artifact Registry
gcr-login:
	@echo "Logging into Google Cloud Artifact Registry..."
	@gcloud auth configure-docker || { echo "Failed to log into Google Cloud Artifact Registry"; exit 1; }

# Generate the .udx environment file
generate-env:
	@echo "Generating .udx environment file..."
	@read -p "Enter Azure Subscription ID: " AZURE_SUBSCRIPTION_ID; \
	read -p "Enter Azure Tenant ID: " AZURE_TENANT_ID; \
	read -p "Enter Azure Application ID: " AZURE_APPLICATION_ID; \
	read -p "Enter Azure Application Password: " AZURE_APPLICATION_PASSWORD; \
	echo "AZURE_SUBSCRIPTION_ID=$$AZURE_SUBSCRIPTION_ID" > $(ENV_FILE); \
	echo "AZURE_TENANT_ID=$$AZURE_TENANT_ID" >> $(ENV_FILE); \
	echo "AZURE_APPLICATION_ID=$$AZURE_APPLICATION_ID" >> $(ENV_FILE); \
	echo "AZURE_APPLICATION_PASSWORD=$$AZURE_APPLICATION_PASSWORD" >> $(ENV_FILE); \
	echo ".udx environment file generated successfully."

# Pull Docker image from repository
pull:
	@echo "Pulling Docker image: $(DOCKER_IMAGE)..."
	docker pull $(DOCKER_IMAGE) || { echo "Failed to pull Docker image"; exit 1; }
