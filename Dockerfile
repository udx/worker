# Dockerfile
FROM ubuntu:latest

ARG USER

ENV ENV_TYPE=service
ENV USER=${USER}

# Install curl and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

RUN \
    npm install -g grunt-cli pm2 mocha should gulp-cli ionic request should-type

# Create a new user
RUN useradd -m ${USER}

# Switch to the non-root user after all commands that require root permissions have been executed
USER ${USER}

# Create a new directory for your application
WORKDIR /home/app

# Copy package.json and package-lock.json
COPY /src/app/package*.json ./

# Install application dependencies
RUN npm install

# Copy the rest of the application
COPY /src/app .

COPY --chown=${USER}:${USER} bin/entrypoint.sh /home/bin/entrypoint.sh

# Set the entrypoint to run bin/entrypoint.sh
ENTRYPOINT ["sh", "-c", "/home/bin/entrypoint.sh"]
