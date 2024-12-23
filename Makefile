# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build stringify-creds exec log test dev-pipeline

# Automatically detect JSON credentials file, stringify its content, and set it as an environment variable
stringify-creds:
	@echo "#!/bin/sh" > creds_env.sh
	@for file in *.json; do \
		if [ -f "$$file" ]; then \
			CREDS_VAR_NAME=$$(echo "$$file" | sed -e 's/\.json//g' -e 's/\./_/g' | tr '[:lower:]' '[:upper:]'); \
			CREDS_VAR_VALUE=$$(cat "$$file" | jq -c .); \
			echo "export $$CREDS_VAR_NAME='$$CREDS_VAR_VALUE'" >> creds_env.sh; \
			echo "Setting $$CREDS_VAR_NAME environment variable..."; \
		else \
			echo "No JSON credential files found. Skipping..."; \
		fi; \
	done
	@chmod +x creds_env.sh

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
	@. ./creds_env.sh && docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		$(foreach var,$(shell . ./creds_env.sh && env | grep -E '^[A-Z_]+_CREDS=' | cut -d= -f1),-e $(var)=$$$(var)) \
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