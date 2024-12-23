#!/bin/bash

echo "Starting validation of authorization..."

# Path to the merged configuration file
MERGED_CONFIG="/home/${USER}/.cd/configs/merged_worker.yml"

# Test authenticate_actors function
test_authenticate_actors() {
    
    # Check if the MERGED_CONFIG variable is set and the file exists
    if [[ -z "$MERGED_CONFIG" ]]; then
        echo "[ERROR] MERGED_CONFIG variable is not set."
        return 1
        elif [[ ! -f "$MERGED_CONFIG" ]]; then
        echo "[ERROR] Merged configuration file not found: $MERGED_CONFIG"
        return 1
    fi
    
    merged_config=$(cat "$MERGED_CONFIG")
    
    # Extract actors from the merged configuration
    actors=$(echo "$merged_config" | yq eval -o=json '.config.actors' - | jq -c '.[] | .type')
    
    # Check provider-specific authorization using CLI if authorized
    for actor_type in $actors; do
        provider=$(echo "$actor_type" | cut -d '-' -f 1 | tr -d '"')
        env_var_name="${provider^^}_AUTHORIZED"
        
        # Check if the environment variable exists and its value is "true"
        if [[ ${!env_var_name} == "true" ]]; then

            echo "$provider must be authorized. Checking authentication status..."

       case "$provider" in
                azure)
                    if az account show > /dev/null 2>&1; then
                        echo "az is authorized."
                    else
                        echo "az authorization failed."
                    fi
                ;;
                gcp)
                    if gcloud auth list > /dev/null 2>&1; then
                        echo "gcloud is authorized."
                    else
                        echo "gcloud authorization failed."
                    fi
                ;;
                aws)
                    if aws sts get-caller-identity > /dev/null 2>&1; then
                        echo "aws is authorized."
                    else
                        echo "aws authorization failed."
                    fi
                ;;
                bitwarden)
                    if bw status > /dev/null 2>&1; then
                        echo "bw is authorized."
                    else
                        echo "bw authorization failed."
                    fi
                ;;
                *)
                    echo "Unsupported provider: $provider"
                ;;
            esac
        else
            echo "Skipping provider-specific authorization check for $provider as it was not marked as authorized."
        fi
    done
    
    echo "Test passed: authenticate_actors"
}

# Run the test
if test_authenticate_actors; then
    echo "Authorization tests passed successfully."
else
    echo "Authorization tests failed."
    exit 1
fi