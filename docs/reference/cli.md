# UDX Worker CLI

## Overview

The UDX Worker provides a command-line interface for managing services, environment variables, and health checks.

## When To Use

Use the CLI when you need to:

- Inspect or manage running services.
- Check or resolve environment and secrets.
- Review health and SBOM output.

## Key Concepts

- Commands are namespaced (`worker service`, `worker env`, `worker auth`).
- Most commands provide help when run without arguments.

## Examples

```bash
# Show auth command help
worker auth

# Show service command help
worker service
```

## Common Pitfalls

- Forgetting to mount runtime config before running commands.
- Using the CLI outside the container when the worker is not running.

## Related Docs

- `docs/runtime/services.md`
- `docs/runtime/config.md`
