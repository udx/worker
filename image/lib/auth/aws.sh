#!/bin/sh

# Function to authenticate AWS role
aws_authenticate() {
    local actor=$1
    local role_arn=$(resolve_env_vars "$(echo "$actor" | jq -r '.role_arn')")
    local session_name=$(resolve_env_vars "$(echo "$actor" | jq -r '.session_name')")

    echo "[INFO] Authenticating AWS role: $role_arn"

    # Assume the role
    aws sts assume-role --role-arn "$role_arn" --role-session-name "$session_name" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to assume AWS role: $role_arn"
        return 1
    fi

    echo "[INFO] AWS role authentication successful for role: $role_arn"
    return 0
}

# Include utility functions
. /usr/local/lib/utils.sh

# Initialize the AWS auth module
init_aws_auth() {
    echo "[INFO] Initializing AWS auth module"
}

# Execute authentication if script is called directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    authenticate_actors
fi