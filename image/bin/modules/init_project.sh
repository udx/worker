#!/bin/bash

# Specify whether each directory is required
declare -A required=(
    ["bin"]=true
    [".github/workflows"]=true
    ["environment/default"]=true
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

nice_logs() {
    local message=$1
    local log_type=$2
    echo "${log_type^^}: $message"
}

init_project() {
    local mode=${1:-plan}
    local force=${2:-false}

    echo "Initializing project in $mode mode..."

    for dir in "${!explanations[@]}"; do
        nice_logs "${explanations[$dir]}" "info"

        if [[ ! -d $dir ]]; then
            if [[ ${required[$dir]} == true ]]; then
                nice_logs "Required directory $dir does not exist." "error"
                return 1
            fi

            if [[ $mode == "apply" ]]; then
                nice_logs "Directory $dir does not exist. Creating..." "info"
                mkdir -p "$dir"
            else
                nice_logs "Directory $dir does not exist. Would create..." "info"
            fi
        else
            nice_logs "Directory $dir already exists." "info"
        fi

        if [[ ! -f $dir || $force == true ]]; then
            if [[ $mode == "apply" ]]; then
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_project "$@"
fi
