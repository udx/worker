# Provider Authentication Guides

## Overview

This directory contains detailed authentication documentation for each supported cloud provider.

## When To Use

Use these guides when you need provider-specific setup, credential formats, or CLI integration details.

## Key Concepts

- Each provider has its own auth flow and credential structure.
- Worker-deployment CLI can simplify authentication setup.

## Examples

- `docs/auth/gcp.md` - GCP authentication guide
- `docs/auth/azure.md` - Azure authentication guide (coming soon)
- `docs/auth/aws.md` - AWS authentication guide (coming soon)

## Common Pitfalls

- Mixing provider-specific formats.
- Passing plain secrets directly in config files.

## Related Docs

- `docs/authorization.md`
- `docs/runtime/config.md`
- `docs/reference/cli.md`
