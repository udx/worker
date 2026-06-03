You are updating Dockerfile dependency pins for this repository.

Inputs:
- Dockerfile: `Dockerfile`
- Dependency report: `docker-dependency-report.json`

Automation contract:
- Read both input files before editing.
- The dependency report already resolves current apt package versions for the configured Ubuntu base image using a no-pin apt probe.
- The no-pin apt probe is authoritative for apt package updates: it was built from a temporary Dockerfile where apt pins were removed, then queried with `dpkg-query`.
- You are responsible for detecting and checking every non-apt dependency directly from Dockerfile.

Dependency handling:
- For apt packages, update Dockerfile pins only from `dependencies.apt[].installed` in the dependency report. Do not use apt websites, package search pages, or guessed versions for apt pins.
- If an apt package from Dockerfile is missing from the report, leave that package unchanged and explain it in the changelog.
- For non-apt dependencies, detect ARG-pinned versions, URL-pinned versions, package-manager pins, and dynamically installed tools from Dockerfile.
- For each non-apt pinned dependency, identify its upstream source from Dockerfile context and check the latest stable version.
- Update only Dockerfile dependency pins and ARG values when the report or upstream source shows a newer version.
- Preserve the ubuntu base image tag unless explicitly necessary to make the reported versions valid.
- Keep dynamically installed dependencies unpinned unless Dockerfile already pins them; mention them in the changelog only.
- If a Dockerfile dependency cannot be checked confidently, leave it unchanged and mention the reason in the changelog.

Editing rules:
- Edit only Dockerfile dependency pins and ARG values.
- Do not edit workflow files, docs, tests, or application code.
- Do not commit, push, or create a pull request; this workflow will do that.

Output:
- Print a changelog using this template:

```text
Docker dependency changelog

Updated:
- <dependency>: <old version> -> <new version> (<source>)

Unchanged:
- <dependency>: <version> (<reason>)

Observed but not pinned:
- <dependency>: <observed version> (<reason>)

Notes:
- <short note, or "None">
```

- Omit empty sections except `Notes`.
