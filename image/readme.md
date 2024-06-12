# UDX Worker Base Image

This repository contains the base standalone docker image for the UDX Worker.

## Prerequisites

Before using the UDX Worker Image, make sure you have the following prerequisites installed:

- Docker: [Installation Guide](https://docs.docker.com/get-docker/)

## Usage

To use the UDX Worker Image, follow these steps:

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

## Development

_NodeJS by default [pm2,ecosystem.config.js,npm]_

### Container User File Structure

```
.
|- bin-modules
    entrypoint.sh
|- fixtures
    |- application
        readme.md
    |- bin
        entrypoint.sh
    |- static
        |- configs
            readme.md
            |- default
                certificates.yml
                deployment.yml
                secrets.yml
                variables.yml
|- modules
    utils.sh
|- etc
    ecosystem.config.js
```

### Repo Structure

```
.
├── bin
│   ├── fixtures
│   │   └── application
│   │       ├── bin
│   │       └── static
│   │           └── configs
│   │               └── default
│   └── modules
└── etc
    └── home
```

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
