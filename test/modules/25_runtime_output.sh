#!/bin/bash

# Source test helpers
# shellcheck source=../test_helpers.sh disable=SC1091
source "/home/udx/test/test_helpers.sh"

print_header "Runtime Output Tests"

# shellcheck source=/home/udx/lib/runtime_output.sh disable=SC1091
source "${WORKER_LIB_DIR}/runtime_output.sh"

print_info "Testing: runtime output redacts configured secrets"
RUNTIME_ENV_FILE=$(mktemp)
ORIGINAL_WORKER_ENV_FILE="$WORKER_ENV_FILE"
ORIGINAL_WORKER_ENV_REDACTION_FILE="${WORKER_ENV_REDACTION_FILE:-}"
export WORKER_ENV_FILE="$RUNTIME_ENV_FILE"
export WORKER_ENV_REDACTION_FILE="${RUNTIME_ENV_FILE}.redacted"

{
    printf 'export PUBLIC_VALUE=%q\n' "visible value"
    printf 'export CONFIG_SECRET=%q\n' "resolved secret"
    printf 'export CONFIG_REF=%q\n' "resolved reference"
    printf 'export DEPLOYMENT_SECRET=%q\n' "resolved deployment secret"
} > "$WORKER_ENV_FILE"
reset_env_redactions
mark_env_value_redacted "DEPLOYMENT_SECRET"
upsert_env_value "DEPLOYMENT_SECRET_TWO" "resolved deployment secret two"
mark_env_value_redacted "DEPLOYMENT_SECRET_TWO"

CONFIG_JSON='{
  "config": {
    "env": {
      "PUBLIC_VALUE": "visible value",
      "CONFIG_REF": "gcp/project-id/secret-name"
    },
    "secrets": {
      "CONFIG_SECRET": "aws/secret-name/us-west-2"
    }
  }
}'

RUNTIME_OUTPUT=$(build_runtime_output_json "$CONFIG_JSON")
export WORKER_ENV_FILE="$ORIGINAL_WORKER_ENV_FILE"
if [[ -n "$ORIGINAL_WORKER_ENV_REDACTION_FILE" ]]; then
    export WORKER_ENV_REDACTION_FILE="$ORIGINAL_WORKER_ENV_REDACTION_FILE"
else
    unset WORKER_ENV_REDACTION_FILE
fi
rm -f "$RUNTIME_ENV_FILE" "${RUNTIME_ENV_FILE}.redacted"

if ! echo "$RUNTIME_OUTPUT" | jq -e '.env.PUBLIC_VALUE == "visible value"' >/dev/null; then
    print_error "runtime output missing non-secret env value"
    exit 1
fi

if echo "$RUNTIME_OUTPUT" | jq -e '.env.CONFIG_SECRET or .env.CONFIG_REF or .env.DEPLOYMENT_SECRET or .env.DEPLOYMENT_SECRET_TWO' >/dev/null; then
    print_error "runtime output leaked a redacted env value"
    exit 1
fi

if ! echo "$RUNTIME_OUTPUT" | jq -e '.redacted == ["CONFIG_REF", "CONFIG_SECRET", "DEPLOYMENT_SECRET", "DEPLOYMENT_SECRET_TWO"]' >/dev/null; then
    print_error "runtime output redacted list is incorrect"
    exit 1
fi

LOG_LINE=$(WORKER_OUTPUT_LOG=true emit_runtime_output_log "$RUNTIME_OUTPUT")
if [[ "$LOG_LINE" != WORKER_RUNTIME_OUTPUT_JSON=* ]]; then
    print_error "runtime output log marker is missing"
    exit 1
fi

if ! echo "${LOG_LINE#WORKER_RUNTIME_OUTPUT_JSON=}" | jq -e '.env.PUBLIC_VALUE == "visible value"' >/dev/null; then
    print_error "runtime output log JSON is invalid"
    exit 1
fi

print_success "All runtime output tests passed"
