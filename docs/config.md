## Worker Configuration

The `worker.yaml` configuration file is a crucial component for customizing the environment of the UDX Worker. It allows users to specify both environment variables and secrets that are essential for the worker's operations.

### Structure

- **env**: This section define various environment variables that your worker needs to function.

```yaml
env:
  AZURE_CLIENT_ID: "your-azure-client-id"
  AZURE_TENANT_ID: "your-azure-tenant-id"
  AZURE_SUBSCRIPTION_ID: "your-azure-subscription-id"
  ...
```

- **secrets**: This section allows to reference secrets stored in secure locations.

```yaml
secrets:
  DB_PASSWORD: "aws/secrets-manager/db_password"
  API_KEY: "gcp/my-project/api_key"
  ...
```

Supported Providers

1. Azure Key Vault

```yaml
  AZURE_CLIENT_ID: "azure/{key_vault_name}/{secret_name}"
```

- AWS Secrets Manager

```yaml
  AWS_ACCESS_KEY_ID: "aws/{directory}/{secret_name}"
```

- GCP Secret Manager

```yaml
  GCP_CREDS: "gcp/{project_id}/{secret_name}"
```

- Bitwarden Vault

```yaml
  BITWARDEN_TOKEN: "bitwarden/{vault_name}/{secret_name}"
```


### Config Example

```yaml
---
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    AZURE_CLIENT_ID: "12345678-1234-1234-1234-1234567890ab"

  secrets:
    APP_CLIENT_SECRET: "azure/kv-example/clientSecret"
```

### Usage

To use this configuration file, make sure to mount it with your application under `/home/udx/`. It doesn't matter where you mount it, it could be autodetected in any subdirectory if it's mounted correctly and named `worker.yaml`.