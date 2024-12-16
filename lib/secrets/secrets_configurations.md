# Secrets Configurations

## Azure Key Vault

### Prerequisites
- Access to an Azure subscription and an Azure Key Vault.
- Azure CLI installed for setup and authentication.

### Setup
1. **Create Key Vault**:
    - In the Azure portal, navigate to Key Vaults and select Create.
    - Set up the resource group, key vault name, and region.
    - Choose Review + Create and then Create.

### Add Secrets
1. Go to Secrets within your Key Vault.
2. Select Generate/Import to add a new secret.
3. Name your secret descriptively and set the secret value.

### Grant Access
1. Go to Access policies in your Key Vault.
2. Add an access policy to grant permissions for Get and List for secrets.
3. Select the Azure AD Application that represents your UDX Worker or create a new one.
4. Save the changes.

### Set Credentials For Environment Authorization
Set Azure credentials in your `.env` file (or set GitHub Action secret), referencing a service principal with access to the Key Vault.

```txt
AZURE_CREDS='{"clientId": "your-client-id", "clientSecret": "your-client-secret", "tenantId": "your-tenant-id"}'
```

### Reference in `worker.yml`

```yml
secrets:
  MY_SECRET: "azure/your-vault-name/your-secret-name"
```

- **Vault Reference**: Use "azure/{Vault Name}/{Secret Name}" in the secrets section of `worker.yml`.
- **Secret Reference**: Use the secret's name as defined in Azure Key Vault.

## Google Cloud Secret Manager

### Prerequisites
- Access to a Google Cloud project with Secret Manager API enabled.
- Google Cloud SDK installed for setup and authentication.

### Setup
1. **Enable Secret Manager API**:
    - In the Google Cloud Console, go to APIs & Services > Dashboard.
    - Select Enable APIs and Services and search for Secret Manager API.
    - Enable the API for your project.

### Create Secrets
1. In the Google Cloud Console, go to Secret Manager.
2. Select Create Secret.
3. Provide a descriptive name for the secret and enter the secret value.
4. Click Create Secret to save.

### Grant Access
1. Go to IAM & Admin > IAM in the Google Cloud Console.
2. Add a role to the service account that will be used by UDX Worker to access the secrets.
3. Assign the Secret Manager Secret Accessor role to this service account for access to specific secrets.

### Set Credentials For Environment Authorization
Set Google Cloud credentials in your `.env` file (or set GitHub Action secret), referencing a service account with access to Secret Manager.

```txt
GCP_CREDS='{"type": "service_account", "project_id": "your-project-id", "private_key_id": "your-private-key-id", "private_key": "your-private-key", "client_email": "your-client-email", "client_id": "your-client-id", "auth_uri": "https://accounts.google.com/o/oauth2/auth", "token_uri": "https://oauth2.googleapis.com/token", "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs", "client_x509_cert_url": "your-cert-url"}'
```

### Reference in `worker.yml`

```yml
secrets:
  MY_SECRET: "gcp/your-project-id/your-secret-name"
```

- **Project Reference**: Use "gcp/{Project ID}/{Secret Name}" in the secrets section of `worker.yml`.
- **Secret Reference**: Use the secret's name as defined in Google Cloud Secret Manager.

## AWS Secrets Manager

### Prerequisites
- Access to an AWS account with Secrets Manager enabled.
- AWS CLI installed for setup and configuration.

### Setup
1. **Create Secrets**:
    - Go to AWS Secrets Manager in the AWS Management Console.
    - Choose Store a new secret and select the secret type (e.g., credentials or plaintext).
    - Enter the secret value and give it a descriptive name.
    - Complete the setup and store the secret.

### Grant Access
1. Go to IAM in the AWS Management Console and create (or select) a service role that UDX Worker will use.
2. Attach the SecretsManagerReadWrite permission or a custom policy that grants read access to specific secrets.

### Set Credentials For Environment Authorization
Set AWS credentials in your `.env` file (or set GitHub Action secret), referencing an IAM user or role with the necessary permissions to access Secrets Manager.

```txt
AWS_CREDS='{"aws_access_key_id": "your-access-key-id", "aws_secret_access_key": "your-secret-access-key", "region": "your-region"}'
```

### Reference in `worker.yml`

```yml
secrets: 
  MY_SECRET: "aws/secrets-manager/your-secret-name"
```

- **Path Reference**: Use "aws/secrets-manager/{Secret Name}" in the secrets section of `worker.yml`.
- **Secret Name**: Use the name of the secret as it appears in AWS Secrets Manager.

## Bitwarden

### Prerequisites
- Access to a Bitwarden organization and Bitwarden CLI.

### Enable Secret Manager (Optional for Advanced Features)
1. Go to Settings > Secret Manager in your Bitwarden organization admin portal (requires an enterprise plan).

### Add Secrets
1. Create a Collection in Collections.
2. Add secrets as Secure Notes in this collection, using descriptive names for easy identification.

### Grant Access
1. Ensure the correct users or groups have read access to the collection.

### Set Credentials For Environment Authorization
Add Bitwarden credentials in your `.env` file (or set GitHub Action secret).

```txt
BITWARDEN_CREDS='{"clientId": "your-client-id", "clientSecret": "your-client-secret"}'
```

### Reference in `worker.yml`

```yml
secrets:
  MY_SECRET: "bitwarden/your-collection-name/your-secret-name"
```

- **Collection**: Use the Collection Name (or ID if there’s ambiguity).
- **Secret Reference**: Use the format "bitwarden/{Collection Name}/{Secret Name}".