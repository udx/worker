# UDX Worker CLI

## Overview

The UDX Worker provides a command-line interface for managing services, environment variables, and health checks.

## When To Use

Use the CLI when you need to:

- Inspect or manage running services.
- Check or resolve environment and secrets.
- Review health and SBOM output.

## Key Concepts

- Commands are namespaced (`worker service`, `worker env`, `worker health`, `worker sbom`, `worker config`).
- Most commands provide help when run without arguments.
- `worker env reload` and `worker config apply` rerun the same config/env/secret resolution path used by the entrypoint.

## Examples

```bash
# Show service command help
worker service

# Inspect resolved environment
worker env status

# Re-apply worker.yaml after provider auth has been established
worker env reload
```

## Common Pitfalls

- Forgetting to mount runtime config before running commands.
- Using the CLI outside the container when the worker is not running.

## Related Docs

- `docs/services.md`
- `docs/config.md`
