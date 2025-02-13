# Include variables and help modules
include Makefile.variables
include Makefile.help

# Default target
.DEFAULT_GOAL := help

.PHONY: run run-it clean build exec log test dev-pipeline

# Use BuildKit for better output
export DOCKER_BUILDKIT=1


.SILENT: build run run-it clean exec log test dev-pipeline

# Common shell function for error handling and output
define exec_with_status
@bash -c 'set -eo pipefail; \
	printf "$(COLOR_BLUE)$(SYM_ARROW) %s$(COLOR_RESET)\n" "$(1)"; \
	{ $(2); } && \
		printf "$(COLOR_GREEN)$(SYM_SUCCESS) %s$(COLOR_RESET)\n" "$(3)" || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) %s$(COLOR_RESET)\n" "$(4)"; exit 1; }'
endef

build:
	@bash -c 'set -eo pipefail; \
		filter="(error|Error|ERROR|failed|Failed|FAILED|\\[.*[0-9]+/[0-9]+\\]|^#[0-9]+ DONE|sha256|CACHED)"; \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Starting Docker build...$(COLOR_RESET)\n"; \
		if [ "$(MULTIPLATFORM)" = "true" ]; then \
			printf "$(COLOR_BLUE)$(SYM_ARROW) Building for multiple platforms: [linux/amd64, linux/arm64]$(COLOR_RESET)\n"; \
			docker buildx build --progress=plain \
				--platform linux/amd64,linux/arm64 \
				-t $(DOCKER_IMAGE) \
				--load . 2>&1 | grep -E "$$filter" || exit 1; \
		else \
			printf "$(COLOR_BLUE)$(SYM_ARROW) Building for local platform$(COLOR_RESET)\n"; \
			DOCKER_BUILDKIT=1 docker build \
				--progress=plain \
				-t $(DOCKER_IMAGE) . 2>&1 | grep -E "$$filter" || exit 1; \
		fi && \
		printf "$(COLOR_GREEN)$(SYM_SUCCESS) Docker image build completed$(COLOR_RESET)\n" || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) Docker build failed$(COLOR_RESET)\n"; exit 1; }'

run: clean
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Starting container...$(COLOR_RESET)\n"
	@if [ ! -f $(ENV_FILE) ]; then \
		printf "$(COLOR_YELLOW)$(SYM_WARNING) Creating environment file...$(COLOR_RESET)\n" && \
		touch $(ENV_FILE); \
	fi
	@docker run $(if $(INTERACTIVE),-it,-d) --rm --name $(CONTAINER_NAME) \
		--env-file $(ENV_FILE) \
		$(foreach vol,$(VOLUMES),-v $(vol)) \
		$(DOCKER_IMAGE) $(COMMAND)
	@if [ "$(INTERACTIVE)" = "true" ]; then \
		:; \
	else \
		printf "$(COLOR_BLUE)$(SYM_ARROW) Container started in detached mode. Use 'make log' to view logs$(COLOR_RESET)\n"; \
	fi
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Container started successfully$(COLOR_RESET)\n"

run-it:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Starting interactive container...$(COLOR_RESET)\n"
	@$(MAKE) run INTERACTIVE=true COMMAND=/bin/bash
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Interactive container started$(COLOR_RESET)\n"

exec:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Executing into container...$(COLOR_RESET)\n"
	@docker exec -it $(CONTAINER_NAME) /bin/bash || \
		{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to execute into container$(COLOR_RESET)\n"; exit 1; }
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Successfully executed into container$(COLOR_RESET)\n"

log:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Fetching container logs...$(COLOR_RESET)\n"
	@if [ "$(FOLLOW_LOGS)" = "true" ]; then \
		docker logs -f $(CONTAINER_NAME) || \
			{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to retrieve logs$(COLOR_RESET)\n"; exit 1; }; \
	else \
		docker logs $(CONTAINER_NAME) || \
			{ printf "$(COLOR_RED)$(SYM_ERROR) Failed to retrieve logs$(COLOR_RESET)\n"; exit 1; }; \
	fi
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Logs retrieved successfully$(COLOR_RESET)\n"

clean:
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Cleaning up containers...$(COLOR_RESET)\n"
	@docker stop $(CONTAINER_NAME) 2>/dev/null || true
	@docker rm -f $(CONTAINER_NAME) 2>/dev/null || true
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Cleanup completed$(COLOR_RESET)\n"

test: clean
	@printf "$(COLOR_BLUE)$(SYM_ARROW) Running tests...$(COLOR_RESET)\n"
	@$(MAKE) run \
		VOLUMES="$(TEST_WORKER_CONFIG):/home/$(USER)/worker.yaml:ro $(TEST_SERVICES_CONFIG):/home/$(USER)/services.yaml:ro $(TESTS_TASKS_DIR):/home/$(USER)/tasks:ro $(TESTS_MAIN_SCRIPT):/home/$(USER)/main.sh:ro" \
		COMMAND="/home/$(USER)/main.sh" || exit 1
	@$(MAKE) log FOLLOW_LOGS=true || exit 1
	@$(MAKE) clean || exit 1
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Tests completed successfully$(COLOR_RESET)\n"

dev-pipeline: build test
	@printf "$(COLOR_GREEN)$(SYM_SUCCESS) Development pipeline completed successfully$(COLOR_RESET)\n"