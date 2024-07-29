#!/bin/sh
#
#
# !!! Not supported yet, will be implemented in the future !!!
#
#

# Specify whether each directory is required
required() {
    case "$1" in
        "bin-modules") echo "true" ;;
        ".github/workflows") echo "true" ;;
        ".cd/configs") echo "true" ;;
        *) echo "false" ;;
    esac
}

# Explanation for each directory and file
explanation() {
    case "$1" in
        "bin-modules") echo "Contains scripts that are run at the start of the project." ;;
        "bin-modules/entrypoint.sh") echo "The script that is run when the Docker container starts." ;;
        ".github/workflows") echo "Contains GitHub Actions workflows." ;;
        ".github/workflows/docker-build-and-release.yml") echo "A workflow for building and releasing the Docker image." ;;
        ".cd/configs") echo "Contains configuration for the default environment." ;;
        ".cd/configs/environment.yml") echo "Contains environment variables for the default environment" ;;
        "Dockerfile") echo "Defines how to build the Docker image." ;;
        "README.md") echo "Provides information about the project." ;;
        ".gitignore") echo "Specifies intentionally untracked files to ignore." ;;
        "package.json") echo "Defines the project and its dependencies." ;;
        *) echo "No explanation available." ;;
    esac
}

nice_logs() {
    message="$1"
    log_type="$2"
    echo "${log_type}: $message"
}

init_project() {
    mode="${1:-plan}"
    force="${2:-false}"
    
    echo "Initializing project in $mode mode..."
    
    dirs="bin bin/entrypoint.sh .github/workflows .github/workflows/docker-build-and-release.yml environment/default environment/default/secrets.yml environment/default/deployment.yml environment/default/certificates.yml environment/default/variables.yml Dockerfile README.md .gitignore package.json"
    
    for dir in $dirs; do
        nice_logs "$(explanation "$dir")" "info"
        
        if [ ! -d "$dir" ]; then
            if [ "$(required "$dir")" = "true" ]; then
                nice_logs "Required directory $dir does not exist." "error"
                return 1
            fi
            
            if [ "$mode" = "apply" ]; then
                nice_logs "Directory $dir does not exist. Creating..." "info"
                mkdir -p "$dir"
            else
                nice_logs "Directory $dir does not exist. Would create..." "info"
            fi
        else
            nice_logs "Directory $dir already exists." "info"
        fi
        
        if [ ! -f "$dir" ] || [ "$force" = "true" ]; then
            if [ "$mode" = "apply" ]; then
                nice_logs "File $dir does not exist or force mode is enabled. Creating..." "info"
                touch "$dir"
            else
                nice_logs "File $dir does not exist or force mode is enabled. Would create..." "info"
            fi
        else
            nice_logs "File $dir already exists." "info"
        fi
    done
    
    nice_logs "Project initialization plan complete." "success"
}

# Execute the function if the script is run directly
# if [ "$(basename "$0")" = "$(basename "${0}")" ]; then
# init_project "$@"
# fi
