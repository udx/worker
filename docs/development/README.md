# Development

## Overview

This section covers how to build the core worker image and how to create child images for workload-specific tooling.

## When To Use

Use these docs when you need to:

- Modify the core worker runtime.
- Add dependencies for a specific workload.
- Build and test images locally.

## Key Concepts

- **Core image**: modify this repo when changing worker behavior.
- **Child image**: extend the core image for extra dependencies.

## Examples

- Core image workflow: `docs/development/core-image.md`
- Child image workflow: `docs/development/child-images.md`

## Common Pitfalls

- Using child images to change core behavior.
- Forgetting to rebuild after Dockerfile changes.

## Related Docs

- `docs/deploy/README.md`
- `docs/reference/container-structure.md`
