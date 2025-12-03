# Worker Configuration

## Overview

The UDX Worker uses `worker.yaml` as its primary configuration file, allowing you to:

- Define environment variables
- Reference secrets from various providers
- Configure worker behavior

## File Location

```bash
/home/udx/.config/worker/worker.yaml
```

## Configuration Structure

| Section          | Purpose                       | Required |
| ---------------- | ----------------------------- | -------- |
| `kind`           | Configuration type identifier | Yes      |
| `version`        | Schema version                | Yes      |
| `config.env`     | Environment variables         | No       |
| `config.secrets` | Secret references             | No       |

## Basic Example

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    AZURE_CLIENT_ID: "12345678-1234-1234-1234-1234567890ab"
    AWS_REGION: "us-west-2"
  secrets:
    DB_PASSWORD: "aws/prod/db_password"
    API_KEY: "azure/kv-prod/api-key"
```

## Secret Provider References

### Azure Key Vault

```yaml
secrets:
  CLIENT_SECRET: "azure/{vault_name}/{secret_name}"
  API_KEY: "azure/kv-prod/api-key"
```

### AWS Secrets Manager

```yaml
secrets:
  DB_PASSWORD: "aws/{path}/{secret_name}"
  ACCESS_KEY: "aws/prod/access-key"
```

### Google Cloud Secret Manager

```yaml
secrets:
  SERVICE_KEY: "gcp/{project_id}/{secret_name}"
  AUTH_TOKEN: "gcp/my-project/auth-token"
```

### Bitwarden Vault

```yaml
secrets:
  MASTER_KEY: "bitwarden/{vault_name}/{secret_name}"
  LICENSE_KEY: "bitwarden/prod/license-key"
```

## Environment Variables

Environment variables can be defined in two ways:

### 1. Direct Values

```yaml
config:
  env:
    # Cloud Provider Settings
    AZURE_TENANT_ID: "tenant-id"
    AWS_REGION: "us-west-2"
    GCP_PROJECT: "my-project"

    # Application Settings
    LOG_LEVEL: "info"
    MAX_WORKERS: "5"
    ENABLE_METRICS: "true"
```

### 2. Secret References

Environment variables can also reference secrets using the same provider format as the `secrets` section:

```yaml
config:
  env:
    # Reference secrets directly in env variables
    DATABASE_URL: "gcp/my-project/db-connection-string"
    API_TOKEN: "azure/kv-prod/api-token"
    AWS_SECRET_KEY: "aws/prod/secret-access-key"
    VAULT_PASSWORD: "bitwarden/prod/vault-pass"

    # Mix with regular values
    LOG_LEVEL: "info"
```

The worker will automatically detect secret references (format: `provider/vault/secret`) in environment variables and resolve them at runtime.

## Deployment Environment Variables

Environment variables can also be set at the deployment level (e.g., Kubernetes, Docker Compose) and will **take priority** over `worker.yaml` configuration.

### Priority Order

1. **Deployment environment variables** (highest priority)
2. `worker.yaml` config.secrets
3. `worker.yaml` config.env

### Example: Environment Override

```yaml
# worker.yaml (production defaults)
config:
  secrets:
    ES_PASSWORD: "gcp/prod-project/es-password"
```

```yaml
# Kubernetes deployment (staging override)
spec:
  containers:
    - name: worker
      env:
        - name: ES_PASSWORD
          value: "gcp/staging-project/es-password"
```

**Result**: The staging secret reference from Kubernetes will be used, not the production one from `worker.yaml`.

### Use Cases

- **Environment-specific overrides**: Different secrets per environment (dev/staging/prod)
- **Sensitive values**: Keep secrets out of config files entirely
- **Dynamic configuration**: Runtime values that change per deployment
- **Testing**: Override config values without modifying files

### Behavior

- Deployment env vars with secret references are automatically detected and resolved
- Deployment env vars with static values are used as-is
- If a deployment env var exists, the corresponding `worker.yaml` entry is skipped

## Best Practices

1. **Secret Management**

   - Never store sensitive values as plain text
   - Use secret references in any of these locations:
     - `config.secrets`: Explicit separation of secrets
     - `config.env`: Unified configuration with secret references
     - Deployment env vars: Runtime overrides (highest priority)
   - All methods support the same provider format: `provider/vault/secret`

2. **Environment-Specific Configuration**

   - Use `worker.yaml` for shared/default configuration
   - Use deployment env vars for environment-specific overrides
   - Example pattern:
     ```yaml
     # worker.yaml: production defaults
     config:
       secrets:
         DB_PASSWORD: "gcp/prod/db-pass"
     
     # K8s staging: override with deployment env
     env:
       - name: DB_PASSWORD
         value: "gcp/staging/db-pass"
     ```

3. **Environment Variables**

   - Use `config.env` for non-sensitive configuration OR secret references
   - Use deployment env vars to override per environment
   - Document any required variables
   - Remember: deployment env vars always win

4. **File Handling**

   - Keep `worker.yaml` in version control (without sensitive data)
   - Use secret references instead of plain text values
   - Validate configuration before deployment
   - Use deployment env vars for truly sensitive overrides
