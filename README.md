# UDX Docker Builder

UDX Docker Builder is a robust Docker-in-Docker image that is used to create consistent build environments for cloud applications. This tool ensures that all our Docker builds are performed in a consistent environment, both locally and in our CI/CD pipelines.

In addition to creating Docker images, this tool can also generate various configuration files essential for your development and deployment workflow. It supports applications developed in multiple languages like Node.js, C#, Java, Python, Ruby and more.

The UDX Docker Builder also handles authorization and programmatic secrets management. It integrates with Google Cloud Platform's Workflow Identity for secure access management. By creating a provider, mapping attributes such as `assertion.repository`, connecting service accounts and creating a workflow identity user, it provides secure access control for your cloud resources.

## Features

- Generates Dockerfiles following best practices for your application.
- Generates GitHub Actions workflow file that can automate CI/CD processes like building, testing, and deploying your application.
- Generates `ecosystem.config.js` file for PM2, a process manager for Node.js applications.
- Generates Kubernetes (K8s) YAML configuration files for setting up your application as a service in a Kubernetes cluster.
- Handles authorization and programmatic secrets management.
- Integrates with Google Cloud Platform's Workflow Identity for secure access management.

## Usage

Use the `udx.tooling` command with the `generate` option followed by `--type` to specify the language or framework of your application. Use the `--include` option to specify which configuration files to generate.

```bash
udx.tooling generate --type=<language> --include=<config-file1>,<config-file2>,...
```

Here are some examples:

1. To generate Dockerfile and Jenkins pipeline config for a C# (.NET Core) application:

   ```bash
   udx.tooling generate --type=csharp --include=dockerfile,jenkins-pipeline
   ```

2. To generate PM2 ecosystem config and K8s service config for a Python (Django) application:

   ```bash
   udx.tooling generate --type=python --include=pm2-ecosystem,k8-app
   ```

3. To generate Dockerfile, GitHub workflow, and K8s service config for a Java (Spring Boot) application:

   ```bash
   udx.tooling generate --type=java --include=dockerfile,github-workflow,k8-app
