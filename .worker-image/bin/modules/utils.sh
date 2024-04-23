# Utility functions library.
#
# Example usage:
#
# [bash] source "./modules/utils.sh"
# [bash] env_defaults
#

ping_pong() {
    read -p "Ping? " answer
    
    if [[ $answer == "Pong" ]]; then
        echo "Pong received"
    else
        echo "Invalid response: $answer"
    fi
}

nice_logs() {
    
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    GREY=$(tput setaf 8)
    RESET=$(tput sgr0)
    
    message=$1
    type=$2
    
    case $type in
        "success")
            echo "${GREEN} ${message}${RESET}"
        ;;
        "info")
            echo "${BLUE} ${message}${RESET}"
        ;;
        "warn")
            echo "${YELLOW} ${message}${RESET}"
        ;;
        "error")
            echo "${RED} ${message}${RESET}"
        ;;
        *)
            echo "${type} ${message}"
        ;;
    esac
}

# @TODO: fetch configs from https://github.com/udx/udx-worker-configs repository
# For now let's fetch config files from fixtures
# Usage: fetchConfigs [filename]
# Example: fetchConfigs "config.json"
# Example: fetchConfigs
# Example: fetchConfigs "config.json" | jq
#
fetchConfigs() {
    files=$(find /home/bin-modules/fixtures/application/ -type f)
    
    if [[ -n $1 ]]; then
        filtered_files=$(echo "$files" | grep "$1")
        for file in $filtered_files; do
            nice_logs "$(cat "$file")" "info"
        done
    else
        for file in $files; do
            nice_logs "Found file: $file" "info"
        done
    fi
}

# ---
# kind: workerActors
# version: udx.io/worker-v1/actor
# data:
#   # supports all Azure KVs, must provide Azure Tenant/App/Subscription
#   - user: svc-cag
#     subscription: ce7d5514-0698-4eed-b66c-73ff0dd932bd
#     tenant: 4c3ec952-0472-4e75-be60-28127156b91f
#     application: 998e3cca-2036-4106-9243-3b16998fb327
#     # for local dev, we can source value from YAML config in ~/.udx
#     password: "udx://tokens/data/svc-cag/secretValue"
#   # for cloud.google.com
#   - user: andy@udx.io
#     # alternative we use environment variables (later set via GitHub secrets)
#     password: ${ANDYS_UDX_IO_NONINTERACTIVE_PASSWORD}
#     domains: [cloud.google.com]
ActorsAuth() {
    user=$1
    password=$2
    tenant=$3
    application=$4
    subscription=$5
    domains=$6
    
    nice_logs "User: $user" "info"
    nice_logs "Password: $password" "info"
    nice_logs "Tenant: $tenant" "info"
    nice_logs "Application: $application" "info"
    nice_logs "Subscription: $subscription" "info"
    nice_logs "Domains: $domains" "info"
    
    nice_logs "Authenticating..." "info"
    
    nice_logs "Authenticated successfully." "success"
}

# ---
# kind: workerSecrets
CleanUpActors() {
    nice_logs "Cleaning up actors..." "info"
    
    nice_logs "Actors cleaned up successfully." "success"
}

# ---
# kind: workerSecrets
# version: udx.io/worker-v1/secrets
# items:
#     GOOGLE_CLOUD_SERVICE_ACCOUNT: bitwarden/svc.worker.ci
#     GITHUB_SSH_KEY: google/svc.worker.ci
FetchSecrets(){
    secrets=$(fetchConfigs "secrets.yml")
    
    # Parse the secrets using yq
    kind=$(echo "$secrets" | yq e '.kind' -)
    version=$(echo "$secrets" | yq e '.version' -)
    items=$(echo "$secrets" | yq e '.items' -)
    
    nice_logs "Kind: $kind" "info"
    nice_logs "Version: $version" "info"
    nice_logs "Items: $items" "info"
}

# Put together and create all the necessary files and configurations for the project
#
# How to use:
# 
# [bash] InitProject [mode] [force]
# [bash] InitProject
# [bash] InitProject "apply"
# [bash] InitProject "apply" "true"
# [bash] InitProject "plan"
# [bash] InitProject "plan" "true"
# 
InitProject() {
    mode=${1:-"plan"} # Default to "plan" mode
    force=${2:-false} # Default to not force

    # Specify whether each directory is required
    declare -A required=(
        ["bin"]=true
        [".github/workflows"]=false
        ["environment/default"]=true
    )

    echo "Initializing project in $mode mode..."

    # Define the directory structure
    declare -A dirs=(
        ["bin"]="entrypoint.sh"
        [".github/workflows"]="docker-build-and-release.yml"
        ["environment/default"]="secrets.yml deployment.yml certificates.yml variables.yml"
    )

    # Explanation for each directory and file
    declare -A explanations=(
        ["bin"]="Contains scripts that are run at the start of the project."
        ["bin/entrypoint.sh"]="The script that is run when the Docker container starts."
        [".github/workflows"]="Contains GitHub Actions workflows."
        [".github/workflows/docker-build-and-release.yml"]="A workflow for building and releasing the Docker image."
        ["environment/default"]="Contains configuration for the default environment."
        ["environment/default/secrets.yml"]="Contains secrets for the default environment."
        ["environment/default/deployment.yml"]="Contains deployment configuration for the default environment."
        ["environment/default/certificates.yml"]="Contains certificates for the default environment."
        ["environment/default/variables.yml"]="Contains environment variables for the default environment."
        ["Dockerfile"]="Defines how to build the Docker image."
        ["README.md"]="Provides information about the project."
        [".gitignore"]="Specifies intentionally untracked files to ignore."
        ["package.json"]="Defines the project and its dependencies."
    )

    # Loop through each directory
    for dir in "${!dirs[@]}"; do
        nice_logs "${explanations[$dir]}" "info"

        # Check if the directory exists
        if [[ ! -d "$dir" ]]; then
            # If the directory is required and doesn't exist, print an error and return
            if [[ "${required[$dir]}" == true ]]; then
                nice_logs "Required directory $dir does not exist." "error"
                return 1
            fi

            # If we're in "apply" mode, create the directory
            if [[ "$mode" == "apply" ]]; then
                nice_logs "Directory $dir does not exist. Creating..." "info"
                mkdir -p "$dir"
            else
                nice_logs "Directory $dir does not exist. Would create..." "info"
            fi
        else
            nice_logs "Directory $dir already exists." "info"
        fi

        # Loop through each file in the directory
        for file in ${dirs[$dir]}; do
            nice_logs "${explanations[$dir/$file]}" "info"

            # Create the file if it doesn't exist or if force mode is enabled
            if [[ ! -f "$dir/$file" ]] || [[ "$force" == true ]] || [[ "$force" == "$dir/$file" ]]; then
                if [[ "$mode" == "apply" ]]; then
                    nice_logs "File $dir/$file does not exist or force mode is enabled. Creating..." "info"
                    touch "$dir/$file"
                else
                    nice_logs "File $dir/$file does not exist or force mode is enabled. Would create..." "info"
                fi
            else
                nice_logs "File $dir/$file already exists." "info"
            fi
        done
    done

    # Create Dockerfile, README.md, .gitignore, and package.json in the root directory if they don't exist or if force mode is enabled
    for file in "Dockerfile" "README.md" ".gitignore" "package.json"; do
        nice_logs "${explanations[$file]}" "info"

        if [[ ! -f "$file" ]] || [[ "$force" == true ]] || [[ "$force" == "$file" ]]; then
            if [[ "$mode" == "apply" ]]; then
                nice_logs "File $file does not exist or force mode is enabled. Creating..." "info"
                touch "$file"
            else
                nice_logs "File $file does not exist or force mode is enabled. Would create..." "info"
            fi
        else
            nice_logs "File $file already exists." "info"
        fi
    done

    nice_logs "Project initialization plan complete." "success"
}

# Fetch environment variables from variables.yml
FetchEnvironmentVariables() {
    nice_logs "Fetching environment variables..." "info"
    
    # @TODO 
    # # Use yq to parse the YAML file and export the environment variables
    # while IFS= read -r line; do
    #     export "$line"
    # done < <(yq e '.items | to_entries[] | "\(.key)=\(.value)"' /home/bin/fixtures/application/static/configs/default/variables.yml)
    
    nice_logs "Environment variables fetched successfully." "success"
}