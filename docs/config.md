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

| Section | Purpose | Required |
|---------|----------|----------|
| `kind` | Configuration type identifier | Yes |
| `version` | Schema version | Yes |
| `config.env` | Environment variables | No |
| `config.secrets` | Secret references | No |

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

## Best Practices

1. **Secret Management**
   - Never store sensitive values directly in `env`
   - Use `secrets` section for sensitive data
   - Reference secrets from appropriate providers

2. **Environment Variables**
   - Use `env` for non-sensitive configuration
   - Keep values consistent across environments
   - Document any required variables

3. **File Handling**
   - Keep configuration in version control (without sensitive data)
   - Use different files for different environments
   - Validate configuration before deployment