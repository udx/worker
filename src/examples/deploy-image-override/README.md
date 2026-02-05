# Deploy Image Override (CI/CD)

This example shows how to override the worker image at deploy time using an environment variable and a deploy template.

Related docs: `docs/deploy/README.md`

## Steps

```bash
cd src/examples/deploy-image-override

export WORKER_IMAGE="usabilitydynamics/udx-worker:latest"

# Render deploy.yml from the template
envsubst < deploy.template.yml > deploy.yml

# Run container using worker-deployment
worker run --config=deploy.yml
```

## Notes

- `services.yaml` controls processes inside the container, not the container image.
- The image is selected in `deploy.yml` (worker-deployment).
- If `envsubst` is unavailable, use:

```bash
sed "s|\${WORKER_IMAGE}|${WORKER_IMAGE}|g" deploy.template.yml > deploy.yml
```
