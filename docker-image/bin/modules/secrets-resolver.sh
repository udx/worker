#!/bin/bash
#
# Secrets Resolver
# This module is responsible for resolving secrets from the cloud secret manager
# and setting them as environment variables
#
#

echo "Secrets Resolver module loaded..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "gcloud is not installed. Please install gcloud before running this script."
    exit 1
fi

# Check if gcloud is authenticated
if ! gcloud auth list &> /dev/null; then
    echo "gcloud is not authenticated. Please authenticate gcloud before running this script."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install jq before running this script."
    exit 1
fi

# Resolve secret from GCP Secret Manager
resolve_secret() {
    project_id=$1
    secret_id=$2
    version=${3:-latest}
    
    if [[ -z $project_id || -z $secret_id ]]; then
        echo "Project ID or Secret ID is empty"
        exit 1
    fi
    
    if [[ $version == "latest" ]]; then
        secret_version=$(gcloud secrets versions access latest --secret=$secret_id --project=$project_id)
    else
        secret_version=$(gcloud secrets versions access $version --secret=$secret_id --project=$project_id)
    fi
    
    if [[ -z $secret_version ]]; then
        echo "Failed to resolve secret"
        exit 1
    fi
    
    echo $secret_version
}

# Parse YML config file and resolve secrets by refs
#
#

resolve_secrets() {
    config_file=$1
    
    if [[ -z $config_file ]]; then
        echo "Config file is empty"
        exit 1
    fi
    
    if [[ ! -f $config_file ]]; then
        echo "Config file not found"
        exit 1
    fi
    
    # Parse YML config file
    config_data=$(cat $config_file | yq r -)
    
    # Extract secrets from config data
    secrets=$(echo $config_data | yq r - 'data.*' | grep '<')
    
    for secret in $secrets; do
        secret_key=$(echo $secret | cut -d':' -f1)
        secret_ref=$(echo $secret | cut -d':' -f2 | tr -d '<>')
        
        secret_value=$(resolve_secret $secret_ref)
        
        if [[ -z $secret_value ]]; then
            echo "Failed to resolve secret: $secret_key"
            exit 1
        fi
        
        export $secret_key=$secret_value
    done
}

# Parse YAML and set environment variables
parse_yaml_and_set_env() {
    local yaml_file=$1
    local kind=$2

    # Parse YAML with yq and iterate over keys and values
    yq e ".$kind.data | keys[]" $yaml_file | while read -r key; do
        # Get value
        local value=$(yq e ".$kind.data.$key" $yaml_file)

        # If value is a URL, resolve secret
        if [[ $value == http* ]]; then
            # Extract project ID and secret ID from URL
            local project_id=$(echo $value | cut -d'/' -f4)
            local secret_id=$(echo $value | cut -d'/' -f6)

            # Resolve secret
            value=$(resolve_secret $project_id $secret_id)
        fi

        # Export environment variable
        eval export $key='$value'
    done
}

# Use the function
parse_yaml_and_set_env worker.yml workerSecrets
parse_yaml_and_set_env worker.yml workerActors
parse_yaml_and_set_env worker.yml workerVariables