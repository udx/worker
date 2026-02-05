# UDX Worker Documentation

## Overview

This documentation is organized by concern so it is clear what happens **inside** the worker container (runtime) vs what happens **outside** at deployment time.

## When To Use

Start here if you need to:

- Configure runtime behavior (`services.yaml`, `worker.yaml`).
- Deploy the worker image across environments.
- Build the core image or child images.

## Key Concepts

- Runtime config lives inside the container.
- Deployment config selects the image and mounts runtime files.

## Examples

- Runtime: `docs/runtime/services.md`
- Deployment: `docs/deploy/README.md`
- Development: `docs/development/README.md`

## Common Pitfalls

- Mixing runtime config with deployment config.
- Editing the image when you only need a runtime change.

## Related Docs

- `docs/runtime/config.md`
- `docs/deploy/worker-deployment.md`
