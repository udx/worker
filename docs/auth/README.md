# Provider Authentication Guides

This directory contains detailed authentication documentation for each supported cloud provider.

## Available Guides

- **[GCP Authentication](gcp.md)** - Complete guide for Google Cloud Platform
  - Service Account Keys
  - Workload Identity Tokens
  - Service Account Impersonation
  - worker-deployment CLI integration

- **[Azure Authentication](azure.md)** - Coming soon
- **[AWS Authentication](aws.md)** - Coming soon
- **[Bitwarden Authentication](bitwarden.md)** - Coming soon

## Quick Links

- [Main Authorization Guide](../authorization.md) - Overview and general credential formats
- [Worker Configuration](../config.md) - Worker configuration reference
- [CLI Documentation](../CLI.md) - Worker CLI commands

## Contributing

When adding a new provider authentication guide, please follow this structure:

1. **Authentication Methods** - List all supported authentication methods
2. **JSON Format Examples** - Show credential structure
3. **Usage Examples** - Provide practical examples (env vars, file paths, base64)
4. **Features** - Highlight key features and capabilities
5. **Best Practices** - Security and operational recommendations
6. **CLI Integration** - If applicable, show worker-deployment CLI usage

See [gcp.md](gcp.md) as a reference template.
