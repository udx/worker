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
- Secret references are resolved from provider paths in `worker.yaml` and matching runtime env vars.
- Authorization cleanup is controlled by `ACTORS_CLEANUP` (enabled by default).

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
  "clientId": "CLIENT_ID",
  "clientSecret": "CLIENT_SECRET",
  "tenantId": "TENANT_ID",
  "subscriptionId": "SUBSCRIPTION_ID"
}
```

### Base64 Format

```bash
echo -n '{"clientId":"CLIENT_ID","clientSecret":"CLIENT_SECRET","tenantId":"TENANT_ID","subscriptionId":"SUBSCRIPTION_ID"}' | base64
```

### File Path

```bash
AZURE_CREDS="/path/to/azure_credentials.json"
```

### Provider-Specific Credential Keys

- Azure (`AZURE_CREDS`): `clientId`, `clientSecret`, `tenantId`, `subscriptionId`
- AWS (`AWS_CREDS`): `AccessKeyId`, `SecretAccessKey`, optional `SessionToken`
- GCP (`GCP_CREDS`): standard GCP credential JSON (service account or other `gcloud --cred-file` compatible JSON)

### Security Scenario: Long-Lived Credentials

Example concern:
- A static service principal secret is stored in CI and reused for months.
- If leaked, an attacker can keep resolving secrets from the same vault scope until rotation.

How worker design can mitigate:
- Fetch only referenced secrets at startup (for example `azure/<vault>/<secret>`).
- Remove local auth artifacts after setup when `ACTORS_CLEANUP=true`.
- Override secret references per environment at deploy time for safer rotation workflows.

How worker design can exacerbate:
- Resolved secrets are exported to process environment and can live for the container lifetime.
- Services can leak secrets if scripts print env vars or run with verbose shell tracing.
- A single broad credential can unlock multiple vault scopes in one worker instance.

### Recommended Credential Posture

- Prefer short-lived credentials or federation-based identity flows over long-lived static secrets.
- Grant least-privilege access to only the required secret scopes.
- Rotate provider credentials and secret values regularly.
- Split high-trust workloads into separate worker deployments when hard isolation is required.

## Common Pitfalls

- Using relative credential paths in production.
- Storing secrets in version control.
- Using long-lived provider credentials with broad access scope.
- Reusing one credential principal for unrelated services that require isolation.

## Related Docs

- `docs/runtime/config.md`
- `docs/deploy/README.md`
- `docs/auth/README.md`
