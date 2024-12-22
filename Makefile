# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build stringify-creds exec log test dev-pipeline

# Automatically detect JSON credentials file, stringify its content, and set it as an environment variable
stringify-creds:
	@for file in *.json; do \
		if [ -f "$$file" ]; then \
			CREDS_VAR_NAME=$$(echo "$$file" | sed -e 's/\.json//g' -e 's/\./_/g' | tr '[:lower:]' '[:upper:]'); \
			CREDS_VAR_VALUE=$$(cat "$$file" | jq -c .); \
			echo "Setting $$CREDS_VAR_NAME environment variable..."; \
			export $$CREDS_VAR_NAME="$$CREDS_VAR_VALUE"; \
		else \
			echo "No JSON credential files found. Skipping..."; \
		fi \
	done

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
run: clean stringify-creds
	@echo "Running Docker container..."
	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		$(foreach file,$(wildcard *.json),-e $(shell echo $(file) | sed -e 's/\.json//g' -e 's/\./_/g' | tr '[:lower:]' '[:upper:]')="$$(cat $(file) | jq -c .)") \
		$(DOCKER_IMAGE) $(if $(INTERACTIVE),sh)
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
	@docker logs $(CONTAINER_NAME)

# Delete the running container
clean:
	@echo "Deleting Docker container if exists..."
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true

# Run the validation tests
test: clean stringify-creds
	@echo "Setting WORKER_CONFIG to tests/configs/worker.yml..."
	@WORKER_CONFIG=tests/configs/worker.yml
	@echo "Running Docker container to execute tests..."
	@docker run --rm --name $(CONTAINER_NAME) \
		-v $(WORKER_CONFIG):/home/udx/.cd/configs/worker.yml:ro \
		$(foreach file,$(wildcard *.json),-e $(shell echo $(file) | sed -e 's/\.json//g' -e 's/\./_/g' | tr '[:lower:]' '[:upper:]')="$$(cat $(file) | jq -c .)") \
		$(DOCKER_IMAGE) /usr/local/tests/main.sh
	@echo "Validation tests completed."
	@$(MAKE) clean

# Development pipeline
dev-pipeline: build test
	@echo "Development pipeline completed successfully."