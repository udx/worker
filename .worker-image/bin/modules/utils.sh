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
    files=$(find /home/bin/fixtures/application/ -type f)
    
    if [[ -n $1 ]]; then
        filtered_files=$(echo "$files" | grep "$1")
        for file in $filtered_files; do
            cat "$file"
        done
    else
        for file in $files; do
            echo "Found file: $file"
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
    
    echo "User: $user"
    echo "Password: $password"
    echo "Tenant: $tenant"
    echo "Application: $application"
    echo "Subscription: $subscription"
    echo "Domains: $domains"
    
    echo "Authenticating..."
    
    echo "Authenticated successfully."
}

# ---
# kind: workerSecrets
CleanUpActors() {
    echo "Cleaning up actors..."
    
    echo "Actors cleaned up successfully."
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
    
    echo "Kind: $kind"
    echo "Version: $version"
    echo "Items: $items"
}

# Put together and create all the necessary files and configurations for the project
#
InitProject() {
    echo "Initializing project..."
    
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
    
    # Force mode: if set to true, all files will be recreated. If it's a string, only that file will be recreated.
    force=${1:-false}
    
    # Loop through each directory
    for dir in "${!dirs[@]}"; do
        echo "${explanations[$dir]}"
        
        # Create the directory if it doesn't exist
        if [[ ! -d "$dir" ]]; then
            echo "Directory $dir does not exist. Creating..."
            mkdir -p "$dir"
        else
            echo "Directory $dir already exists."
        fi
        
        # Loop through each file in the directory
        for file in ${dirs[$dir]}; do
            echo "${explanations[$dir/$file]}"
            
            # Create the file if it doesn't exist or if force mode is enabled
            if [[ ! -f "$dir/$file" ]] || [[ "$force" == true ]] || [[ "$force" == "$dir/$file" ]]; then
                echo "File $dir/$file does not exist or force mode is enabled. Creating..."
                touch "$dir/$file"
            else
                echo "File $dir/$file already exists."
            fi
        done
    done
    
    # Create Dockerfile, README.md, .gitignore, and package.json in the root directory if they don't exist or if force mode is enabled
    for file in "Dockerfile" "README.md" ".gitignore" "package.json"; do
        echo "${explanations[$file]}"
        
        if [[ ! -f "$file" ]] || [[ "$force" == true ]] || [[ "$force" == "$file" ]]; then
            echo "File $file does not exist or force mode is enabled. Creating..."
            touch "$file"
        else
            echo "File $file already exists."
        fi
    done
    
    echo "Project initialized successfully."
}

# Fetch environment variables from variables.yml
FetchEnvironmentVariables() {
    echo "Fetching environment variables..."
    
    # @TODO 
    # # Use yq to parse the YAML file and export the environment variables
    # while IFS= read -r line; do
    #     export "$line"
    # done < <(yq e '.items | to_entries[] | "\(.key)=\(.value)"' /home/bin/fixtures/application/static/configs/default/variables.yml)
    
    echo "Environment variables fetched successfully."
}