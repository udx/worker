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
- Child image scaffolding can be created manually with a Dockerfile that extends the base worker image.

## Examples

### Minimal Workflow

1. Create a Dockerfile.
2. Add dependencies.
3. Build and tag the image.
4. Run it with Docker, Kubernetes, or CI/CD.

Example Dockerfile:

```dockerfile
FROM usabilitydynamics/udx-worker:latest
RUN apt-get update && apt-get install -y jq
```

Build:

```bash
docker build -t my-org/udx-worker-custom:latest .
```

Run:

```bash
docker run --rm \
  -v "$(pwd)/.config/worker:/home/udx/.config/worker:ro" \
  my-org/udx-worker-custom:latest
```

## Common Pitfalls

- Baking secrets into the image.
- Forgetting to update the host deployment image reference.

## Related Docs

- `docs/deployment.md`
- `docs/references/container-structure.md`
