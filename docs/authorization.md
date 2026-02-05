# Worker Authorization

## Overview

The UDX Worker supports multiple cloud providers and services through environment-based credential management.

## When To Use

Use this when you need to:

- Provide credentials to the worker container.
- Understand supported providers and formats.

## Key Concepts

- Credentials can be provided via env vars.
- Secrets can be JSON, Base64, or file paths.

## Examples

### Supported Providers

| Provider | Environment Variable | Description                       |
| -------- | -------------------- | --------------------------------- |
| Azure    | `AZURE_CREDS`        | Azure cloud credentials           |
| AWS      | `AWS_CREDS`          | Amazon Web Services credentials   |
| GCP      | `GCP_CREDS`          | Google Cloud Platform credentials |

### JSON Format

```json
{
  "client_id": "CLIENT_ID",
  "client_secret": "CLIENT_SECRET",
  "tenant_id": "TENANT_ID",
  "subscription_id": "SUBSCRIPTION_ID"
}
```

### Base64 Format

```bash
echo -n '{"client_id":"CLIENT_ID","client_secret":"CLIENT_SECRET","tenant_id":"TENANT_ID","subscription_id":"SUBSCRIPTION_ID"}' | base64
```

### File Path

```bash
AZURE_CREDS="/path/to/azure_credentials.json"
```

## Common Pitfalls

- Using relative credential paths in production.
- Storing secrets in version control.

## Related Docs

- `docs/runtime/config.md`
- `docs/deploy/README.md`
- `docs/auth/README.md`
