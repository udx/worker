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
    lsb-release \
    nodejs \
    npm \
    e2fsprogs \
    jq \
    gettext-base && \
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

# Add the Microsoft package repository and install Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Bitwarden CLI with debugging and retry logic
RUN for i in {1..5}; do \
        echo "Attempt $i to download Bitwarden CLI"; \
        curl -Lso /usr/local/bin/bw "https://vault.bitwarden.com/download/?app=cli&platform=linux" && break || echo "Retrying..."; \
    done && \
    test -f /usr/local/bin/bw && chmod +x /usr/local/bin/bw || { \
        echo "Failed to download Bitwarden CLI with curl, trying wget"; \
        wget -O /usr/local/bin/bw "https://vault.bitwarden.com/download/?app=cli&platform=linux" && chmod +x /usr/local/bin/bw || { \
            echo "Failed to download Bitwarden CLI with wget"; \
            exit 1; \
        }; \
    }

# Create a new user and ensure home directory permissions are set correctly
RUN useradd -m ${USER}

# Switch to the user directory
WORKDIR /home/${USER}

# Install PM2 and Grunt CLI globally and update vulnerable packages
RUN npm install -g pm2@5.4.1 grunt-cli@1.4.3 && \
    npm install @babel/traverse@7.24.7 braces@3.0.3 http-cache-semantics@4.1.1

# Copy the bin and etc directories to the image and set correct permissions
COPY ./bin /usr/local/bin
COPY ./etc/home /home/${USER}/etc
COPY ./etc/configs /home/${USER}/.cd/configs

# Copy the lib directory to the image
COPY ./lib /usr/local/lib

# Set executable permissions for entrypoint.sh and other scripts
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/test.sh && \
    find /usr/local/lib -type f -name "*.sh" -exec chmod +x {} \; && \
    chown -R ${USER}:${USER} /usr/local/bin /usr/local/lib /home/${USER}/etc /home/${USER}/.cd/configs && \
    chmod 555 /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the new entrypoint script using shell form
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command to display NodeJS version in the desired format
CMD ["sh", "-c", "echo NodeJS@$(node -v)"]
