# Authentication Modules

## Prerequisites

- Azure CLI
- AWS CLI
- GCP SDK

## Setup

### Azure Service Principal

#### Create

```shell
az ad sp create-for-rbac --name "udx-worker-sp" --role contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

Note the appId, password, tenant.

#### Use

```yaml
workerActors:
  - type: azure-service-principal
    subscription: "YOUR_SUBSCRIPTION_ID"
    tenant: "YOUR_TENANT_ID"
    application: "YOUR_APP_ID"
    password: "YOUR_CLIENT_SECRET"
```

### GCP Service Account (TBD)

### Azure Service Principal (TBD)