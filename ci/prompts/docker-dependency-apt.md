Apt dependency rules:
- The dependency report already resolves current apt package versions for the configured Ubuntu base image using a no-pin apt probe.
- The no-pin apt probe is authoritative for apt package updates: it was built from a temporary Dockerfile where apt pins were removed, then queried with `dpkg-query`.
- For apt packages, update Dockerfile pins only from `dependencies.apt[].installed` in the dependency report.
- Do not use apt websites, package search pages, or guessed versions for apt pins.
- If an apt package from Dockerfile is missing from the report, leave that package unchanged and explain it in the changelog.
