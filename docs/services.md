# Service Configuration

## Overview

The UDX Worker uses `services.yaml` to define and manage multiple services. Each service can be configured with its own runtime settings, environment variables, and behavior policies.

## File Location

```bash
/home/udx/.config/worker/services.yaml
```

## Configuration Structure

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `kind` | string | Yes | - | Must be `workerService` |
| `version` | string | Yes | - | Must be `udx.io/worker-v1/service` |
| `services` | array | Yes | - | List of service definitions |

### Service Definition Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | Yes | - | Unique service identifier |
| `command` | string | Yes | - | Command to execute |
| `ignore` | boolean | No | `false` | Skip service management |
| `autostart` | boolean | No | `true` | Start on worker launch |
| `autorestart` | boolean | No | `false` | Restart on failure |
| `envs` | array | No | `[]` | Environment variables |

## Basic Example

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "web-server"
    command: "python app.py"
    autostart: true
    autorestart: true
    envs:
      - "PORT=8080"
      - "DEBUG=true"
```

## Advanced Examples

### Multiple Services

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "api-server"
    command: "node api/server.js"
    autostart: true
    autorestart: true
    envs:
      - "PORT=3000"
      - "NODE_ENV=production"

  - name: "worker-queue"
    command: "python worker.py"
    autostart: true
    envs:
      - "QUEUE_URL=redis://localhost:6379"

  - name: "monitoring"
    command: "./monitor.sh"
    ignore: true  # Temporarily disabled
```

### Service with Complex Command

```yaml
services:
  - name: "data-processor"
    command: "bash -c 'source .env && python -m processor.main --config=prod.json'"
    autostart: true
    autorestart: true
    envs:
      - "PYTHONPATH=/app"
      - "LOG_LEVEL=info"
```

## Best Practices

1. **Service Naming**
   - Use descriptive, lowercase names
   - Separate words with hyphens
   - Keep names concise but meaningful

2. **Command Definition**
   - Use absolute paths when possible
   - Quote commands with spaces or special characters
   - Consider using shell scripts for complex commands

3. **Environment Variables**
   - Use uppercase for variable names
   - Group related variables together
   - Document required variables

4. **Restart Policies**
   - Enable `autorestart` for critical services
   - Use `ignore` for maintenance or debugging
   - Consider dependencies between services

## Service Status

When running `worker service list`, services show the following status indicators:

| Symbol | Status | Description |
|--------|---------|-------------|
| ✅ | RUNNING | Service is running normally |
| ⛔ | STOPPED | Service was stopped with `worker service stop` |
| 💀 | FATAL | Service exited (any exit code) |
| 🔄 | RETRY | Service is retrying (with autorestart: true) |
| ⚠️ | STARTING | Service is starting up |

### Service Types

1. **Long-running Services**
   ```yaml
   - name: "web-server"
     command: "python server.py"
     autorestart: true    # Restarts on exit
   ```
   - Shows as RUNNING (✅) while active
   - Shows as RETRY (🔄) then FATAL (💀) if it keeps failing

2. **One-shot Tasks**
   ```yaml
   - name: "setup"
     command: "./setup.sh"
     autorestart: false   # Runs once
   ```
   - Use `worker service stop` for clean completion (⛔)
   - Otherwise shows as FATAL (💀) after exit

Note: Exit codes (0 or non-zero) don't affect the final status. What matters is:
- Whether the service keeps running (RUNNING ✅)
- How it stops (STOPPED ⛔ vs FATAL 💀)

Example:
```bash
# Long-running service and one-shot task
$ worker service list
✅ service1    RUNNING   pid 123   0:01:23
⛔ service2    STOPPED   Apr 08    11:30 AM

# Long-running service and failed task
$ worker service list
✅ service1    RUNNING   pid 123   0:01:23
💀 service2    FATAL    Apr 08    11:30 AM
```

## Monitoring and Management

Use the following CLI commands to manage services:

```bash
# List all services
worker service list

# Check specific service status
worker service status web-server

# View service logs
worker service logs web-server

# Restart a service
worker service restart web-server
```