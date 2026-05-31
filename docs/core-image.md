# Develop the Core Worker Image

## Overview

This repo builds the base `usabilitydynamics/udx-worker` image. Use this when you need to change the worker runtime itself.

## When To Use

Use this when you are modifying:

- Supervisor/service behavior
- Auth/secrets handling
- CLI commands

## Key Concepts

- `make build` builds the image.
- `make run` runs it locally with mounted configs.
- `make test` runs container-based tests.

## Examples

### Build

```bash
make build
```

Common options (see `Makefile.variables`):

- `DOCKER_IMAGE` (default image name/tag)
- `MULTIPLATFORM=true` (buildx multi-arch)
- `DEBUG=true` (verbose build output)

### Run

```bash
make run
```

Interactive shell:

```bash
make run-it
```

Follow logs:

```bash
make log FOLLOW_LOGS=true
```

### Tests

```bash
make test
```

The test target mounts `test` and example configs into the container and runs `/home/udx/test/main.sh`.

## Common Pitfalls

- Forgetting to rebuild after changes.
- Not mounting runtime config before testing.

## Related Docs

- `docs/services.md`
- `docs/config.md`
