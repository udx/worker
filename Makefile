# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build exec log test dev-pipeline

# Build the Docker image
MULTIPLATFORM ?= false

build:
	@echo "Building Docker image..."
	@if [ "$(MULTIPLATFORM)" = "true" ]; then \
		echo "Multiple platforms: [linux/amd64, linux/arm64]..."; \
		docker buildx build --platform linux/amd64,linux/arm64 -t $(DOCKER_IMAGE) --load .; \
	else \
		echo "Only local platform..."; \
		docker build -t $(DOCKER_IMAGE) .; \
	fi
	@echo "Docker image build completed."

# Run Docker container (supports interactive mode)
run: clean
	@echo "Running Docker container..."

	@if [ ! -f $(ENV_FILE) ]; then \
		echo "Creating environment file..."; \
		touch $(ENV_FILE); \
	else \
		echo "Environment file exists..."; \
	fi

	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		--env-file $(ENV_FILE) \
		$(foreach vol,$(VOLUMES),-v $(vol)) \
		$(DOCKER_IMAGE) $(COMMAND)
	$(if $(filter false,$(INTERACTIVE)),docker logs -f $(CONTAINER_NAME);)

# Run Docker container in interactive mode
run-it:
	@$(MAKE) run INTERACTIVE=true COMMAND=/bin/bash

# Exec into the running container
exec:
	@echo "Executing into Docker container..."
	@docker exec -it $(CONTAINER_NAME) /bin/bash

# View the container logs
log:
	@echo "Viewing Docker container logs..."
	@if [ "$(FOLLOW_LOGS)" = "true" ]; then \
		docker logs -f $(CONTAINER_NAME); \
	else \
		docker logs $(CONTAINER_NAME); \
	fi

# Delete the running container
clean:
	@echo "Deleting Docker container if exists..."
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true

# Test Docker container
test: clean
	@echo "Setting up test environment..."
	@$(MAKE) run VOLUMES="$(TEST_WORKER_CONFIG):/home/$(USER)/worker.yaml:ro $(TESTS_TASKS_DIR):/home/$(USER)/tasks:ro $(TESTS_MAIN_SCRIPT):/home/$(USER)/main.sh:ro" COMMAND="/home/$(USER)/main.sh"
	@$(MAKE) log FOLLOW_LOGS=true
	@$(MAKE) clean

# Development pipeline
dev-pipeline: build test
	@echo "Development pipeline completed successfully."