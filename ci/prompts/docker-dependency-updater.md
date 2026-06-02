You are updating Dockerfile dependency pins for this repository.

Intent:
- Read Dockerfile and docker-dependency-report.json.
- The report was produced by building a temporary copy of Dockerfile with apt pins and selected ARG pins removed.
- The report may include probe_config.content from ci/configs/docker-dependency-probe.yaml.
- Treat the report as the primary evidence for versions that install successfully for the current base image when a dependency uses `update_strategy: unpin_probe`.
- Treat probe_config.content as repo-specific hints, not as the source of truth.
- For dependencies with `update_strategy: copilot_latest`, use the report and Dockerfile to identify the current installed version, then check the dependency source for the latest stable version.
- Update only Dockerfile dependency pins and ARG values when the report or checked source shows a newer version.
- Preserve the ubuntu base image tag unless explicitly necessary to make the reported versions valid.
- Keep observed-only dependencies unpinned unless Dockerfile already pins them; mention their latest observed versions in the changelog only.
- Do not edit workflow files, docs, tests, or application code.
- Do not commit, push, or create a pull request; this workflow will do that.
- If Dockerfile contains a versioned dependency that is not represented in the report or probe_config, mention it as missing probe coverage.

Expected Dockerfile update categories:
- apt package pins from dependencies.apt[].installed
- ARG pins from dependencies.probes[] entries with maps_to_arg values and `update_strategy: unpin_probe`
- ARG pins from dependencies.probes[] entries with maps_to_arg values and `update_strategy: copilot_latest`, after checking their source
- observed-only tools from dependencies.observed_only[] entries

After editing:
- Print a concise changelog of every version change.
- Print any dependency that was observed but intentionally not pinned.
