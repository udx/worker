Non-apt dependency rules:
- Detect ARG-pinned versions, URL-pinned versions, package-manager pins, and dynamically installed tools from Dockerfile.
- For each non-apt pinned dependency, identify its upstream source from Dockerfile context and check the latest stable version.
- Update only Dockerfile dependency pins and ARG values when the dependency report or upstream source shows a newer version.
- Preserve the ubuntu base image tag unless explicitly necessary to make reported apt versions valid.
- Keep dynamically installed dependencies unpinned unless Dockerfile already pins them; mention them in the changelog only.
- If a Dockerfile dependency cannot be checked confidently, leave it unchanged and mention the reason in the changelog.
