
# UDX Docker Builder

UDX Docker Builder is a robust Docker-in-Docker image that is used to create consistent build environments for cloud applications. This tool ensures that all our Docker builds are performed in a consistent environment, both locally and in our CI/CD pipelines.

This tool focuses specifically on the "Build" phase of the software development lifecycle. It automates the generation of various configuration files essential for your build process. It supports applications developed in multiple languages like Node.js, C#, Java, Python, Ruby and more. UDX Docker Builder also handles authorization and programmatic secrets management, integrating with Google Cloud Platform's Workflow Identity for secure access management.

All this power is bundled into a cloud-native toolset that helps teams transition away from older CI/CD tools like Jenkins, enabling them to leverage modern development practices and technologies.

## Approach

![Atlas 12-Factor Value Stream for Software Development](https://storage.googleapis.com/stateless-udx-io/2023/11/39a1d248-atlas-left-shifted-enterprise-value-stack-for-software-development-v1.png)

UDX Docker Builder adopts an approach that emphasizes the 12-factor methodology while adding the "Manage" phase. It connects work items, release packages, Jira Stories, and Metadata to create a Software Bill of Materials (SBOM), helping measure lead times and visualize workflows.

Here's how it works:

1. **Build Phase:**
   - The input is your code hosted on platforms like GitHub.
   - It performs code scanning using tools such as Trivy to ensure security.
   - The continuous integration (CI) process creates the application components.
   - These are then stored and distributed via an Artifact Registry.

The other phases (Manage & Release) are not handled by UDX Docker Builder but can be managed by other tools or services as per your workflow requirements.

## Benefits

1. **Consistent Environment:** Eliminates the "it works on my machine" problem and ensures that the application behaves the same way in all environments.

2. **Automated Configuration:** Saves developers time by automating the generation of various configuration files such as Dockerfiles, GitHub Actions workflows, Kubernetes configuration files.

3. **Versatile Language Support:** Supports applications developed in multiple languages like Node.js, C#, Java, Python, Ruby.

4. **Secure Access Management:** Handles authorization and programmatic secrets management by integrating with Google Cloud Platform's Workflow Identity.

5. **Cloud-Native Transition:** Provides a cloud-native toolset that helps teams transition away from older CI/CD tools to leverage modern development practices and technologies.

## Usage

Use the `udx.tooling` command with the `generate` option followed by `--type` to specify the language or framework of your application. Use the `--include` option to specify which configuration files to generate.

```bash
udx.tooling generate --type=<language> --include=<config-file1>,<config-file2>,...
```

Here are some examples:

1. To generate Dockerfile and GitHub Actions workflow for a C# (.NET Core) application:

   ```bash
   udx.tooling generate --type=csharp --include=dockerfile,github-workflow
   ```

2. To generate PM2 ecosystem config and K8s service config for a Python (Django) application:

   ```bash
   udx.tooling generate --type=python --include=pm2-ecosystem,k8-app
   ```

3. To generate Dockerfile, GitHub workflow, and K8s service config for a Java (Spring Boot) application:

   ```bash
   udx.tooling generate --type=java --include=dockerfile,github-workflow,k8-app
   ```
