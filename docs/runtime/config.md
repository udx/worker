# Worker Configuration (`worker.yaml`)

## Overview

`worker.yaml` is the primary runtime configuration file. It defines environment variables and secret references used **inside** the worker container.

## When To Use

Use this when you need to:

- Define runtime environment variables.
- Reference secrets from cloud providers.
- Override defaults at runtime without rebuilding images.

## Key Concepts

- Runtime-only config: `/home/udx/.config/worker/worker.yaml`.
- Deployment env vars override `worker.yaml` values.
- Secret references use `provider/vault/secret` format.

## Examples

### Basic

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

### Secret References in Env

```yaml
config:
  env:
    DATABASE_URL: "gcp/my-project/db-connection-string"
    API_TOKEN: "azure/kv-prod/api-token"
    LOG_LEVEL: "info"
```

### Runtime Environment and Precedence

1. **Deployment environment variables** (highest priority)
2. `worker.yaml` `config.secrets`
3. `worker.yaml` `config.env`

Example override:

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

## Common Pitfalls

- Storing plaintext secrets in `worker.yaml`.
- Forgetting that deployment env vars override runtime config.

## Related Docs

- `docs/runtime/services.md`
- `docs/deploy/README.md`
- `docs/deploy/kubernetes.md`
