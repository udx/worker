#
# UDX Worker Docker Image
#
# Description: This Dockerfile is used to build a Docker image for a UDX Worker.
#
# The image is based on the official Ubuntu image and includes the following:
# - Ubuntu (based on the latest version)
# - Curl cli
# - GnuPG standard
# - Node.js (20.x by default)
# - NPM
# - Python
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

# Create a new image based on the latest Ubuntu image
FROM ubuntu:latest

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define arguments
ARG USER=udx-worker

# Set NodeJS version to 20.x by default
ARG NODE_VERSION=20.x

# Copy user as an environment variable from arg
ENV USER=${USER}

# Set the environment variable to run Python unbuffered
ENV PYTHONUNBUFFERED=1

# Install curl, wget, gnupg, Node.js, npm and Python
RUN apt-get update && \
    apt-get install -y curl gnupg wget python3 python3-pip && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    # Install pyyaml
    pip3 install pyyaml

# Install npm packages globally
RUN npm install -g grunt-cli pm2 mocha should gulp-cli ionic request should-type

# Create a new user
RUN useradd -m ${USER}

# Create a new directory for the user and change ownership
RUN mkdir -p /home/${USER} && chown -R ${USER}:${USER} /home/${USER}

# Copy the bin, etc directories to the image
COPY --chown=${USER}:${USER} ./bin              /home/${USER}/bin-modules
COPY --chown=${USER}:${USER} ./etc/home         /home/${USER}/etc
COPY --chown=${USER}:${USER} ./etc/configs      /home/${USER}/worker-configs

# Switch to the non-root user after all commands that require root permissions have been executed
USER ${USER}

# Create a new directory for user
WORKDIR /home/${USER}

# Set the entrypoint to run bin/entrypoint.sh
ENTRYPOINT ["sh", "-c", "/home/${USER}/bin-modules/entrypoint.sh"]