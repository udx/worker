# Service Config (`services.yaml`)

## Overview

`services.yaml` defines **processes that run inside the worker container**. It does not select the container image or perform deployment.

## When To Use

Use this when you need to:

- Define one or more long-running services inside the container.
- Configure commands, restart policy, and env vars for each service.

## Key Concepts

- Runtime-only: it lives inside the container at `/home/udx/.config/worker/`.
- Image selection happens at deployment time (see `docs/deployment.md`).
- Each service is configured with a single `command` string (there is no `args` field in `services.yaml`).

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
    command: >-
      bash -lc 'echo "[startup] logger";
      while true; do echo "[tick] $(date)"; sleep 5; done'
    autostart: true
    autorestart: true
```

Then view output:

```bash
worker service logs logger --tail 100 --follow
worker service errors logger --tail 100 --follow
```

Example scripts: `src/examples/simple-service/`

### Two Independent Services (Concurrent)

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "serviceA"
    command: >-
      bash -lc 'echo "starting $SERVICE_NAME"; exec /home/udx/bin/service_a.sh'
    autostart: true
    autorestart: true
    envs:
      - "SERVICE_NAME=serviceA"
      - "LOG_LEVEL=info"

  - name: "serviceB"
    command: >-
      bash -lc 'echo "starting $SERVICE_NAME"; exec /home/udx/bin/service_b.sh'
    autostart: true
    autorestart: true
    envs:
      - "SERVICE_NAME=serviceB"
      - "LOG_LEVEL=warn"
```

### Passing Command-Line Arguments to a Script

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "job-runner"
    command: >-
      /home/udx/bin/job-runner.sh
      --config-path=/etc/app/config.json
      --mode=sync
      --retry=3
    autostart: true
    autorestart: true
```

### Reading Environment Variables in the Executed Command

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "print-service-name"
    command: >-
      bash -lc 'echo "SERVICE_NAME=$SERVICE_NAME"; exec /home/udx/bin/start.sh'
    autostart: true
    autorestart: true
    envs:
      - "SERVICE_NAME=worker-api"
```

## Common Pitfalls

- Using `services.yaml` to select the image; image selection belongs to Docker, Kubernetes, or CI/CD deployment config.
- Forgetting to mount `services.yaml` into the container.
- Expecting an `args` field in `services.yaml` (put arguments directly in `command`).
- Putting provider references (for example `azure/...`) in `services.yaml` `envs`.

## Related Docs

- `docs/config.md`
- `docs/deployment.md`
