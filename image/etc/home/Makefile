# General Makefile for UDX Worker

# How to Use the Makefile
#
# Build the Docker Image:
# make build
#
# Run the Docker Container:
# make run ENV_FILE=./path/to/your/env-file
#
# Run the Docker Container Interactively:
# make run-interactive ENV_FILE=./path/to/your/env-file
#
# Exec into the Running Container:
# make exec CONTAINER_NAME=my-container
#
# Delete the Running Container:
# make delete
#
# View the Container Logs:
# make log
#
# Log in to Google Cloud Artifact Registry:
# make gcr-login


# Variables
IMAGE_NAME = udx-worker/udx-worker
TAG = latest
CONTAINER_NAME = udx-worker-container
ENV_FILE ?= ./.udx

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
	@echo ""
	@echo "Variables:"
	@echo "  IMAGE_NAME (default: udx-worker/udx-worker)"
	@echo "  TAG (default: latest)"
	@echo "  CONTAINER_NAME (default: udx-worker-container)"
	@echo "  ENV_FILE (default: ./.udx)"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make run ENV_FILE=./path/to/your/env-file"
	@echo "  make run-interactive ENV_FILE=./path/to/your/env-file"
	@echo "  make exec CONTAINER_NAME=my-container"
	@echo "  make delete"
	@echo "  make log"
	@echo "  make gcr-login"

# Build the Docker image
build:
	docker build -t $(IMAGE_NAME):$(TAG) .

# Run the Docker container
run:
	docker run --rm -d --name $(CONTAINER_NAME) --env-file $(ENV_FILE) $(IMAGE_NAME):$(TAG)

# Run the Docker container interactively
run-interactive:
	docker run --rm -it --name $(CONTAINER_NAME) --env-file $(ENV_FILE) $(IMAGE_NAME):$(TAG) /bin/bash

# Exec into the running container
exec:
	docker exec -it $(CONTAINER_NAME) bash

# Delete the running container
delete:
	docker rm -f $(CONTAINER_NAME) || true

# View the container logs
log:
	docker logs $(CONTAINER_NAME)

# Log in to Google Cloud Artifact Registry
gcr-login:
	@gcloud auth configure-docker
