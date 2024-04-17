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
    files=$(find ../configs/fixtures/configs/ -type f)
    
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
ActorAuth() {
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