# Kubernetes Deployment

## Overview

Kubernetes can mount `worker.yaml` and `services.yaml` into the container using ConfigMaps/Secrets. This keeps runtime configuration separate from the image.

## When To Use

Use this when you deploy the worker as a Kubernetes Deployment and want environment-specific configuration without rebuilding images.

## Key Concepts

- Store runtime configs as ConfigMaps (or Secrets for sensitive data).
- Mount into `/home/udx/.config/worker/`.

## Examples

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: udx-worker-config
data:
  worker.yaml: |
    kind: workerConfig
    version: udx.io/worker-v1/config
    config:
      env:
        LOG_LEVEL: "info"
  services.yaml: |
    kind: workerService
    version: udx.io/worker-v1/service
    services:
      - name: "logger"
        command: "bash -c 'echo \"[startup]\"; while true; do echo \"[tick]\"; sleep 5; done'"
        autostart: true

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: udx-worker
spec:
  replicas: 1
  selector:
    matchLabels:
      app: udx-worker
  template:
    metadata:
      labels:
        app: udx-worker
    spec:
      containers:
        - name: worker
          image: usabilitydynamics/udx-worker:latest
          volumeMounts:
            - name: worker-config
              mountPath: /home/udx/.config/worker
              readOnly: true
      volumes:
        - name: worker-config
          configMap:
            name: udx-worker-config
```

## Common Pitfalls

- Mounting configs to the wrong path.
- Putting secrets in ConfigMaps instead of Kubernetes Secrets.

## Related Docs

- `docs/runtime/config.md`
- `docs/runtime/services.md`
