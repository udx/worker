# UDX Worker

The UDX Worker revolutionizes DevSecOps by abstracting secret management complexities, securely handling secrets within its runtime environment.

This repository contains the UDX Worker Docker image, designed for secure and reliable automation tasks.

![UDX Worker Diagram](https://storage.googleapis.com/stateless-udx-io/2023/07/e5a9ac2b-understanding-containerization-in-microservices-architecture.png)

## Prerequisites

Before using the UDX Worker Image, make sure you have the following prerequisites installed:

- Docker: [Installation Guide](https://docs.docker.com/get-docker/)

## Local Development

### Build

To build the Docker image locally:

```shell
docker build -t udx-worker/udx-worker:latest .
```

### Run

To run the container in the background:

```shell
docker run -d --rm --name udx-worker udx-worker/udx-worker:latest
```

To run the container interactively:

```shell
docker run --rm -it udx-worker/udx-worker:latest bash
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
docker pull us-central1-docker.pkg.dev/rabbit-ci-tooling/udx-worker/udx-worker:latest
```

### Run

To run the UDX Worker container pulled from the Google Cloud Artifact Registry:

```shell
docker run -d --rm --name udx-worker us-central1-docker.pkg.dev/rabbit-ci-tooling/udx-worker/udx-worker:latest
```

## Features

### Dynamic Configuration with worker.yml

Supports dynamic configuration via worker.yml for environment variables, worker actors auth, and secrets fetching.

_Only [Azure] Auth supported so far._

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    DOCKER_IMAGE_NAME: "udx-worker"
    AZURE_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID}
    AZURE_TENANT_ID: ${AZURE_TENANT_ID}
    AZURE_APPLICATION_ID: ${AZURE_APPLICATION_ID}
    AWS_REGION: ${AWS_REGION}
    AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}
    AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}
    BITWARDEN_EMAIL: ${BITWARDEN_EMAIL}
    BITWARDEN_PASSWORD: ${BITWARDEN_PASSWORD}
    GCP_EMAIL: ${GCP_EMAIL}
    GCP_KEYFILE: ${GCP_KEYFILE}
  workerSecrets:
    AZURE_SECRET: "https://kv-udx-worker-secrets.vault.azure.net/secrets/udx-worker-secret-one"
    AWS_SECRET: "arn:aws:secretsmanager:region:account-id:secret:secret-id"
    BITWARDEN_SECRET: "bitwarden://vault/secrets/your-secret-id"
    GCP_SECRET: "projects/your-project/secrets/your-secret"
  workerActors:
    - type: azure-service-principal
      subscription: ${AZURE_SUBSCRIPTION_ID}
      tenant: ${AZURE_TENANT_ID}
      application: ${AZURE_APPLICATION_ID}
      password: ${AZURE_APPLICATION_PASSWORD}
    - type: aws-role
      role_arn: ${AWS_ROLE_ARN}
      session_name: ${AWS_SESSION_NAME}
    - type: bitwarden
      email: ${BITWARDEN_EMAIL}
      password: ${BITWARDEN_PASSWORD}
    - type: gcp-service-account
      email: ${GCP_EMAIL}
      keyfile: ${GCP_KEYFILE}
```

### Merging worker.yml Configurations

The UDX Worker supports merging configuration files from the base and child images. 

The base worker.yml is located at `/home/$USER/.cd/configs/worker.yml`, while the child image can provide its own worker.yml file, typically located at `/usr/src/app/configs/worker.yml`.

When the container starts, these files are merged, and the child configuration can override settings from the base configuration.

Example `worker.yml` for child image:

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    DOCKER_IMAGE_NAME: "custom-sql-backup"
  workerSecrets:
    AZURE_SECRET_APP_ONE: "https://kv-udx-worker-secrets.vault.azure.net/secrets/udx-worker-secret-one"
    AZURE_SECRET_APP_TWO: "https://kv-udx-worker-secrets.vault.azure.net/secrets/udx-worker-secret-two"
  workerActors:
    - type: azure-service-principal
      subscription: ${AZURE_SUBSCRIPTION_ID}
      tenant: ${AZURE_TENANT_ID}
      application: ${AZURE_APPLICATION_ID}
      password: ${AZURE_APPLICATION_PASSWORD}
```

#### Local Environment

The `.udx` file is used to store environment variables required by the UDX Worker. Example .udx file:

```txt
AZURE_SUBSCRIPTION_ID=132583e0-0e9d-46a9-b702-66060ca58c1b
AZURE_TENANT_ID=ffbbef27-e47d-46b3-8d3c-21aa3438d682
AZURE_APPLICATION_ID=a6319a29-b3f2-4fc9-ba16-f215664a7d4e
AZURE_APPLICATION_PASSWORD=my-password
```

### GitHub Actions Integration

Integrate UDX Worker with CI/CD pipelines using GitHub Actions.

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
          docker run -v ${{ github.workspace }}/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml us-central1-docker.pkg.dev/rabbit-ci-tooling/udx-worker/udx-worker:latest
```

## Test

The `bin/test.sh` script validates the environment setup by:

- Loading environment variables from `.udx`.

- Ensuring required environment variables are set.

- Verifying secrets are resolved correctly.

- Checking that actor credentials are not exposed.

## Continuous testing and automated releases

This repository is configured with GitHub Actions workflows that ensure continuous code scanning and build/tests verification checks. These workflows include:

- **CI Pipeline**: Builds and pushes Docker images to the Google Artifact Registry on every push. Only pushes to the "release" (latest) branch result in building and pushing the image. For other branches, the pipeline performs a test build.

- **CodeQL and Linter Analysis**: Analyzes the code for security vulnerabilities and code quality issues.

- **Dependabot**: Ensures that dependencies are up to date by automatically creating pull requests for version updates.

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
