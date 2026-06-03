# Simple Service Examples

These scripts demonstrate common service behaviors for `services.yaml`.

Related docs: `docs/services.md`

## Scripts

- `10_long_running.sh` - long-running process
- `20_clean_exit.sh` - exits cleanly
- `30_syntax_error.sh` - fails due to syntax error
- `40_connection_error.sh` - simulates a connection failure
- `50_rapid_exit.sh` - exits quickly

## Usage

Create a `services.yaml` that points to one or more scripts:

```yaml
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "long-running"
    command: "/home/udx/10_long_running.sh"
    autostart: true
    autorestart: true
```

Mount the directory when running the container:

```bash
docker run -d \
  --name my-service \
  -v "$(pwd)/src/examples/simple-service:/home/udx" \
  -v "$(pwd)/.config/worker:/home/udx/.config/worker" \
  usabilitydynamics/udx-worker:latest
```

Then check logs:

```bash
worker service logs long-running
```
