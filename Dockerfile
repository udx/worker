# Use the latest version of the Ubuntu image with a specific tag for stability
FROM ubuntu:25.04

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Set base environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    USER=udx \
    UID=500 \
    GID=500 \
    HOME=/home/udx \
    # Worker specific paths
    WORKER_BASE_DIR=/opt/worker \
    WORKER_CONFIG_DIR=/etc/worker \
    WORKER_APP_DIR=/opt/worker/apps \
    WORKER_DATA_DIR=/opt/worker/data \
    WORKER_LIB_DIR=/usr/local/worker/lib \
    WORKER_BIN_DIR=/usr/local/worker/bin \
    WORKER_ETC_DIR=/usr/local/worker/etc \
    # Add worker bin to PATH
    PATH=/usr/local/worker/bin:${PATH} \
    # Cloud SDK configurations
    CLOUDSDK_CONFIG=/usr/local/configs/gcloud \
    AWS_CONFIG_FILE=/usr/local/configs/aws \
    AZURE_CONFIG_DIR=/usr/local/configs/azure

# Set the shell with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set user to root for installation
USER root

# Install necessary packages
# hadolint ignore=DL3015
RUN apt-get update && \
    apt-get install -y \
    tzdata=2025a-2ubuntu1 \
    curl=8.12.0+git20250209.89ed161+ds-1ubuntu1 \
    bash=5.2.37-1ubuntu1 \
    apt-utils=2.9.29 \
    gettext=0.23.1-1 \
    gnupg=2.4.4-2ubuntu22 \
    ca-certificates=20241223 \
    lsb-release=12.1-1 \
    jq=1.7.1-3build1 \
    zip=3.0-14ubuntu2 \
    unzip=6.0-28ubuntu6 \
    nano=8.3-1 \
    vim=2:9.1.0861-1ubuntu1 \
    python3.12=3.12.9-1 \
    python3-pip=25.0+dfsg-1 \
    supervisor=4.2.5-3 && \
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
    curl -sL https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_${ARCH}.tar.gz | tar xz && \
    mv yq_linux_${ARCH} /usr/bin/yq && \
    rm -rf /tmp/*

# Install Google Cloud SDK (architecture-aware)
ENV CLOUDSDK_CONFIG=/usr/local/configs/gcloud
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    curl -sSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-510.0.0-linux-x86_64.tar.gz" -o google-cloud-sdk.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
    curl -sSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-510.0.0-linux-arm.tar.gz" -o google-cloud-sdk.tar.gz; \
    fi && \
    tar -xzf google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh -q && \
    rm -rf google-cloud-sdk.tar.gz /tmp/* /var/tmp/*

# Add Google Cloud SDK to PATH
ENV PATH=$PATH:/google-cloud-sdk/bin

# Install AWS CLI (architecture-aware)
ENV AWS_CONFIG_FILE=/usr/local/configs/aws
RUN ARCH=$(uname -m) && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws /tmp/* /var/tmp/*

# Install Azure CLI with manual GPG key retrieval as root
ENV GNUPGHOME=/root/.gnupg
ENV AZURE_CONFIG_DIR=/usr/local/configs/azure
RUN mkdir -p $GNUPGHOME && \
    chmod 700 $GNUPGHOME && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys EB3E94ADBE1229CF && \
    gpg --export EB3E94ADBE1229CF | tee /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ jammy main" | tee /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends azure-cli=2.69.0-1~jammy && \
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
RUN mkdir -p /var/log/supervisor /var/run/supervisor && \
    chown -R ${USER}:${USER} /var/log/supervisor /var/run/supervisor

# Create directory structure
RUN mkdir -p \
    # Worker directories
    ${WORKER_CONFIG_DIR} \
    ${WORKER_APP_DIR} \
    ${WORKER_DATA_DIR} \
    ${WORKER_LIB_DIR} \
    ${WORKER_BIN_DIR} \
    ${WORKER_ETC_DIR} \
    # Environment and secrets files directory
    ${WORKER_CONFIG_DIR}/environment.d \
    # User and config directories
    ${HOME}/.config/worker \
    # Cloud SDK config directories
    ${CLOUDSDK_CONFIG} \
    ${AWS_CONFIG_FILE%/*} \
    ${AZURE_CONFIG_DIR} && \
    # Create and set permissions for environment files
    touch ${WORKER_CONFIG_DIR}/environment ${WORKER_CONFIG_DIR}/secrets && \
    chown ${USER}:${USER} \
        ${WORKER_CONFIG_DIR}/environment \
        ${WORKER_CONFIG_DIR}/secrets && \
    chmod 644 ${WORKER_CONFIG_DIR}/environment && \
    chmod 600 ${WORKER_CONFIG_DIR}/secrets

# Copy worker files
COPY bin/entrypoint.sh ${WORKER_BIN_DIR}/
COPY lib ${WORKER_LIB_DIR}/
COPY etc/configs/worker/default.yaml ${WORKER_CONFIG_DIR}/worker.yaml
COPY etc/configs/supervisor ${WORKER_CONFIG_DIR}/supervisor/

# Make scripts executable and initialize environment
RUN chmod +x ${WORKER_LIB_DIR}/*.sh && \
    ${WORKER_LIB_DIR}/env_handler.sh init_environment

# Set up CLI tool and create symlink
COPY lib/cli.sh ${WORKER_BIN_DIR}/worker_mgmt
RUN chmod 755 ${WORKER_BIN_DIR}/worker_mgmt && \
    ln -sf ${WORKER_BIN_DIR}/worker_mgmt ${WORKER_BIN_DIR}/worker

# Set permissions
RUN \
    # Set base ownership
    chown -R ${UID}:${GID} \
        ${WORKER_BASE_DIR} \
        ${WORKER_CONFIG_DIR} \
        ${WORKER_LIB_DIR} \
        ${WORKER_BIN_DIR} \
        ${HOME} \
        ${CLOUDSDK_CONFIG} \
        ${AWS_CONFIG_FILE%/*} \
        ${AZURE_CONFIG_DIR} && \
    # Set directory permissions
    find ${WORKER_BASE_DIR} ${WORKER_CONFIG_DIR} ${WORKER_LIB_DIR} ${WORKER_BIN_DIR} -type d -exec chmod 755 {} + && \
    # Set base file permissions
    find ${WORKER_CONFIG_DIR} -type f -exec chmod 644 {} + && \
    find ${WORKER_LIB_DIR} -type f ! -name process_manager.sh -exec chmod 644 {} + && \
    # Make specific files executable
    chmod 755 \
        ${WORKER_BIN_DIR}/entrypoint.sh \
        ${WORKER_BIN_DIR}/worker_mgmt \
        ${WORKER_LIB_DIR}/process_manager.sh && \
    # Set runtime directories permissions
    chmod 775 ${WORKER_APP_DIR} ${WORKER_DATA_DIR} && \
    # Set sensitive file permissions
    chmod 600 ${WORKER_CONFIG_DIR}/secrets && \
    # Set home directory executable
    chmod 755 ${HOME}

# Set up supervisor configuration
RUN ln -sf ${WORKER_CONFIG_DIR}/supervisor/supervisord.conf /etc/supervisord.conf

# Switch to the user directory
WORKDIR ${HOME}

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the entrypoint script using shell form
ENTRYPOINT ["/usr/local/worker/bin/entrypoint.sh"]

# Set the default command
CMD ["tail", "-f", "/dev/null"]