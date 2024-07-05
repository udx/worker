#!/bin/sh

# Function to resolve secrets from GCP Secret Manager
resolve_gcp_secret() {
    local secret_url=$1
    echo "Resolving GCP secret for URL: $secret_url" >&2
    gcloud secrets versions access latest --secret="${secret_url}" 2>/dev/null
}
