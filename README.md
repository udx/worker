## UDX Worker

The UDX Worker simplifies DevSecOps by providing a secure, containerized environment for handling secrets and running automation tasks. This repository contains the UDX Worker Docker image, designed for secure and reliable automation tasks based on 12-factor methodology. UDX Worker environments are ephemeral and adhere to zero-trust principles and methodology, ensuring maximum security and reliability.

### Deployment

1. Make sure Docker installed.

2. Pull the Docker image:

```shell
docker pull usabilitydynamics/udx-worker:latest
```

3. Run the Docker container:

```shell
docker run -d \
  --name my-app \
  -v $(pwd):/home/udx \
  usabilitydynamics/udx-worker:latest
```

_Make sure to mount the current directory to /home/udx in the container._

### Development

1. Clone the Repository

```shell
git clone https://github.com/udx/worker.git
cd worker
```

2. Build Image

```shell
make build
```

3. Start the container

```shell
make run
```

_Interactively_

```shell
make run-it
```

4. Run tests

```shell
make test
```

_For more details on available commands_

```shell
make
```

### Resources

- [Docker Hub](https://hub.docker.com/r/usabilitydynamics/udx-worker)
- [Marketing Page](https://udx.io/products/udx-worker)

### Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please fork the repository and submit a pull request.

### Custom Development

Looking for a unique feature for your next project? [Hire us!](https://udx.io/)
