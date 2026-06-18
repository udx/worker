# Deployment

## Overview

Deployment is external to the worker container. Use the host-native tool for the target environment: `docker run`, Docker Compose, `kubectl apply`, or the CI/CD platform's deployment step.

## When To Use

Use this when you need to:

- Run the worker locally with Docker.
- Deploy in CI/CD (GitHub Actions, etc.).
- Mount runtime configs into a container runtime or orchestrator.

## Key Concepts

- Host tooling chooses the image, mounts runtime configs, and defines command/args.
- `worker.yaml` and `services.yaml` are runtime configs inside the container.
- Provider auth should be established by the host/platform or by the command running inside the container.
- Prefer native identity/env/token injection over custom credential volumes where the platform supports it.

## Examples

- Docker:

```bash
docker run --rm \
  -v "$(pwd)/.config/worker:/home/udx/.config/worker:ro" \
  -e API_KEY="gcp/my-project/api-key" \
  usabilitydynamics/udx-worker:latest
```

- Docker with a child image:

```bash
docker run --rm \
  -v "$(pwd)/.config/worker:/home/udx/.config/worker:ro" \
  my-org/udx-worker-custom:latest
```

For orchestrators such as Kubernetes, mount `worker.yaml` and `services.yaml` through the platform's normal config/secret primitives and keep deployment manifests outside the worker image.

## Common Pitfalls

- Editing runtime configs when you meant to change deployment behavior.
- Baking secrets into images instead of using env vars, mounted files, or Kubernetes Secrets.
- Putting runtime process definitions in host deployment config instead of `services.yaml`.
- Expecting worker deployment logic to create cloud sessions; deployment and auth are external concerns.

## Related Docs

- `docs/config.md`
- `docs/services.md`
- `docs/secrets.md`
- `docs/runtime-output.md`
