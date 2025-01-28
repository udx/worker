## Worker Authorization

### Supported Environment Variables
- Azure: `AZURE_CREDS`
- AWS: `AWS_CREDS`
- GCP: `GCP_CREDS`
- Bitwarden: `BITWARDEN_CREDS`

### Credential Formats

Credentials can be provided in three ways:

- **JSON**: Stringified JSON.

- **Base64 Encoded JSON**: Base64 encoded JSON strings.

- **File Path**: File path to JSON files with the credentials.


### Examples

1. JSON

```json
{"client_id":"CLIENT_ID","client_secret":"CLIENT_SECRET","tenant_id":"TENANT_ID","subscription_id":"SUBSCRIPTION_ID"}
```

2. Base64 Encoded JSON

```base64
ewogICAgImNsaWVudF9pZCI6ICJDTElFTlRfSUQiLAogICAgImNsaWVudF9zZWNyZXQiOiAiQ0xJRU5UX1NFQ1JFVCIsCiAgICAidGVuYW50X2lkIjogIlRFTkFOVF9JRCIsCiAgICAic3Vic2NyaXB0aW9uX2lkIjogIlNVQlNDUklQVElPTl9JRCIKfQ==
```

Here is how you can base64 encode a JSON string:

```bash
echo -n '{"client_id": "CLIENT_ID", "client_secret": "CLIENT_SECRET", "tenant_id": "TENANT_ID", "subscription_id": "SUBSCRIPTION_ID"}' | base64
```

3. File Path

```txt
./creds/azure_creds.json
```

_Make sure to replace `./creds/azure_creds.json` with the actual file path to your credentials file_