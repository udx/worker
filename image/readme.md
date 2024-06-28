# UDX Worker

This repository contains the UDX Worker Docker image, designed to provide a secure and reliable environment for various automation tasks. The image includes essential tools and dependencies for development and deployment.

### Prerequisites

Before using the UDX Worker Image, make sure you have the following prerequisites installed:

- Docker: [Installation Guide](https://docs.docker.com/get-docker/)

### Build

To build the Docker image, use the following command:

```shell
docker build -t udx-worker:latest .
```

### Run

```shell
docker run --rm -it udx-worker:latest
```

### Exec

```shell
docker exec -it udx-worker bash
```

### Pull

```shell
docker pull gcr.io/rabbit-ci-tooling/udx-worker:latest
```

### Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
