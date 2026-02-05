# Container Structure

## Overview

This document outlines the directory structure of the UDX Worker container and how to place application code in child images.

## When To Use

Use this when you need to:

- Understand where worker internals live.
- Build child images without breaking worker paths.

## Key Concepts

- Worker directories must be preserved.
- Application code should live in language-standard paths.

## Examples

### Base Directory Structure

```
/
├── opt/worker/           # Base directory for worker-specific files
│   ├── apps/            # Worker applications and plugins
│   └── data/            # Worker data storage and processing
├── etc/worker/          # Worker configuration files
├── usr/local/worker/
│   ├── bin/            # Worker executable files
│   ├── lib/            # Worker library files
│   └── etc/            # Additional worker configuration
└── usr/local/configs/   # Cloud provider configurations
    ├── gcloud/         # Google Cloud SDK config
    ├── aws/            # AWS CLI config
    └── azure/          # Azure CLI config
```

### Child Image Placement

PHP:

```
/
├── var/www/           # PHP application code
└── opt/worker/        # Worker directories (preserved)
```

Node.js:

```
/
├── usr/src/app/      # Node.js application code
└── opt/worker/       # Worker directories (preserved)
```

Python:

```
/
├── usr/src/app/      # Python application code
└── opt/worker/       # Worker directories (preserved)
```

## Common Pitfalls

- Modifying or removing worker directories.
- Storing application code under `/opt/worker`.

## Related Docs

- `docs/development/child-images.md`
- `docs/deploy/README.md`
