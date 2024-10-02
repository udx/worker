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
		echo "Building Docker image for multiple platforms..."; \
		docker buildx build --platform linux/amd64,linux/arm64 -t $(DOCKER_IMAGE) --push .; \
	else \
		echo "Building Docker image for the local platform..."; \
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
	@docker rm -f $(CONTAINER_NAME) || true

# Run the validation tests
test: build run clean
	@echo "Validation tests completed."

# Development pipeline
dev-pipeline: build test
	@echo "Development pipeline completed successfully."
