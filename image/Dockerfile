# Use the latest version of the Ubuntu image
FROM ubuntu:24.04

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define the user to be created
ARG USER=udx
ARG UID=500
ARG GID=500

# Set environment variables to avoid interactive prompts and set a fixed timezone
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    USER=${USER} \
    HOME=/home/${USER}

# Set the shell with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install necessary packages, set timezone, and clean up in a single RUN statement
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
    gettext-base \
    sudo && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install yq, Go, Azure CLI, and Bitwarden CLI
RUN wget -qO- https://github.com/mikefarah/yq/releases/download/v4.18.1/yq_linux_amd64.tar.gz | tar xz && \
    mv yq_linux_amd64 /usr/bin/yq && \
    wget https://golang.org/dl/go1.20.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.20.5.linux-amd64.tar.gz && \
    ln -s /usr/local/go/bin/go /usr/bin/go && \
    rm go1.20.5.linux-amd64.tar.gz && \
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -Lso /usr/local/bin/bw "https://vault.bitwarden.com/download/?app=cli&platform=linux" && \
    chmod +x /usr/local/bin/bw || { \
    echo "Failed to download Bitwarden CLI with curl, trying wget"; \
    wget -O /usr/local/bin/bw "https://vault.bitwarden.com/download/?app=cli&platform=linux" && chmod +x /usr/local/bin/bw || { \
    echo "Failed to download Bitwarden CLI with wget"; \
    exit 1; \
    }; \
    }

# Create a new user and group with specific UID and GID, and set permissions
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# Switch to the user directory
WORKDIR /home/${USER}

# Install PM2 and Grunt CLI globally
RUN npm cache clean --force && \
    npm install -g pm2@5.4.1 grunt-cli@1.4.3

# Install additional npm packages globally
RUN npm cache clean --force && \
    npm install @babel/traverse@7.24.7 braces@3.0.3 http-cache-semantics@4.1.1

# Create necessary directories and set permissions
RUN mkdir -p /home/${USER}/etc /home/${USER}/.cd/configs /src/configs && \
    chown -R ${USER}:${USER} /home/${USER}

# Copy the bin, etc, and lib directories
COPY ./bin /usr/local/bin
COPY ./etc/home /home/${USER}/etc
COPY ./etc/configs /home/${USER}/.cd/configs
COPY ./lib /usr/local/lib

# Copy the worker.yml to /src/configs
COPY ./etc/configs/worker.yml /src/configs/worker.yml

# Set executable permissions and ownership for scripts
RUN chmod +x /usr/local/bin/{entrypoint.sh,test.sh} && \
    chmod +x /usr/local/lib/{auth/aws.sh,auth/azure.sh,auth/bitwarden.sh,auth/gcp.sh,auth.sh,cleanup.sh,environment.sh,init_project.sh,secrets/aws.sh,secrets/azure.sh,secrets/bitwarden.sh,secrets/gcp.sh,secrets.sh,utils.sh} && \
    chown -R ${USER}:${USER} /usr/local/bin /usr/local/lib /home/${USER}/etc /home/${USER}/.cd/configs && \
    chmod 555 /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the entrypoint script using shell form
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command to display NodeJS version
CMD ["sh", "-c", "echo NodeJS@$(node -v)"]
