# CI/CD Image Override

## Overview

Override the worker image at deploy time by rendering a deploy template with an environment variable.

## When To Use

Use this when you:

- Tag images per build and want to deploy that tag.
- Need to switch images without changing runtime configs.

## Key Concepts

- Keep `deploy.template.yml` in repo.
- Render to `deploy.yml` in CI.

## Examples

Template (`deploy.template.yml`):

```yaml
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "${WORKER_IMAGE}"
  command: "echo"
  args:
    - "Hello from CI/CD"
```

Render + run:

```bash
export WORKER_IMAGE="usabilitydynamics/udx-worker:latest"
envsubst < deploy.template.yml > deploy.yml
worker run --config=deploy.yml
```

If `envsubst` is unavailable:

```bash
export WORKER_IMAGE="usabilitydynamics/udx-worker:latest"
sed "s|\${WORKER_IMAGE}|${WORKER_IMAGE}|g" deploy.template.yml > deploy.yml
worker run --config=deploy.yml
```

Example directory: `src/examples/deploy-image-override/`

## Common Pitfalls

- Committing generated `deploy.yml` with build-specific tags.
- Forgetting to set `WORKER_IMAGE` in CI.

## Related Docs

- `docs/deploy/worker-deployment.md`
