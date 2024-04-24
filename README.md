# UDX Worker

UDX Worker is a tool that provides a consistent interface for running any type of software or cloud applications.

The UDX Worker is designed to be flexible and can be used in two different ways: as an npm cli or as a standalone Docker image.
<br />

## Features

- CLI
- Worker Container
- Github Actions Integration

### Installation

It can be installed globally on local machine and used to configure, build and run cloud tasks, services, applications or scripts.

#### NPM Registry

```
npm install -g udx-worker
```

#### Repository

```
npm install -g
```

### Use (In Progress)

The npm package acts as a wrapper to the Docker CLI, providing a simplified, user-friendly interface for running Docker commands.

## Worker Container

The Worker Container provides a consistent environment for running applications.

It encapsulates the operating system, system libraries, third-party modules, etc.

### Use (In Progress)

| Docker Compose Command Example                              | Description                                                                     |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `docker-compose run udx-worker-service start`               | Starts an application as a service, keeping the worker container running        |
| `docker-compose run udx-worker-service start php8.1`        | Starts a web application as a service using the PHP 8.1 web server package      |
| `docker-compose run udx-worker-task start`                  | Executes a single Node.js job task                                              |
| `docker-compose run udx-worker-task start typescript`       | Executes a task with TypeScript-based source code                               |
| `docker-compose run udx-worker-task start terraform`        | Executes Terraform configurations (init/plan/apply,interactive/non-interactive) |
| `docker-compose run udx-worker generate staging/worker.yml` | Generates a configuration manifest for the staging environment                  |

\*\* _NodeJS by default [pm2,ecosystem.config.js,npm]_

### Container File Structure

- `/home/app`: This directory contains the application code.
- `/home/bin`: This directory contains executable scripts, such as the entrypoint script.
- `/home/etc`: This directory contains configuration files, such as the `ecosystem.config.js` file.
- `/home/fixtures`: This directory contains any fixtures for the application.
  <br />

### Repo Structure

- `./.github/workflow`: CI workflows configurations.

- `./bin/entrypoint.sh`: entrypoint shell script that configure environment modules.
- `./bin/modules/*`: shell modules that enable environment features needed for the run.

- `./ci/git-version.yml`: GitVersion configuration file to generate semantic version numbers based on the state of Git repository.

- `./cli/index.js`: cli program that serves as simple wrapper to to run `docker-compose` commands.

- `./etc/home/ecosystem.config.js`: PM2 uses this file to manage application settings.

- `./fixtures/*`: the scripts, apps and data used to create a controlled scenario to know what the output should be for certain inputs.

- `./Dockerfile`: used by Docker to build an image.
- `./docker-compose.yml`: configure docker worker containers.
- `./package.json`: manifest file for worker cli.
