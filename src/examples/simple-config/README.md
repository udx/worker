# Simple Config

Minimal config used by tests and quick local runs. This keeps the example
small and avoids external secret providers.

## Files

- `.config/worker/worker.yaml`

## Usage

Mount it into the container:

```bash
docker run -d \
  --name worker-simple-config \
  -v "$(pwd)/src/examples/simple-config/.config/worker:/home/udx/.config/worker" \
  usabilitydynamics/udx-worker:latest
```
