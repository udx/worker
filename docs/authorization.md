# Worker Authorization

## Overview

The UDX Worker supports multiple cloud providers and services through environment-based credential management.

## Supported Providers

| Provider  | Environment Variable | Description                              |
| --------- | -------------------- | ---------------------------------------- |
| Azure     | `AZURE_CREDS`        | Azure cloud credentials                  |
| AWS       | `AWS_CREDS`          | Amazon Web Services credentials          |
| GCP       | `GCP_CREDS`          | Google Cloud Platform credentials        |
| Bitwarden | `BITWARDEN_CREDS`    | Bitwarden secrets management credentials |

## Credential Formats

Credentials can be provided in three formats:

| Format    | Description         | Use Case                     |
| --------- | ------------------- | ---------------------------- |
| JSON      | Plain JSON string   | Direct configuration         |
| Base64    | Base64-encoded JSON | Secure environment variables |
| File Path | Path to JSON file   | Local development            |

## Format Examples

### 1. JSON Format

```json
{
  "client_id": "CLIENT_ID",
  "client_secret": "CLIENT_SECRET",
  "tenant_id": "TENANT_ID",
  "subscription_id": "SUBSCRIPTION_ID"
}
```

### 2. Base64 Encoded Format

```bash
# Original JSON
{
    "client_id": "CLIENT_ID",
    "client_secret": "CLIENT_SECRET",
    "tenant_id": "TENANT_ID",
    "subscription_id": "SUBSCRIPTION_ID"
}

# Base64 encoded value
ewogICAgImNsaWVudF9pZCI6ICJDTElFTlRfSUQiLAogICAgImNsaWVudF9zZWNyZXQiOiAiQ0xJRU5UX1NFQ1JFVCIsCiAgICAidGVuYW50X2lkIjogIlRFTkFOVF9JRCIsCiAgICAic3Vic2NyaXB0aW9uX2lkIjogIlNVQlNDUklQVElPTl9JRCIKfQ==
```

**Generate Base64 Format:**

```bash
echo -n '{"client_id":"CLIENT_ID","client_secret":"CLIENT_SECRET","tenant_id":"TENANT_ID","subscription_id":"SUBSCRIPTION_ID"}' | base64
```

### 3. File Path Format

```bash
# Environment variable value
AZURE_CREDS="/path/to/azure_credentials.json"

# Credential file content (azure_credentials.json)
{
    "client_id": "CLIENT_ID",
    "client_secret": "CLIENT_SECRET",
    "tenant_id": "TENANT_ID",
    "subscription_id": "SUBSCRIPTION_ID"
}
```

> **Note**: Always use absolute paths in production environments to avoid path resolution issues.

## Credential Management

| Flag             | Default | Description                                                               |
| ---------------- | ------- | ------------------------------------------------------------------------- |
| `ACTORS_CLEANUP` | `true`  | Controls how cloud provider credentials are handled after authentication: |

- When `true` (default): All temporary credentials and login sessions are cleaned up after use, improving security by not leaving credentials on disk
- When `false`: Credentials are preserved on disk for reuse (e.g., GCP credentials are stored at `$HOME/creds/gcp_creds.json` and `GOOGLE_APPLICATION_CREDENTIALS` is set)

This flag is particularly useful for long-running processes or development environments where frequent re-authentication would be inefficient.