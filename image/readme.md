# UDX Worker

This repository contains the UDX Worker Docker image, designed to provide a secure and reliable environment for various automation tasks. The image includes essential tools and dependencies for development and deployment.

### Prerequisites

Before using the UDX Worker Image, make sure you have the following prerequisites installed:

- Docker: [Installation Guide](https://docs.docker.com/get-docker/)

### Build

To build the Docker image, use the following command:

1. Pull the Docker image from the Docker Hub:

   ```shell
   docker pull gcr.io/[PROJECT-ID]/[IMAGE]:[TAG]

   ## docker pull gcr.io/rabbit-ci-tooling/udx-worker:latest
   ```

2. Run the UDX Worker container:

   ```shell
    docker run -d --rm --name udx-worker gcr.io/[PROJECT-ID]/[IMAGE]:[TAG]

    ## docker run -d --rm --name udx-worker gcr.io/rabbit-ci-tooling/udx-worker:latest
   ```

3. Access the UDX Worker container:

   ```shell
   docker exec -it udx-worker bash
   ```

### Pull

```shell
docker pull gcr.io/rabbit-ci-tooling/udx-worker:latest
```

### Additional Entrypoint Script

The UDX Worker Docker image includes support for an additional entrypoint script. This is defined by the `ADDITIONAL_ENTRYPOINT` environment variable. If a child image or a user wants to include custom initialization logic, they can do so by placing their script at the path specified by `ADDITIONAL_ENTRYPOINT`.

#### How it works:

- Default Entrypoint: Executes `/usr/local/bin/entrypoint.sh` when the container starts.

- Main Script Execution: Runs main.sh to set up the environment.

- Custom Initialization: Executes the script specified by the `ADDITIONAL_ENTRYPOINT` environment variable after main.sh. This allows users who utilize the UDX Worker as a base for their own Docker images to add custom initialization logic.
    - The `ADDITIONAL_ENTRYPOINT` (`/usr/local/bin/init.sh` by default) environment variable specifies the shell script to run during the entrypoint for child images. If an entrypoint is specified in the child Dockerfile, UDX Worker features will not be enabled.

#### Example Usage:

- Create a custom script (e.g., `init.sh`) and place it at `/usr/local/bin/init.sh` inside the Docker container.
- Ensure the script has executable permissions.

```shell
# Dockerfile for a child image
FROM udx-worker:latest

# Copy custom init script to the specified path
COPY init.sh /usr/local/bin/init.sh

# Ensure the script is executable
RUN chmod +x /usr/local/bin/init.sh
```

This setup ensures flexibility and extensibility, allowing custom initialization while maintaining a secure and reliable environment for automation tasks.

### Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
