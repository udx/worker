# Deployment

## Overview

Deployment is external to the worker container. This directory covers how to run the worker image consistently across local machines, CI/CD, and Kubernetes.

## When To Use

Use these docs when you need to:

- Run the worker locally with a consistent config.
- Deploy in CI/CD (GitHub Actions, etc.).
- Mount runtime configs into Kubernetes.

## Key Concepts

- `deploy.yml` chooses the image, mounts runtime configs, and defines command/args.
- `worker.yaml` and `services.yaml` are runtime configs inside the container.

## Examples

- Local/CI usage: `docs/deploy/worker-deployment.md`
- CI image overrides: `docs/deploy/image-override.md`
- Kubernetes ConfigMaps: `docs/deploy/kubernetes.md`

## Common Pitfalls

- Editing runtime configs when you meant to change deployment behavior.
- Hardcoding image tags in CI instead of rendering `deploy.yml`.

## Related Docs

- `docs/runtime/config.md`
- `docs/runtime/services.md`
