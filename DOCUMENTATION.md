# UDX Worker Overview

UDX Worker is a secure, multi-cloud-compatible Docker image designed for efficient CI/CD workflows. It supports both deployment and development scenarios, providing a hardened, zero-trust environment.

---

## Worker Configuration

UDX Worker uses a `worker.yml` file to define environment variables, secrets, and authentication. Place this file in the `.cd/configs/` directory of your repository.

### Example `worker.yml`:

```yaml
---
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    DOCKER_IMAGE_NAME: "my-application"
    DEBUG: "my-application:*"
  secrets:
    DB_PASSWORD: "aws/secrets-manager/db_password"
    API_KEY: "gcp/my-project/api_key"
```

### Key Sections:

- **Variables**: Non-sensitive parameters like application names or debug levels.
- **Secrets**: Sensitive data securely retrieved from external providers at runtime.

---

## Secrets and Actor Authorization

To access secrets from cloud providers, set the following environment variables with credentials:

| **Provider**      | **Credential Variable** |
|--------------------|-------------------------|
| Google Cloud       | `GCP_CREDS`            |
| Azure              | `AZURE_CREDS`          |
| AWS                | `AWS_CREDS`            |
| Bitwarden          | `BITWARDEN_CREDS`      |

UDX Worker handles authentication automatically using these credentials to fetch secrets during runtime.

Supported secrets formats include:
- **Google Cloud:** `gcp/{project_id}/{secret_name}`
- **Azure Key Vault:** `azure/{vault_name}/{secret_name}`
- **AWS Secrets Manager:** `aws/{path}/{secret_name}`
- **Bitwarden:** `bitwarden/{collection}/{secret_name}`

---

## Deploying Locally with Worker Configuration

To deploy the UDX Worker container locally with the `worker.yml` configuration file mounted, use the following:

```shell
docker run -d --name udx-worker \
  --env-file .env \
  -v $(pwd)/.cd/configs/worker.yml:/home/udx/.cd/configs/worker.yml \
  usabilitydynamics/udx-worker:latest
```

### Explanation:

1. **Environment File**:
   - The `.env` file contains the required credential variables for secrets providers, such as:
     - `GCP_CREDS`
     - `AZURE_CREDS`
     - `AWS_CREDS`
     - `BITWARDEN_CREDS`

2. **Mounting `worker.yml`**:
   - The configuration file is mounted into the container using the `-v` flag to ensure it’s available at runtime.

3. **Image**:
   - Replace `usabilitydynamics/udx-worker:latest` with the specific version or tag of the UDX Worker image if needed.

---

## Custom Images for Deployment

You can extend UDX Worker to create custom images tailored to your applications or workflows.

### Steps to Create a Custom Image:

1. **Create a Dockerfile:**

```shell
FROM usabilitydynamics/udx-worker:latest

# Copy the worker
COPY src/worker.yml /home/${USER}/.cd/configs/worker.yml

# Add your dependencies or scripts
COPY my-app /usr/src/app
```

2. **Build the Image:**

```shell
docker build -t my-custom-udx-worker .
```

3. **Run the Custom Image:**

```shell
docker run -d --name my-custom-udx-worker my-custom-udx-worker
```

> **Tip:** Avoid redefining the `ENTRYPOINT` to retain UDX Worker’s built-in configuration capabilities.

---