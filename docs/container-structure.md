# Container Directory Structure

This document outlines the directory structure of the UDX Worker container and provides guidance for creating child images.

## Base Directory Structure

The worker container uses the following directory structure:

```
/
├── opt/worker/           # Base directory for worker-specific files
│   ├── apps/            # Worker applications and plugins
│   └── data/            # Worker data storage and processing
├── etc/worker/          # Worker configuration files
├── usr/local/worker/
│   ├── bin/            # Worker executable files
│   ├── lib/            # Worker library files
│   └── etc/            # Additional worker configuration
└── usr/local/configs/   # Cloud provider configurations
    ├── gcloud/         # Google Cloud SDK config
    ├── aws/            # AWS CLI config
    └── azure/          # Azure CLI config
```

### Directory Purposes

#### Worker-Specific Directories

- `WORKER_BASE_DIR=/opt/worker`
  - Main directory for worker-specific files
  
- `WORKER_APP_DIR=/opt/worker/apps`
  - Contains worker-specific applications and plugins
  - Used for extending worker functionality
  - **Not intended** for application code in child images
  
- `WORKER_DATA_DIR=/opt/worker/data`
  - Used for worker data storage and processing
  - Temporary and persistent data used by the worker
  
- `WORKER_CONFIG_DIR=/etc/worker`
  - Contains worker configuration files
  
- `WORKER_LIB_DIR=/usr/local/worker/lib`
  - Worker library files and shared code
  
- `WORKER_BIN_DIR=/usr/local/worker/bin`
  - Worker executable files
  - Added to system PATH
  
- `WORKER_ETC_DIR=/usr/local/worker/etc`
  - Additional worker configuration files

#### Cloud Configuration Directories

- `CLOUDSDK_CONFIG=/usr/local/configs/gcloud`
  - Google Cloud SDK configuration
  
- `AWS_CONFIG_FILE=/usr/local/configs/aws`
  - AWS CLI configuration
  
- `AZURE_CONFIG_DIR=/usr/local/configs/azure`
  - Azure CLI configuration

## Child Image Development

When developing child images (e.g., PHP, Node.js), follow these guidelines:

### Directory Structure Guidelines

1. **Preserve Worker Directories**
   - Maintain all worker directories as they are
   - Do not modify or remove any worker-specific paths
   - These directories are essential for worker functionality

2. **Application Code Placement**
   - Use framework/language-specific conventional directories for your application code
   - Do not place application code in worker directories

### Examples by Language

#### PHP Applications
```
/
├── var/www/           # PHP application code (standard location)
└── opt/worker/        # Worker directories (preserved)
```

#### Node.js Applications
```
/
├── usr/src/app/      # Node.js application code (standard location)
└── opt/worker/       # Worker directories (preserved)
```

#### Python Applications
```
/
├── usr/src/app/      # Python application code (standard location)
└── opt/worker/       # Worker directories (preserved)
```

### Best Practices

1. **Separation of Concerns**
   - Keep application code separate from worker functionality
   - Use standard language/framework conventions for your application
   - Don't mix application data with worker data

2. **Configuration**
   - Use appropriate configuration directories for your application
   - Don't modify worker configurations unless specifically required

3. **Data Storage**
   - Use appropriate data directories for your application
   - Don't use `WORKER_DATA_DIR` for application data storage
