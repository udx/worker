# GCP Authentication

Google Cloud Platform supports multiple authentication methods, each suited for different use cases.

## Authentication Methods

### 1. Service Account Key (Most Common)

Service account keys work for both local development and CI/CD environments.

**JSON Format:**
```json
{
  "type": "service_account",
  "project_id": "my-project-id",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "my-sa@my-project.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

**Usage:**
```bash
# Via environment variable
export GCP_CREDS='{"type":"service_account",...}'

# Via file path
export GCP_CREDS="/path/to/service-account-key.json"

# Via base64 encoding (recommended for CI/CD)
export GCP_CREDS=$(cat service-account-key.json | base64)
```

**Features:**
- ✅ Automatic `private_key` normalization (handles escaped newlines)
- ✅ Sets both `GOOGLE_APPLICATION_CREDENTIALS` and `GCP_CREDS`
- ✅ Authenticates with `gcloud` CLI
- ✅ Sets project automatically from `project_id` field

---

### 2. Workload Identity Token (GitHub Actions / CI/CD)

Keyless authentication using OIDC tokens - no service account keys needed!

**JSON Format:**
```json
{
  "type": "external_account",
  "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
  "subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
  "token_url": "https://sts.googleapis.com/v1/token",
  "service_account_impersonation_url": "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/SA_EMAIL:generateAccessToken",
  "credential_source": {
    "file": "/path/to/token",
    "format": {
      "type": "text"
    }
  }
}
```

**GitHub Actions Example:**
```yaml
- uses: google-github-actions/auth@v3
  id: auth
  with:
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

- name: Run Worker
  env:
    GCP_CREDS: ${{ steps.auth.outputs.credentials_file_path }}
  run: |
    docker run -e GCP_CREDS usabilitydynamics/udx-worker:latest
```

**Features:**
- ✅ No long-lived credentials
- ✅ Automatic token refresh
- ✅ Works with Google Cloud client libraries
- ✅ Recommended for CI/CD pipelines

---

### 3. Service Account Impersonation (Local Development)

Use your personal gcloud credentials to impersonate a service account - no key files needed!

**Setup:**
```bash
# 1. Authenticate with gcloud
gcloud auth login

# 2. Set up Application Default Credentials (required for Terraform/SDKs)
gcloud auth application-default login

# 3. Grant yourself impersonation permission
gcloud iam service-accounts add-iam-policy-binding \
  my-sa@my-project.iam.gserviceaccount.com \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=MY_PROJECT
```

**Usage with worker-deployment CLI:**
```yaml
# deploy.yml
config:
  service_account:
    email: "my-sa@my-project.iam.gserviceaccount.com"
  image: "usabilitydynamics/udx-worker:latest"
  command: "worker run my-task"
```

```bash
# Run with automatic impersonation
worker-run --config=deploy.yml
```

**Manual Docker Usage:**
```bash
# Generate impersonation credentials
gcloud auth application-default print-access-token > /tmp/token.txt

# Run container with impersonation
docker run \
  -e GOOGLE_APPLICATION_CREDENTIALS=/home/udx/adc.json \
  -e CLOUDSDK_AUTH_ACCESS_TOKEN=$(cat /tmp/token.txt) \
  -v ~/.config/gcloud/application_default_credentials.json:/home/udx/adc.json:ro \
  usabilitydynamics/udx-worker:latest
```

**Features:**
- ✅ No service account key files
- ✅ Uses your personal credentials
- ✅ Temporary access tokens
- ✅ Easy permission management
- ✅ Works with Terraform, gcloud, and SDKs

> **Note**: Impersonation bypasses the `gcp_authenticate()` function by setting `GOOGLE_APPLICATION_CREDENTIALS` and `CLOUDSDK_AUTH_ACCESS_TOKEN` directly.

---

## Authentication Priority

When multiple credential sources are available, the worker uses this priority:

1. **`GOOGLE_APPLICATION_CREDENTIALS`** - If already set, skip authentication (used for impersonation)
2. **`GCP_CREDS`** - Process through `gcp_authenticate()` function:
   - Detect credential type (service account key vs. workload identity token)
   - Normalize service account keys (fix escaped newlines in `private_key`)
   - Set `GOOGLE_APPLICATION_CREDENTIALS`
   - Authenticate with `gcloud auth login --cred-file`

---

## Using worker-deployment CLI

The [`@udx/worker-deployment`](https://www.npmjs.com/package/@udx/worker-deployment) CLI simplifies GCP authentication:

**Installation:**
```bash
npm install -g @udx/worker-deployment
```

**Quick Start:**
```bash
# Generate config template
worker-config

# Edit deploy.yml with your settings

# Run with automatic credential detection
worker-run
```

**Features:**
- ✅ Automatic credential detection (service account keys, impersonation, workload identity)
- ✅ Zero-config for default file names (`gcp-key.json`, `gcp-credentials.json`)
- ✅ Secure read-only mounts
- ✅ Support for custom credential paths

See the [worker-deployment README](https://github.com/udx/worker-deployment) for detailed examples.
