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
		docker buildx build --platform linux/amd64,linux/arm64 -t $(DOCKER_IMAGE) .; \
	else \
		echo "Only local platform..."; \
		docker build -t $(DOCKER_IMAGE) .; \
	fi
	@echo "Docker image build completed."

# Run Docker container (supports interactive mode)
run: clean
	@echo "Running Docker container..."
	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		$(foreach file,$(wildcard *.json),\
			$(eval CREDS_VAR_NAME=$(shell echo "$(file)" | sed -e 's/\.json//g' -e 's/\./_/g' | tr '[:lower:]' '[:upper:]')) \
			$(eval CREDS_VAR_VALUE=$(shell cat "$(file)" | jq -c .)) \
			-e $(CREDS_VAR_NAME)='$(CREDS_VAR_VALUE)' \
		) \
		$(foreach env_var,$(filter %_CREDS,$(.VARIABLES)),\
			-e $(env_var)=$($(env_var)) \
		) \
		$(foreach vol,$(VOLUMES),-v $(vol)) \
		$(DOCKER_IMAGE) $(COMMAND)
	$(if $(filter false,$(INTERACTIVE)),docker logs -f $(CONTAINER_NAME);)

# Run Docker container in interactive mode
run-it:
	@$(MAKE) run INTERACTIVE=true

# Exec into the running container
exec:
	@echo "Executing into Docker container..."
	@docker exec -it $(CONTAINER_NAME) /bin/sh

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
test: VOLUMES=$(TEST_WORKER_CONFIG):/home/udx/.cd/configs/worker.yml:ro
test: COMMAND=/usr/local/tests/main.sh
test: run
	@$(MAKE) log FOLLOW_LOGS=true
	@$(MAKE) clean

# Development pipeline
dev-pipeline: build test
	@echo "Development pipeline completed successfully."