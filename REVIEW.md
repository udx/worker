# Review Guidelines - worker (udx-worker base image)

Base container image for the entire UDX worker family (worker-nodejs, worker-php, worker-tooling and their children worker-site, worker-engine, docker-sftp, plus R2A). Ubuntu base, runs as non-root UID/GID 500. A regression here propagates to every downstream image and every tenant workload.

## Critical Areas (extra scrutiny)

- `bin/entrypoint.sh`: the ENTRYPOINT for the whole image family. Trace every change for child-image compatibility (children rely on its env handling, service startup, and exit behavior).
- `lib/*.sh` (`process_manager.sh`, `env_handler.sh`, `secrets.sh`, `worker_config.sh`, `runtime_output.sh`, `cli.sh`): shared runtime library. Function signature or output format changes are breaking changes for children; require a check of downstream usage.
- `src/configs/services.yaml` and `src/configs/worker.yaml`: default service and worker config schema consumed downstream.
- Dockerfile UID/GID 500 creation and the `chown -R` block: everything downstream assumes UID 500 with specific ownership. Changes to user, ownership, or directory permissions are the classic source of child-image breakage (log dirs, port binds, home paths). Flag ANY permissions change and require downstream verification.
- `worker.yml` secrets resolution (`gcp/...`, `aws/...`, `azure/...`, `bitwarden/...` refs): watch for changes that could log resolved secret values or weaken provider auth handling.

## Release Model

- Version comes from GitVersion (`ci/git-version.yml`): merge to `latest` cuts a Minor release automatically when a filtered path changed (`Dockerfile`, `bin/**`, `lib/**`, `src/**`, `etc/**`, `test/**`, `Makefile*`, `ci/**`). There is no changelog; the PR description is the release note - require it to state downstream impact (which child images need rebumps).
- Child images pin this image by version tag; a release is inert for children until each bumps its `FROM` pin. Findings about rollout should reference that pin chain.

## Conventions to Enforce

- Shell passes shellcheck with no new exclusions; Dockerfile passes hadolint; YAML passes yamllint (all run in CI on every push).
- Tool and package versions in the Dockerfile stay pinned; reject newly unpinned installs or removed checksum verification.
- `make test` and `make build` stay the canonical local verification commands.

## Security

- This image handles cloud credentials (GCP_CREDS, AWS_CREDS, AZURE_CREDS, BITWARDEN_CREDS) to resolve secrets. Flag anything that writes credentials to disk outside established paths, echoes them, or broadens their lifetime.
