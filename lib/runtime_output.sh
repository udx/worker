#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
# shellcheck source=${WORKER_LIB_DIR}/worker_config.sh disable=SC1091
source "${WORKER_LIB_DIR}/worker_config.sh"

get_effective_env_value() {
    local name="$1"
    printenv "$name" 2>/dev/null || true
}

build_runtime_output_json() {
    local config_json="$1"
    local worker_config_path services_config_path env_json secrets_json

    worker_config_path=$(get_worker_config_path)
    services_config_path="${HOME}/.config/worker/services.yaml"
    if [[ ! -f "$services_config_path" && -f "${WORKER_CONFIG_DIR}/services.yaml" ]]; then
        services_config_path="${WORKER_CONFIG_DIR}/services.yaml"
    fi

    env_json=$(
        echo "$config_json" | jq -r '.config.env // {} | keys[]' 2>/dev/null | while IFS= read -r key; do
            [ -n "$key" ] || continue
            value=$(get_effective_env_value "$key")
            printf '%s\t%s\n' "$key" "$value"
        done | jq -Rn '
            reduce inputs as $line ({};
                ($line | split("\t")) as $parts |
                . + {($parts[0]): ($parts[1] // "")}
            )
        '
    )

    secrets_json=$(echo "$config_json" | jq '.config.secrets // {}' 2>/dev/null)

    jq -n \
        --arg worker_config_path "$worker_config_path" \
        --arg services_config_path "$services_config_path" \
        --arg worker_env_file "$WORKER_ENV_FILE" \
        --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson env "$env_json" \
        --argjson secrets "$secrets_json" \
        '{
            generated_at: $generated_at,
            paths: {
                worker_config: $worker_config_path,
                services_config: $services_config_path,
                environment: $worker_env_file
            },
            env: $env,
            secrets: $secrets,
            secret_values: "redacted"
        }'
}

emit_runtime_output() {
    local config_json runtime_json

    if [[ -z "${WORKER_OUTPUT_FILE:-}" ]]; then
        log_info "Runtime output disabled. Set WORKER_OUTPUT_FILE to write redacted JSON runtime config for workflow/deployment integrations."
        return 0
    fi

    config_json=$(load_and_parse_config) || return 1
    runtime_json=$(build_runtime_output_json "$config_json")

    mkdir -p "$(dirname "$WORKER_OUTPUT_FILE")" || return 1
    echo "$runtime_json" > "$WORKER_OUTPUT_FILE"
    log_info "Runtime output written to $WORKER_OUTPUT_FILE"
}
