#!/bin/sh

# Function to authenticate AWS role
aws_authenticate() {
    local actor=$1
    local role_arn=$(echo "$actor" | yq e '.value.role_arn' -)
    local session_name=$(echo "$actor" | yq e '.value.session_name' -)

    echo "Authenticating AWS role: $role_arn"
    aws sts assume-role --role-arn "$role_arn" --role-session-name "$session_name"
}
