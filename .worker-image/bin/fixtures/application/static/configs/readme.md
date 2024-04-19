# UDX Worker Configuration Standards

This document describes the configuration standards for UDX workers.

The configuration is divided into four categories: certificates, deployment, secrets, and variables. Each category is defined in a separate YAML file.

All configurations are organized under the `/default` directory. If there are any environment-specific configurations or references to sensitive data that need to be different, they can be specified under the environment-specific directories such as `/staging`, `/production`, etc.

## Deployment (`deployment.yml`)

The `deployment.yml` file defines the deployment settings for the worker, including the name, image, and type of the worker.

```yaml
---
kind: workerDeployment
version: udx.io/worker-v1/deployment
settings:
  name: "udx-worker"
  image: "udx-worker:ubuntu-latest"
  type: "task"
```

## Secrets (`secrets.yml`)

The `secrets.yml` file defines the secrets used by the worker. Each secret has a name and a source. The source is a URL that points to the secret in a secrets management service.

```yaml
---
kind: workerSecrets
version: udx.io/worker-v1/secrets
items:
  GOOGLE_CLOUD_SERVICE_ACCOUNT: bitwarden/svc.worker.ci
  GITHUB_SSH_KEY: google/svc.worker.ci
```

## Certificates (`certificates.yml`)

The `certificates.yml` file defines the certificates used by the worker. Each certificate has a name, notes, source, a flag indicating whether it has a private key, and a type.

```yaml
---
kind: workerCertificates
version: udx.io/worker-v1/certificates
items:
  worker-vm:
    name: "WORKER_WM"
    notes: "Worker VM certificate"
    source: azure/worker-vm-cert
    has_private_key: true
    type: certificate
```

## Variables (`variables.yml`)

The `variables.yml` file defines the variables used by the worker.

```yaml
---
kind: workerVariables
version: udx.io/worker-v1/variables
items:
  DOCKER_IMAGE_NAME: "docker-builder"

  GCP_AUTH_PROVIDER: "projects/309037306746/locations/global/workloadIdentityPools/docker-builder-pool/providers/docker-builder-provider"
  GCP_PROJECT: "rabbit-ci-tooling"
  GCP_REGION: "us-central1"
  GCP_REGISTRY_REPO: "docker-builder"
  GCP_SERVICE_ACCOUNT: "svc-docker-builder@rabbit-ci-tooling.iam.gserviceaccount.com"

  GITHUB_CONFIGS_REPO: https://github.com/udx/worker-repo-best-practice-configs
  GITHUB_CONFIGS_BRANCH: main
```

These configuration files provide a flexible and secure way to manage the settings, secrets, and certificates used by UDX workers. Environment-specific configurations allow for fine-tuned control over different deployment environments.
