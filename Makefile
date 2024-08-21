# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

# Docker-related variables
DOCKER_IMAGE := udx-worker
CONTAINER_NAME := udx-worker-container

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
run-it:
	@echo "Running Docker container in interactive mode..."
	@$(MAKE) run INTERACTIVE=true

# Run Docker container
run: clean
	@echo "Running Docker container..."
	# Check if the worker config file exists and is a file
	@if [ ! -f src/configs/worker.yml ]; then \
		echo "[ERROR] Worker config file does not exist: src/configs/worker.yml" >&2; \
		exit 1; \
	fi

	# Run the container
	@if [ "$(INTERACTIVE)" = "true" ]; then \
		docker run -it --name $(CONTAINER_NAME) \
			-v $(shell pwd)/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml \
			$(DOCKER_IMAGE) /bin/sh; \
	else \
		docker run -d --name $(CONTAINER_NAME) \
			-v $(shell pwd)/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml \
			$(DOCKER_IMAGE); \
		@if [ "$(DEBUG)" = "true" ]; then \
			docker logs -f $(CONTAINER_NAME); \
		else \
			docker logs $(CONTAINER_NAME) > /dev/null 2>&1; \
			echo "Docker container run completed."; \
		fi \
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
		echo "Docker container deleted."; \
	fi

# Run the validation tests
test: build run clean
	@echo "Validation tests completed."

# Development pipeline
dev-pipeline: build test
	@if [ "$(DEBUG)" = "true" ]; then \
		echo "Development pipeline completed successfully."; \
	else \
		echo "Development pipeline completed."; \
	fi
