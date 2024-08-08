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
    curl=8.5.0-2ubuntu10.2 \
    bash=5.2.21-2ubuntu4 \
    gnupg=2.4.4-2ubuntu17 \
    ca-certificates=20240203 \
    lsb-release=12.0-2 \
    nodejs=18.19.1+dfsg-6ubuntu5 \
    npm=9.2.0~ds1-2 \
    jq=1.7.1-3build1 \
    sudo=1.9.15p5-3ubuntu5 && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install yq
RUN curl -sL https://github.com/mikefarah/yq/releases/download/v4.18.1/yq_linux_amd64.tar.gz | tar xz && \
    mv yq_linux_amd64 /usr/bin/yq

# Install Go
RUN curl -sL https://golang.org/dl/go1.20.5.linux-amd64.tar.gz -o go1.20.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.20.5.linux-amd64.tar.gz && \
    ln -s /usr/local/go/bin/go /usr/bin/go && \
    rm go1.20.5.linux-amd64.tar.gz

# Install Azure CLI
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends azure-cli=2.63.0-1~noble && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Bitwarden CLI
RUN curl -Lso /usr/local/bin/bw "https://vault.bitwarden.com/download/?app=cli&platform=linux" && \
    chmod +x /usr/local/bin/bw

# Create a new user and group with specific UID and GID, and set permissions
RUN groupadd -g ${GID} ${USER} && \
    useradd -l -m -u ${UID} -g ${GID} -s /bin/bash ${USER} && \
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
COPY ./src/configs /home/${USER}/.cd/configs
COPY ./lib /usr/local/lib

# Copy the worker.yml to /src/configs
COPY ./src/configs/worker.yml /home/${USER}/.cd/configs/worker.yml

# Set executable permissions and ownership for scripts
RUN chmod +x /usr/local/bin/* && \
    chmod +x /usr/local/lib/* && \
    chown -R ${USER}:${USER} /usr/local/bin /usr/local/lib /home/${USER}/etc /home/${USER}/.cd/configs && \
    chmod 555 /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the entrypoint script using shell form
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set the default command to execute bin/test.sh
CMD ["/usr/local/bin/test.sh"]
