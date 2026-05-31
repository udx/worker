# Cloud Providers Auth

Cloud auth is intentionally outside the worker runtime. The worker only passes through provider environment variables/files and uses provider CLIs or SDK behavior after auth exists.

## Options Matrix

Prefer identity mechanisms that the runtime platform injects without worker-specific credential volumes.

| Provider | Preferred path | File or volume fallback | Worker role |
|---|---|---|---|
| AWS | ECS task role, EKS Pod Identity, IRSA, or CI federation that exports standard AWS env/token variables | Shared AWS config/credentials files or projected web identity token files | Pass through AWS env/files and resolve secrets only after auth exists. |
| Azure | GitHub OIDC with `azure/login`, managed identity, or AKS workload identity | Azure CLI profile/config directory or projected federated token file when CLI tooling requires it | Pass through Azure env/files and resolve secrets only after auth exists. |
| Google Cloud | Attached service account, GKE/Cloud Run identity, or Workload Identity Federation | ADC or gcloud config files such as `GOOGLE_APPLICATION_CREDENTIALS` / `CLOUDSDK_CONFIG` | Pass through ADC/config and resolve secrets only after auth exists. |

## Practical Rule

Use the platform-native identity path first. Use mounted credential files only for local development, legacy tools, or provider CLIs that specifically require file-backed config.

When auth happens inside the container, run the provider-native auth command first, then run:

```bash
worker env reload
```

## Related Docs

- `docs/secrets.md`
