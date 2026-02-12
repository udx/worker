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
- Secret references use `provider/<scope>/<name>` format.
- Provider reference formats:
  - `azure/<key-vault-name>/<secret-name>`
  - `gcp/<project-id>/<secret-name>`
  - `aws/<secret-name>/<region>`

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
    DB_PASSWORD: "aws/db-password/us-west-2"
    API_KEY: "azure/kv-prod/api-key"
```

### Static Secret Injection (`API_KEY`) and External Secret Resolution (`DB_PASSWORD`)

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    API_KEY: "dev-only-static-key"
  secrets:
    DB_PASSWORD: "azure/kv-prod/db-password"
```

`API_KEY` is injected as-is. `DB_PASSWORD` is resolved from the provider and then exported as an environment variable.

### Secret References in `config.env`

```yaml
config:
  env:
    DATABASE_URL: "gcp/my-project/db-connection-string"
    API_TOKEN: "azure/kv-prod/api-token"
    LOG_LEVEL: "info"
```

If an `env` value matches a secret reference format, the worker resolves it at startup.

### Separate Secret Scopes for Different Services

Use separate variable names in `worker.yaml`, then consume the right variable in each service:

```yaml
# worker.yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  secrets:
    SERVICE_A_DB_PASSWORD: "azure/kv-service-a/db-password"
    SERVICE_B_DB_PASSWORD: "azure/kv-service-b/db-password"
```

```yaml
# services.yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "serviceA"
    command: "bash -lc 'exec /home/udx/bin/service_a.sh'"
    envs:
      - "SERVICE_NAME=serviceA"

  - name: "serviceB"
    command: "bash -lc 'exec /home/udx/bin/service_b.sh'"
    envs:
      - "SERVICE_NAME=serviceB"
```

`serviceA` should read `SERVICE_A_DB_PASSWORD`, and `serviceB` should read `SERVICE_B_DB_PASSWORD`.
For strict isolation boundaries, run separate worker instances with separate identities.

### Runtime Environment and Precedence

1. **Deployment environment variables** (highest priority)
2. Deployment environment variables containing secret references (resolved at startup)
3. `worker.yaml` `config.secrets`
4. `worker.yaml` `config.env`

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
