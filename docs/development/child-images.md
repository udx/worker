# Develop Child Images

## Overview

Child images solve a common problem: the base worker image is intentionally minimal, but many workloads require extra tools. A child image adds only what you need without changing the core worker.

## When To Use

Use a child image when:

- You need extra dependencies (SDKs, language runtimes, build tools).
- You want faster startup and predictable CI/CD.
- You want to keep the core worker image stable.

Avoid a child image when:

- You are changing worker core behavior.
- The dependency is only needed for a one-off task.

## Key Concepts

- Child images extend `usabilitydynamics/udx-worker`.
- `worker gen` creates scaffolding to get started quickly.

## Examples

### Generate Scaffolding

```bash
npm install -g @udx/worker-deployment

# Generate a child image repo skeleton (dry-run + prompt)
worker gen repo

# Generate a Dockerfile only (dry-run + prompt)
worker gen dockerfile
```

### Minimal Workflow

1. Generate a repo or Dockerfile.
2. Add dependencies.
3. Build and tag the image.
4. Deploy using `deploy.yml`.

Example Dockerfile:

```dockerfile
FROM usabilitydynamics/udx-worker:latest
RUN apt-get update && apt-get install -y jq
```

Build:

```bash
docker build -t my-org/udx-worker-custom:latest .
```

Deploy (excerpt):

```yaml
kind: workerDeployConfig
version: udx.io/worker-v1/deploy
config:
  image: "my-org/udx-worker-custom:latest"
```

## Common Pitfalls

- Baking secrets into the image.
- Forgetting to update `deploy.yml` with the child image.

## Related Docs

- `docs/deploy/worker-deployment.md`
- `docs/reference/container-structure.md`
