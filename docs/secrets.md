# Secrets

## Overview

The worker resolves secret references from `worker.yaml` and environment variables after provider auth already exists. It does not log in to cloud providers or manage credential sessions.

## When To Use

Use this when you need to:

- Define secret references in `worker.yaml`.
- Pass secret references through deployment environment variables.
- Re-run secret resolution after a command authenticates inside the container.

## Key Concepts

- Secret values are exported into the worker environment file and become available to services.
- `config.secrets` maps environment variable names to provider references.
- `config.env` values that look like provider references are resolved too.
- Deployment env vars override `worker.yaml` and can also contain secret references.
- Provider auth is external: Docker, Kubernetes, CI/CD, workload identity, mounted credentials, or a command inside the container owns login/session setup.

Supported reference formats:

- `azure/<key-vault-name>/<secret-name>`
- `gcp/<project-id>/<secret-name>`
- `aws/<secret-name>/<region>`

## Examples

### `worker.yaml`

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  secrets:
    DB_PASSWORD: "azure/kv-prod/db-password"
    API_KEY: "gcp/my-project/api-key"
  env:
    DATABASE_URL: "aws/database-url/us-west-2"
```

### Deployment Env Reference

```bash
docker run --rm \
  -v "$(pwd)/.config/worker:/home/udx/.config/worker:ro" \
  -e API_KEY="gcp/my-project/api-key" \
  usabilitydynamics/udx-worker:latest
```

### Internal Auth Then Re-Resolve

For development, testing, validation, or runbook workflows, authenticate with provider-native tooling inside the container and then rerun worker resolution:

```bash
worker env reload
```

`worker config apply` is equivalent when the intent is to re-apply `worker.yaml`.

This is still not a worker login feature. The auth command and credential storage remain owned by the user, child image, workflow, or runbook.

### Resolve One Reference

```bash
worker env resolve gcp/my-project/api-key
```

## Credential Posture

- Prefer short-lived credentials, workload identity, or federation over static keys.
- Grant least-privilege access to only the required secret scopes.
- Pass only the provider env vars and mounted files needed by the workload.
- Mount credential directories read-only when files are required.
- Split high-trust workloads into separate worker deployments when isolation matters.

## Common Pitfalls

- Expecting built-in provider login commands.
- Storing plaintext secrets in `worker.yaml`.
- Reusing one broad credential principal for unrelated workloads.
- Adding custom credential volumes when platform identity or injected env/token files are available.

## Related Docs

- `docs/config.md`
- `docs/services.md`
- `docs/references/cloud-providers-auth.md`
