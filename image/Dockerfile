# Use the latest version of the Ubuntu image
FROM ubuntu:24.04

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define arguments
ARG USER=udx
ARG NODE_VERSION=20

# Set environment variables to avoid interactive prompts and set a fixed timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV USER=${USER}
ENV HOME=/home/${USER}

# Set the additional entrypoint script path
ENV ADDITIONAL_ENTRYPOINT=/usr/local/bin/init.sh

# Set the shell with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install necessary packages in a single RUN statement to reduce layers and pin versions
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tzdata=2024a-3ubuntu1.1 \
    curl=8.5.0-2ubuntu10.1 \
    bash=5.2.21-2ubuntu4 \
    gnupg=2.4.4-2ubuntu17 \
    wget=1.21.4-1ubuntu4 \
    ca-certificates \
    nodejs \
    npm \
    e2fsprogs && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    wget -qO- https://github.com/mikefarah/yq/releases/download/v4.18.1/yq_linux_amd64.tar.gz | tar xz && \
    mv yq_linux_amd64 /usr/bin/yq

# Install Go and update to the latest secure version
RUN wget https://golang.org/dl/go1.20.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.20.5.linux-amd64.tar.gz && \
    ln -s /usr/local/go/bin/go /usr/bin/go && \
    rm go1.20.5.linux-amd64.tar.gz

# Create a new user and ensure home directory permissions are set correctly
RUN useradd -m ${USER}

# Switch to the user directory
WORKDIR /home/${USER}

# Install PM2 and Grunt CLI globally and update vulnerable packages
RUN npm install -g pm2@5.4.1 grunt-cli@1.4.3 && \
    npm install @babel/traverse@7.24.7 braces@3.0.3 http-cache-semantics@4.1.1

# Copy the bin, etc directories to the image and set correct permissions
COPY ./bin /usr/local/bin
COPY ./bin/modules /usr/local/bin/modules
COPY ./etc/home /home/${USER}/etc
COPY ./etc/configs /home/${USER}/.cd/configs

# Set executable permissions for main.sh, entrypoint.sh, and modules, and set read-only permissions
RUN chmod +x /usr/local/bin/main.sh /usr/local/bin/entrypoint.sh /usr/local/bin/modules/*.sh && \
    chown -R ${USER}:${USER} /usr/local/bin /home/${USER}/etc /home/${USER}/.cd/configs && \
    chmod 555 /usr/local/bin/entrypoint.sh /usr/local/bin/main.sh /usr/local/bin/modules/environment.sh /usr/local/bin/modules/init_project.sh /usr/local/bin/modules/utils.sh

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the new entrypoint script using shell form
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command to display NodeJS version in the desired format
CMD ["sh", "-c", "echo NodeJS@$(node -v)"]
