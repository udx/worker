#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
# shellcheck source=${WORKER_LIB_DIR}/worker_config.sh disable=SC1091
source "${WORKER_LIB_DIR}/worker_config.sh"

WORKER_ENV_FILE="${WORKER_ENV_FILE:-/etc/worker/environment}"
WORKER_ENV_REDACTION_FILE="${WORKER_ENV_REDACTION_FILE:-${WORKER_ENV_FILE}.redacted}"

build_runtime_output_json() {
    local config_json="$1"
    local worker_config_path services_config_path env_json redacted_json

    worker_config_path=$(get_worker_config_path)
    services_config_path="${HOME}/.config/worker/services.yaml"
    if [[ ! -f "$services_config_path" && -f "${WORKER_CONFIG_DIR}/services.yaml" ]]; then
        services_config_path="${WORKER_CONFIG_DIR}/services.yaml"
    fi

    env_json=$(build_runtime_env_json "$config_json") || return 1
    redacted_json=$(build_runtime_redacted_json "$config_json") || return 1

    jq -n \
        --arg worker_config_path "$worker_config_path" \
        --arg services_config_path "$services_config_path" \
        --arg worker_env_file "$WORKER_ENV_FILE" \
        --arg generated_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
        --argjson env "$env_json" \
        --argjson redacted "$redacted_json" \
        '{
            generated_at: $generated_at,
            paths: {
                worker_config: $worker_config_path,
                services_config: $services_config_path,
                environment: $worker_env_file
            },
            env: $env,
            redacted: $redacted
        }'
}

is_runtime_output_redacted_name() {
    local config_json="$1"
    local name="$2"

    if [[ -f "$WORKER_ENV_REDACTION_FILE" ]] && grep -Fxq "$name" "$WORKER_ENV_REDACTION_FILE"; then
        return 0
    fi

    echo "$config_json" | jq -e --arg name "$name" --arg pattern "^(${SUPPORTED_SECRET_PROVIDERS})/.+/.+" '
        (.config.secrets // {} | has($name)) or
        ((.config.env // {} | .[$name] // "" | tostring) | test($pattern))
    ' >/dev/null
}

build_runtime_env_json() {
    local config_json="$1"
    local names name value json

    if [[ ! -f "$WORKER_ENV_FILE" ]]; then
        log_error "Runtime output" "Environment file not found: $WORKER_ENV_FILE"
        return 1
    fi

    names=$(grep "^export " "$WORKER_ENV_FILE" | cut -d'=' -f1 | cut -d' ' -f2)
    json="{}"
    while IFS= read -r name; do
        if [[ -z "$name" ]] || is_runtime_output_redacted_name "$config_json" "$name"; then
            continue
        fi

        value=$(get_env_value "$name") || return 1
        json=$(echo "$json" | jq --arg key "$name" --arg value "$value" '. + {($key): $value}') || return 1
    done <<< "$names"

    echo "$json" | jq -S .
}

build_runtime_redacted_json() {
    local config_json="$1"
    local names name json

    if [[ ! -f "$WORKER_ENV_FILE" ]]; then
        log_error "Runtime output" "Environment file not found: $WORKER_ENV_FILE"
        return 1
    fi

    names=$(grep "^export " "$WORKER_ENV_FILE" | cut -d'=' -f1 | cut -d' ' -f2)
    json="[]"
    while IFS= read -r name; do
        if [[ -n "$name" ]] && is_runtime_output_redacted_name "$config_json" "$name"; then
            json=$(echo "$json" | jq --arg name "$name" '. + [$name]') || return 1
        fi
    done <<< "$names"

    echo "$json" | jq -S 'unique'
}

runtime_output_log_enabled() {
    case "${WORKER_OUTPUT_LOG:-false}" in
        true|TRUE|1|yes|YES|on|ON)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

emit_runtime_output_log() {
    local runtime_json="$1"
    local compact_json

    compact_json=$(echo "$runtime_json" | jq -c .) || return 1
    printf 'WORKER_RUNTIME_OUTPUT_JSON=%s\n' "$compact_json"
}

emit_runtime_output() {
    local config_json runtime_json

    if [[ -z "${WORKER_OUTPUT_FILE:-}" ]] && ! runtime_output_log_enabled; then
        log_info "Runtime output disabled. Set WORKER_OUTPUT_FILE or WORKER_OUTPUT_LOG=true to emit redacted JSON runtime config for workflow/deployment integrations."
        return 0
    fi

    config_json=$(load_and_parse_config) || return 1
    if ! runtime_json=$(build_runtime_output_json "$config_json"); then
        log_error "Runtime output" "Failed to build runtime output JSON"
        return 1
    fi

    if [[ -n "${WORKER_OUTPUT_FILE:-}" ]]; then
        mkdir -p "$(dirname "$WORKER_OUTPUT_FILE")" || return 1
        install -m 600 /dev/null "$WORKER_OUTPUT_FILE" || return 1
        printf '%s\n' "$runtime_json" > "$WORKER_OUTPUT_FILE"
        log_info "Runtime output written to $WORKER_OUTPUT_FILE"
    fi

    if runtime_output_log_enabled; then
        emit_runtime_output_log "$runtime_json" || return 1
    fi
}
