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

	@echo "Detecting JSON credentials files..."
	$(eval JSON_CREDS_ENV := $(shell \
		for file in $(wildcard *.json); do \
			CREDS_VAR_NAME=$$(echo "$${file}" | sed -e 's/\.json//g' -e 's/\./_/g' | tr '[:lower:]' '[:upper:]'); \
			CREDS_VAR_VALUE=$$(cat "$${file}" | jq -c .); \
			echo "-e $${CREDS_VAR_NAME}='$${CREDS_VAR_VALUE}'"; \
		done \
	))

	@echo "Detecting host environment credentials..."
	$(eval CREDS_ENV := $(shell bash -c '\
		for env_var in $(filter %_CREDS,$(.VARIABLES)); do \
			creds_value=$${!env_var}; \
			creds_value_escaped=$$(printf "%q" "$${creds_value}"); \
			echo "-e $${env_var}=$${creds_value_escaped}"; \
		done \
	'))

	@echo "Setting Docker volumes if any..."
	$(eval DOCKER_VOLUMES := $(if $(VOLUMES),\
		$(foreach vol,$(VOLUMES),-v $(vol)) \
	))

	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		$(JSON_CREDS_ENV) \
		$(CREDS_ENV) \
		$(DOCKER_VOLUMES) \
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
test: VOLUMES=$(TEST_WORKER_CONFIG):/home/udx/.cd/configs/worker.yml:ro
test: COMMAND=/usr/local/tests/main.sh
test: run
	@$(MAKE) log FOLLOW_LOGS=true
	@$(MAKE) clean

# Development pipeline
dev-pipeline: build test
	@echo "Development pipeline completed successfully."