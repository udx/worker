You are updating Dockerfile dependency pins for this repository.

Inputs:
- Dockerfile: `Dockerfile`
- Dependency report: `docker-dependency-report.json`

Intent:
- Read both input files before editing.
- The report was produced by building a temporary copy of Dockerfile with apt pins removed.
- The report may include probe_config.content from ci/configs/docker-dependency-probe.yaml.
- Treat the report as the primary evidence for apt package versions that install successfully for the current base image.
- Treat Dockerfile as the source of truth for every non-apt dependency. Detect ARG-pinned versions, URL-pinned versions, package-manager pins, and dynamically installed tools directly from Dockerfile.
- For non-apt dependencies, identify the upstream source from Dockerfile context, then check that source for the latest stable version.
- Update only Dockerfile dependency pins and ARG values when the report or checked source shows a newer version.
- Preserve the ubuntu base image tag unless explicitly necessary to make the reported versions valid.
- Keep dynamically installed dependencies unpinned unless Dockerfile already pins them; mention them in the changelog only.
- Do not edit workflow files, docs, tests, or application code.
- Do not commit, push, or create a pull request; this workflow will do that.
- If a Dockerfile dependency cannot be checked confidently, leave it unchanged and mention the reason in the changelog.

Expected Dockerfile update categories:
- apt package pins from dependencies.apt[].installed
- Non-apt ARG pins discovered in Dockerfile after checking their upstream source.
- Non-apt URL/package-manager pins discovered in Dockerfile after checking their upstream source.
- Dynamically installed tools discovered in Dockerfile that intentionally remain unpinned.

After editing:
- Print a concise changelog of every version change.
- Print any dependency that was observed but intentionally not pinned.
