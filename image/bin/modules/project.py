import os

# Specify whether each directory is required
required = {
    "bin": True,
    ".github/workflows": True,
    "environment/default": True
}

# Explanation for each directory and file
explanations = {
    "bin": "Contains scripts that are run at the start of the project.",
    "bin/entrypoint.sh": "The script that is run when the Docker container starts.",
    ".github/workflows": "Contains GitHub Actions workflows.",
    ".github/workflows/docker-build-and-release.yml": "A workflow for building and releasing the Docker image.",
    "environment/default": "Contains configuration for the default environment.",
    "environment/default/secrets.yml": "Contains secrets for the default environment.",
    "environment/default/deployment.yml": "Contains deployment configuration for the default environment.",
    "environment/default/certificates.yml": "Contains certificates for the default environment.",
    "environment/default/variables.yml": "Contains environment variables for the default environment.",
    "Dockerfile": "Defines how to build the Docker image.",
    "README.md": "Provides information about the project.",
    ".gitignore": "Specifies intentionally untracked files to ignore.",
    "package.json": "Defines the project and its dependencies."
}

def nice_logs(message, log_type):
    print(f"{log_type.upper()}: {message}")

def init_project(mode="plan", force=False):
    print(f"Initializing project in {mode} mode...")

    # Loop through each directory
    for dir in explanations.keys():
        nice_logs(explanations[dir], "info")

        # Check if the directory exists
        if not os.path.isdir(dir):
            # If the directory is required and doesn't exist, print an error and return
            if required.get(dir, False):
                nice_logs(f"Required directory {dir} does not exist.", "error")
                return 1

            # If we're in "apply" mode, create the directory
            if mode == "apply":
                nice_logs(f"Directory {dir} does not exist. Creating...", "info")
                os.makedirs(dir, exist_ok=True)
            else:
                nice_logs(f"Directory {dir} does not exist. Would create...", "info")
        else:
            nice_logs(f"Directory {dir} already exists.", "info")

        # Create the file if it doesn't exist or if force mode is enabled
        if not os.path.isfile(dir) or force:
            if mode == "apply":
                nice_logs(f"File {dir} does not exist or force mode is enabled. Creating...", "info")
                open(dir, 'a').close()
            else:
                nice_logs(f"File {dir} does not exist or force mode is enabled. Would create...", "info")
        else:
            nice_logs(f"File {dir} already exists.", "info")

    nice_logs("Project initialization plan complete.", "success")