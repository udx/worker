# Examples

## simple-service

A set of small service scripts used to demonstrate supervisor behavior:

- `10_long_running.sh`
- `20_clean_exit.sh`
- `30_syntax_error.sh`
- `40_connection_error.sh`
- `50_rapid_exit.sh`

## simple-config

Minimal `worker.yaml` used by tests and quick local runs:

- `.config/worker/worker.yaml`

## deploy-image-override

Shows how to override the worker image in CI/CD using a deploy template:

- `deploy.template.yml`
- `README.md`
