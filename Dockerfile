# Use the latest version of the Ubuntu image with a specific tag for stability
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

# Install necessary packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tzdata=2024a-3ubuntu1.1 \
    curl=8.5.0-2ubuntu10.6 \
    bash=5.2.21-2ubuntu4 \
    apt-utils=2.7.14build2 \
    gettext=0.21-14ubuntu2 \
    gnupg=2.4.4-2ubuntu17 \
    ca-certificates=20240203 \
    lsb-release=12.0-2 \
    jq=1.7.1-3build1 \
    zip=3.0-13build1 \
    unzip=6.0-28ubuntu4 \
    nano=7.2-2build1 \
    vim=2:9.1.0016-1ubuntu7.5 \
    python3.12=3.12.3-1ubuntu0.3 \
    python3-pip=24.0+dfsg-1ubuntu1.1 \
    supervisor=4.2.5-1ubuntu0.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure the timezone
RUN echo $TZ > /etc/timezone && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Install yq (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -sL https://github.com/mikefarah/yq/releases/download/v4.44.6/yq_linux_${ARCH}.tar.gz | tar xz && \
    mv yq_linux_${ARCH} /usr/bin/yq && \
    rm -rf /tmp/*

# Install Google Cloud SDK (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    curl -sSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-504.0.0-linux-x86_64.tar.gz" -o google-cloud-sdk.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
    curl -sSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-504.0.0-linux-arm.tar.gz" -o google-cloud-sdk.tar.gz; \
    fi && \
    tar -xzf google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh -q && \
    rm -rf google-cloud-sdk.tar.gz /tmp/* /var/tmp/*

# Add Google Cloud SDK to PATH
ENV PATH=$PATH:/google-cloud-sdk/bin

# Install AWS CLI (architecture-aware)
RUN ARCH=$(uname -m) && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws /tmp/* /var/tmp/*

# Install Azure CLI with manual GPG key retrieval as root
ENV GNUPGHOME=/root/.gnupg
RUN mkdir -p $GNUPGHOME && \
    chmod 700 $GNUPGHOME && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys EB3E94ADBE1229CF && \
    gpg --export EB3E94ADBE1229CF | tee /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends azure-cli=2.67.0-1~noble && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Bitwarden CLI (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    curl -Lso /usr/local/bin/bw "https://vault.bitwarden.com/download/linux/amd64/bw"; \
    elif [ "$ARCH" = "aarch64" ]; then \
    curl -Lso /usr/local/bin/bw "https://vault.bitwarden.com/download/linux/arm64/bw"; \
    else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    chmod +x /usr/local/bin/bw && \
    rm -rf /tmp/* /var/tmp/*

# Create a new user and group with specific UID and GID, and set permissions
RUN groupadd -g ${GID} ${USER} && \
    useradd -l -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# Create the Supervisor log directory and set permissions
RUN mkdir -p /var/log/supervisor && \
    chown -R ${USER}:${USER} /var/log/supervisor    

# Create a directory for Supervisor runtime files
RUN mkdir -p /var/run/supervisor && chown -R ${USER}:${USER} /var/run/supervisor

# Prepare directories for the user and worker configuration
RUN mkdir -p /etc/worker /home/${USER}/.cd/bin /home/${USER}/.cd/configs && \
    touch /home/${USER}/.cd/configs/merged_worker.yml && \
    mkdir -p /home/${USER}/.config/gcloud && \
    mkdir -p /home/${USER}/.azure && \
    chown -R ${UID}:${GID} /etc/worker /home/${USER}/.cd /home/${USER}/.config /home/${USER}/.azure && \
    chmod 600 /home/${USER}/.cd/configs/merged_worker.yml

# Switch to the user directory
WORKDIR /home/${USER}

# Copy built-in worker.yml to the container
COPY ./src/configs /etc/worker
COPY ./src/scripts /usr/local/scripts

# Copy the bin, etc, and lib directories
COPY ./etc/home /home/${USER}/etc
COPY ./lib /usr/local/lib
COPY ./bin/entrypoint.sh /usr/local/bin/entrypoint.sh

# Copy the tests directory
COPY ./tests/main.sh /usr/local/tests/main.sh
COPY ./tests/tasks /usr/local/tests/tasks

# Set permissions during build
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/tests/main.sh && \
    chown -R ${UID}:${GID} /usr/local/lib /etc/worker /home/${USER}/etc /home/${USER}/.cd /usr/local/tests

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the entrypoint script using shell form
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set the default command
CMD ["sh"]