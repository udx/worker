# UDX Worker

This repository contains the UDX Worker Docker image, designed to provide a secure and reliable environment for various automation tasks. The image includes essential tools and dependencies for development and deployment.

## Prerequisites

Before using the UDX Worker Image, make sure you have the following prerequisites installed:

- Docker: [Installation Guide](https://docs.docker.com/get-docker/)

## Local Development

### Build

To build the Docker image locally:

```shell
docker build -t udx-worker .
```

### Run

To run the container in the background:

```shell
docker run -d --rm --name udx-worker udx-worker
```

To run the container interactively:

```shell
docker run --rm -it udx-worker bash
```

### Exec

To access the running UDX Worker container:

```shell
docker exec -it udx-worker bash
```

## Cloud Usage

### Pull

To pull the Docker image from the Google Cloud Artifact Registry:

```shell
docker pull gcr.io/rabbit-ci-tooling/udx-worker:latest
```

### Run

To run the UDX Worker container pulled from the Google Cloud Artifact Registry:

```shell
docker run -d --rm --name udx-worker gcr.io/rabbit-ci-tooling/udx-worker:latest
```

## Features

### Using worker.yml for Dynamic Configuration

The worker.yml file allows you to dynamically configure environment variables, volume mappings, and more for the UDX Worker container. This enhances flexibility and consistency across different environments.

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    DOCKER_IMAGE_NAME: "udx-worker"
  volumes:
    - "/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml"
```

#### Mounting worker.yml during Container Run

You can mount your local worker.yml file to the container using the -v option:

```shell
docker run -v $(pwd)/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml udx-worker
```

### Additional Entrypoint Script

The UDX Worker Docker image includes support for an additional entrypoint script. This is defined by the `ADDITIONAL_ENTRYPOINT` environment variable. If a child image or a user wants to include custom initialization logic, they can do so by placing their script at the path specified by `ADDITIONAL_ENTRYPOINT`.

#### How it works

- Default Entrypoint: Executes `/usr/local/bin/entrypoint.sh` when the container starts.

- Main Script Execution: Runs main.sh to set up the environment.

- Custom Initialization: Executes the script specified by the `ADDITIONAL_ENTRYPOINT` environment variable after main.sh. This allows users who utilize the UDX Worker as a base for their own Docker images to add custom initialization logic.
  - The `ADDITIONAL_ENTRYPOINT` (`/usr/local/bin/init.sh` by default) environment variable specifies the shell script to run during the entrypoint for child images. If an entrypoint is specified in the child Dockerfile, UDX Worker features will not be enabled.

#### Example Usage

- Create a custom script (e.g., `init.sh`) and place it at `/usr/local/bin/init.sh` inside the Docker container.
- Ensure the script has executable permissions.

```shell
# Dockerfile for a child image
FROM udx-worker:latest

# Copy custom init script to the specified path
COPY init.sh /usr/local/bin/init.sh

# Ensure the script is executable
RUN chmod +x /usr/local/bin/init.sh
```

This setup ensures flexibility and extensibility, allowing custom initialization while maintaining a secure and reliable environment for automation tasks.

### GitHub Actions Workflow Integration

You can also integrate the UDX Worker container with a CI/CD pipeline using GitHub Actions. Here’s how you can utilize the already built and uploaded UDX Worker image from Google Cloud, mounting worker.yml from your app repository:

```yaml
name: CI Pipeline

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v2

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v0
        with:
          credentials_json: ${{ secrets.GCP_CREDENTIALS }}

      - name: Pull and run UDX worker
        run: |
          docker pull gcr.io/rabbit-ci-tooling/udx-worker:latest
          docker run -v ${{ github.workspace }}/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml gcr.io/rabbit-ci-tooling/udx-worker:latest
```

## Continuous testing and automated releases

This repository is configured with GitHub Actions workflows that ensure continuous code scanning and build/tests verification checks. These workflows include:

- **CI Pipeline**: Builds and pushes Docker images to the Google Artifact Registry on every push. Only pushes to the "release" (latest) branch result in building and pushing the image. For other branches, the pipeline performs a test build.

- **CodeQL and Linter Analysis**: Analyzes the code for security vulnerabilities and code quality issues.

- **Dependabot**: Ensures that dependencies are up to date by automatically creating pull requests for version updates.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
