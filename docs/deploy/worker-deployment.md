# worker-deployment CLI

## Overview

`@udx/worker-deployment` standardizes how you run the worker image across different hosts and use cases. It keeps image selection, mounts, and runtime args in a single `deploy.yml` file.

## When To Use

Use `worker-deployment` when you want:

- A consistent local run command (`worker run`).
- The same config to work in CI/CD runners.
- A portable deployment format across laptops and ephemeral hosts.

## Key Concepts

- `deploy.yml` is the deployment config.
- `worker.yaml` and `services.yaml` are runtime configs mounted into the container.

## Examples

### Quick Start

```bash
npm install -g @udx/worker-deployment

# Generate a template
worker config

# Edit deploy.yml, then run
worker run
```

### Minimal Config

```yaml
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "usabilitydynamics/udx-worker:latest"
  volumes:
    - "./.config/worker:/home/udx/.config/worker:ro"
  command: "echo"
  args:
    - "Hello from deploy.yml"
```

## Common Pitfalls

- Forgetting to mount `worker.yaml`/`services.yaml` into the container.
- Putting runtime logic in `deploy.yml` instead of `services.yaml`.

## Related Docs

- `docs/deploy/README.md`
- `docs/deploy/image-override.md`
- `docs/runtime/config.md`
- `docs/runtime/services.md`
