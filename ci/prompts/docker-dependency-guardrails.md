You are updating Dockerfile dependency pins for this repository.

Inputs:
- Dockerfile: `Dockerfile`
- Dependency report: `docker-dependency-report.json`

Hard boundaries:
- This is an edit-only dependency update task.
- Read both input files before editing.
- Edit only Dockerfile dependency pins and ARG values.
- Do not edit workflow files, docs, tests, or application code.
- Do not validate, build, test, run the container pipeline, inspect GitHub Actions runs, wait for workflows, create pull requests, commit, push, or request reviews.
- Do not run `docker`, `make`, test commands, CI commands, `gh run`, `gh workflow`, `gh pr`, `git commit`, `git push`, or any command that waits on external workflow state.
- If an update cannot be verified from the dependency report or upstream release metadata without validation, leave it unchanged and mention why.
