# Dockerfile
FROM ubuntu:latest

ARG USER

# Set the environment variable to service by default
ENV ENV_TYPE service

# Set NodeJS version to 20.x by default
ARG NODE_VERSION=20.x

# Copy user as an environment variable from arg
ENV USER ${USER}

# Install curl and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -
RUN apt-get install -y nodejs

RUN \
    npm install -g grunt-cli pm2 mocha should gulp-cli ionic request should-type

# Create a new user
RUN useradd -m ${USER}

# Switch to the non-root user after all commands that require root permissions have been executed
USER ${USER}

# Create a new directory for your application
WORKDIR /home/app

COPY --chown=${USER}:${USER} bin/entrypoint.sh /home/bin/entrypoint.sh

COPY --chown=${USER}:${USER} bin/modules /home/bin/modules

# Set the entrypoint to run bin/entrypoint.sh
ENTRYPOINT ["sh", "-c", "/home/bin/entrypoint.sh"]

CMD ["pm2-runtime", "start", "/home/bin/ecosystem.config.js", "--env", ${ENV_TYPE}]