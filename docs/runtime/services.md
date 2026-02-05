# Service Configuration (`services.yaml`)

## Overview

`services.yaml` defines **processes that run inside the worker container**. It does not select the container image or perform deployment.

## When To Use

Use this when you need to:

- Define one or more long-running services inside the container.
- Configure commands, restart policy, and env vars for each service.

## Key Concepts

- Runtime-only: it lives inside the container at `/home/udx/.config/worker/`.
- Image selection happens at deployment time (see `docs/deploy/README.md`).

## Examples

### Basic

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

### Writing to Stdout

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "logger"
    command: "bash -c 'echo "[startup] logger"; while true; do echo "[tick] $(date)"; sleep 5; done'"
    autostart: true
    autorestart: true
```

Then view output:

```bash
worker service logs logger
```

Example scripts: `src/examples/simple-service/`

### Multiple Services

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "api-server"
    command: "npm start"
    autostart: true
    autorestart: true
    stopasgroup: true
    killasgroup: true
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
    ignore: true
```

## Common Pitfalls

- Using `services.yaml` to select the image (use `deploy.yml` instead).
- Forgetting to mount `services.yaml` into the container.

## Related Docs

- `docs/runtime/config.md`
- `docs/deploy/README.md`
