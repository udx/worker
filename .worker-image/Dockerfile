#
# UDX Worker Dockerfile
#
# Description: This Dockerfile is used to build a Docker image for a UDX Worker.
#
# The image is based on the official Ubuntu image and includes the following:
# - Ubuntu (based on the latest version)
# - Curl cli
# - GnuPG standard
# - Node.js (20.x by default)
# - NPM
# - NPM packages globally (grunt-cli pm2 mocha should gulp-cli ionic request should-type)
# 
# ARGs: 
# - USER: The user to be created in the image (Default: udx-worker).
# - NODE_VERSION: The version of Node.js to be installed in the image (Default: 20.x)
# 
# ENVs:
# - USER: The user to be created in the image (Default: udx-worker inherited from USER arg).
# 
#

FROM ubuntu:latest

# Define arguments
ARG USER=udx-worker

# Set NodeJS version to 20.x by default
ARG NODE_VERSION=20.x

# Set the source path to an (current location by default)
ARG APP_SRC_PATH "src/app"

# Copy user as an environment variable from arg
ENV USER ${USER}

# Install curl and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install yq
RUN apt-get update && apt-get install -y wget && \
    wget https://github.com/mikefarah/yq/releases/download/v4.6.1/yq_linux_amd64 -O /usr/bin/yq && \
    chmod +x /usr/bin/yq    

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash -

# Install Node.js
RUN apt-get install -y nodejs

# Install npm packages globally
RUN \
    npm install -g grunt-cli pm2 mocha should gulp-cli ionic request should-type

# Copy the bin, etc directories to the image
COPY --chown=${USER}:${USER} ./bin          /home/bin
COPY --chown=${USER}:${USER} ./etc/home     /home/core

# Create a new user
RUN useradd -m ${USER}

# Switch to the non-root user after all commands that require root permissions have been executed
USER ${USER}

# Create a new directory for your application
WORKDIR /home/app

# Copy the application source code
COPY --chown=${USER}:${USER} ${APP_SRC_PATH} /home/app

# Set the entrypoint to run bin/entrypoint.sh
ENTRYPOINT ["sh", "-c", "/home/bin/entrypoint.sh"]