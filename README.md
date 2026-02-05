# UDX Worker

[![Docker Pulls](https://img.shields.io/docker/pulls/usabilitydynamics/udx-worker.svg)](https://hub.docker.com/r/usabilitydynamics/udx-worker) [![License](https://img.shields.io/github/license/udx/worker.svg)](LICENSE) [![Documentation](https://img.shields.io/badge/docs-udx.dev-blue.svg)](https://udx.dev/worker)

**Secure, containerized environment for DevSecOps automation**

[Quick Start](#-quick-start) • [Documentation](#-documentation) • [Development](#️-development) • [Contributing](#-contributing)

## 🚀 Overview

UDX Worker is a containerized solution that simplifies DevSecOps by providing:

- 🔒 **Secure Environment**: Built on zero-trust principles
- 🤖 **Automation Support**: Streamlined task execution
- 🔑 **Secret Management**: Automatic detection and resolution from multiple providers
- 📦 **12-Factor Compliance**: Modern application practices
- ♾️ **CI/CD Ready**: Seamless pipeline integration with environment-based overrides

## 🏃 Quick Start

### Prerequisites

- Docker 20.10 or later
- Make (for development)

### Example 1: Simple Service

```bash
# Create project structure
mkdir -p my-worker/.config/worker
cd my-worker

# Create a simple service script
cat > index.sh <<'EOF'
#!/bin/bash
echo "Starting service..."
trap 'echo "Shutting down..."; exit 0' SIGTERM
while true; do
    echo "[$(date)] Service running..."
    sleep 5
done
EOF
chmod +x index.sh

# Create service configuration
cat > .config/worker/services.yaml <<'EOF'
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "index"
    command: "/home/udx/index.sh"
    autostart: true
    autorestart: true
EOF

# Run the worker
docker run -d \
  --name my-service \
  -v "$(pwd):/home/udx" \
  usabilitydynamics/udx-worker:latest

# View service logs
docker logs -f my-service
```

### Example 2: Secrets Management with Authorization

```bash
# Define secrets configuration
cat > .config/worker/worker.yaml <<'EOF'
kind: workerConfig
version: udx.io/worker-v1/config
config:
  secrets:
    API_KEY: "azure/key-vault/api-key"
    DB_PASS: "aws/secrets/database"
EOF

# Create base64-encoded Azure credentials
AZURE_CREDS=$(echo '{
  "client_id": "your-client-id",
  "client_secret": "your-client-secret",
  "tenant_id": "your-tenant-id"
}' | base64)

# Run with cloud provider credentials
docker run -d \
  --name my-secrets \
  -v "$(pwd)/.config/worker:/home/udx/.config/worker" \
  -e AZURE_CREDS="${AZURE_CREDS}" \
  usabilitydynamics/udx-worker:latest

# Verify authorization and secrets
docker exec my-secrets worker auth verify
docker exec my-secrets worker env get API_KEY
```

See [Authorization Guide](docs/authorization.md) for supported providers and credential formats (JSON, Base64, File Path).

### 💡 Simplified Deployment

For easier deployment with automatic credential detection, use the [`@udx/worker-deployment`](https://www.npmjs.com/package/@udx/worker-deployment) CLI:

```bash
# Install
npm install -g @udx/worker-deployment

# Generate config
worker config

# Run with automatic GCP authentication
worker run
```

Features:
- ✅ Auto-detects GCP credentials (service account keys, impersonation, workload identity)
- ✅ Zero-config for default file names
- ✅ Secure read-only mounts
- ✅ Interactive debugging mode

### Development Setup

```bash
# Clone and build
git clone https://github.com/udx/worker.git
cd worker
make build

# Run example service
make run VOLUMES="$(pwd)/src/examples/simple-service:/home/udx"

# View logs
make log FOLLOW_LOGS=true

# Run tests
make test
```

More examples available in [src/examples](src/examples).

## 📚 Documentation

### Core Concepts
- [Authorization](docs/authorization.md) - Credential management
- [Configuration](docs/config.md) - Worker setup
- [Services](docs/services.md) - Service management
- [CLI Reference](docs/cli.md) - Command line usage

### Additional Resources
- [Container Structure](docs/container-structure.md) - Directory layout
- [Development Notes](docs/notes.md) - Best practices
- [Git Tips](docs/git-help.md) - Version control helpers

## 🛠️ Development

```bash
# Clone repository
git clone https://github.com/udx/worker.git
cd worker

# Build image
make build

# Run container
make run      # Detached mode
make run-it   # Interactive mode

# Run tests
make test

# View all commands
make help
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

Please ensure your PR:
- Follows our coding standards
- Includes appropriate tests
- Updates relevant documentation

## 🔗 Resources

- [Docker Hub](https://hub.docker.com/r/usabilitydynamics/udx-worker)
- [Documentation](https://udx.dev/worker)
- [Product Page](https://udx.io/products/udx-worker)

## 🎯 Custom Development

Need specific features or customizations?
[Contact our team](https://udx.io/) for professional development services.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
<div align="center">
Built by <a href="https://udx.io">UDX</a> © 2025
</div>
