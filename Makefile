# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build exec log test dev-pipeline

# Build the Docker image
MULTIPLATFORM ?= false

# Use BuildKit for better output
export DOCKER_BUILDKIT=1

# Colors for better visibility
COLOR_RESET=\033[0m
COLOR_BLUE=\033[34m
COLOR_GREEN=\033[32m

.SILENT: build
build:
	@bash -c 'set -eo pipefail; \
		filter="(error|Error|ERROR|failed|Failed|FAILED|\\[.*[0-9]+/[0-9]+\\]|^#[0-9]+ DONE|sha256|CACHED)"; \
		printf "\033[34m➜ Starting Docker build...\033[0m\n"; \
		if [ "$(MULTIPLATFORM)" = "true" ]; then \
			printf "\033[34m➜ Building for multiple platforms: [linux/amd64, linux/arm64]\033[0m\n"; \
			docker buildx build --progress=plain \
				--platform linux/amd64,linux/arm64 \
				-t $(DOCKER_IMAGE) \
				--load . 2>&1 | grep -E "$$filter" || exit 1; \
		else \
			printf "\033[34m➜ Building for local platform\033[0m\n"; \
			DOCKER_BUILDKIT=1 docker build \
				--progress=plain \
				-t $(DOCKER_IMAGE) . 2>&1 | grep -E "$$filter" || exit 1; \
		fi && \
		printf "\033[32m✔ Docker image build completed\033[0m\n" || \
		{ printf "\033[31m✖ Docker build failed\033[0m\n"; exit 1; }'

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
	@$(MAKE) run VOLUMES="$(TEST_WORKER_CONFIG):/home/$(USER)/worker.yaml:ro $(TEST_SERVICES_CONFIG):/home/$(USER)/services.yaml:ro $(TESTS_TASKS_DIR):/home/$(USER)/tasks:ro $(TESTS_MAIN_SCRIPT):/home/$(USER)/main.sh:ro ./src/tests/utils.sh:/usr/local/tests/utils.sh:ro" COMMAND="/home/$(USER)/main.sh"
	@$(MAKE) log FOLLOW_LOGS=true
	@$(MAKE) clean

# Development pipeline
dev-pipeline: build test
	@echo "Development pipeline completed successfully."