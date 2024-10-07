# UDX Worker

The UDX Worker simplifies DevSecOps by providing a secure, containerized environment for handling secrets and running automation tasks.

This repository contains the UDX Worker Docker image, designed for secure and reliable automation tasks based on 12-factor methodology.

UDX Worker environments are ephemeral and adhere to zero-trust principles and methodology, ensuring maximum security and reliability.

![UDX Worker Diagram](https://storage.googleapis.com/stateless-udx-io/2023/07/e5a9ac2b-understanding-containerization-in-microservices-architecture.png)

## Prerequisites

Before using the UDX Worker Image, make sure you have the following prerequisites installed:

- Docker: [Installation Guide](https://docs.docker.com/get-docker/)

## Quick Start

1. **Clone the Repository**

```shell
git clone https://github.com/udx/udx-worker.git
cd udx-worker
```

2. **Run Dev Pipeline**

```shell
make dev-pipeline
```

3. **Utilize commands for local development**

```shell
make build
```

```shell
make run
```

```shell
make run-interactive
```

For more details on available commands

```shell
make
```

## Detailed Documentation

- [Secure Environment](src/configs/readme.md)
- [Auth Modules](lib/auth/readme.md)
- [Configuration and Environment Management](lib/secrets/readme.md)

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please fork the repository and submit a pull request.

### Custom Development

Looking for a unique feature for your next project? [Hire us!](https://udx.io/)
