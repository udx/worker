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

## Best Practices

1. **Secret Management**

   - Never store sensitive values as plain text
   - Use either `config.secrets` section OR secret references in `config.env`
   - Both methods support the same provider format: `provider/vault/secret`
   - Choose based on your preference:
     - `config.secrets`: Explicit separation of secrets
     - `config.env` with references: Unified configuration

2. **Environment Variables**

   - Use `env` for non-sensitive configuration OR secret references
   - Keep values consistent across environments
   - Document any required variables

3. **File Handling**
   - Keep configuration in version control (without sensitive data)
   - Use different files for different environments
   - Validate configuration before deployment
