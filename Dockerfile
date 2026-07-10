# Use the latest version of the Ubuntu image with a specific tag for stability
FROM ubuntu:25.10

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

ARG AZURE_CLI_VERSION=2.88.0
ARG PIP_VERSION=26.1.2
ARG YQ_VERSION=4.53.3
ARG GCLOUD_VERSION=575.0.1

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
    # Config paths
    AWS_CONFIG_FILE=/usr/local/configs/aws \
    AZURE_CONFIG_DIR=/usr/local/configs/azure \
    CLOUDSDK_CONFIG=/usr/local/configs/gcloud \
    CLOUDSDK_CORE_DISABLE_FILE_LOGGING=true

# Set the shell with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set user to root for installation
USER root

# Install necessary packages
# hadolint ignore=DL3015
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tzdata=2026b-0ubuntu0.25.10.1  \
    curl=8.14.1-2ubuntu1.5  \
    bash=5.2.37-2ubuntu5  \
    apt-utils=3.1.6ubuntu2 \
    gettext=0.23.1-2build2 \
    gnupg2=2.4.8-2ubuntu2.1 \
    ca-certificates=20260601~25.10.1 \
    lsb-release=12.1-1 \
    jq=1.8.1-3ubuntu1.1 \
    zip=3.0-15ubuntu2 \
    unzip=6.0-28ubuntu7 \
    nano=8.4-1ubuntu0.1 \
    vim=2:9.1.0967-1ubuntu6.8 \
    python3.13=3.13.7-1ubuntu0.4 \
    python3.13-venv=3.13.7-1ubuntu0.4 \
    supervisor=4.2.5-3 && \
    # Install Azure CLI in venv with optimizations for scanning
    python3.13 -m venv /opt/az && \
    /opt/az/bin/pip install --no-cache-dir --upgrade pip==${PIP_VERSION} && \
    /opt/az/bin/pip install --no-cache-dir azure-cli==${AZURE_CLI_VERSION} && \
    ln -s /opt/az/bin/az /usr/local/bin/az && \
    # Clean up pip cache and temp files
    rm -rf /root/.cache/pip && \
    (find /opt/az -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true) && \
    apt-get clean && \
    rm -rf /tmp/* /var/tmp/* && \
    # Set up sources.list.d for child images
    mkdir -p /etc/apt/sources.list.d && \
    chmod 755 /etc/apt/sources.list.d

# Configure the timezone
RUN echo $TZ > /etc/timezone && \
    rm -f /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

# Install yq (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${ARCH}.tar.gz" -o /tmp/yq.tar.gz && \
    tar -xzf /tmp/yq.tar.gz -C /tmp && \
    mv /tmp/yq_linux_${ARCH} /usr/bin/yq && \
    rm -rf /tmp/*

# Install Google Cloud SDK (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
    curl -sSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz" -o google-cloud-sdk.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
    curl -sSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-arm.tar.gz" -o google-cloud-sdk.tar.gz; \
    fi && \
    tar -xzf google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh -q && \
    rm -f \
        ./google-cloud-sdk/platform/gsutil/third_party/urllib3/dummyserver/certs/server.key \
        ./google-cloud-sdk/platform/gsutil/third_party/urllib3/dummyserver/certs/cacert.key && \
    rm -rf google-cloud-sdk.tar.gz /tmp/* /var/tmp/*

# Add Google Cloud SDK to PATH
ENV PATH=$PATH:/google-cloud-sdk/bin

# Install AWS CLI (architecture-aware)
RUN ARCH=$(uname -m) && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws /tmp/* /var/tmp/*

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
    # Environment files directory
    ${WORKER_CONFIG_DIR}/environment.d \
    # User and config directories
    ${HOME}/.config/worker \
    # Cloud SDK config directories
    ${CLOUDSDK_CONFIG} \
    ${CLOUDSDK_CONFIG}/credentials \
    ${CLOUDSDK_CONFIG}/logs \
    ${AWS_CONFIG_FILE%/*} \
    ${AZURE_CONFIG_DIR} && \
    # Create and set permissions for environment files
    touch ${WORKER_CONFIG_DIR}/environment && \
    chown ${USER}:${USER} ${WORKER_CONFIG_DIR}/environment && \
    chmod 600 ${WORKER_CONFIG_DIR}/environment

# Copy worker files
COPY bin/entrypoint.sh ${WORKER_BIN_DIR}/
COPY lib ${WORKER_LIB_DIR}/
COPY src/configs/worker.yaml ${WORKER_CONFIG_DIR}/worker.yaml
COPY src/configs/services.yaml ${WORKER_CONFIG_DIR}/services.yaml
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
        # Set cloud config directory permissions
        ${CLOUDSDK_CONFIG} \
        ${AWS_CONFIG_FILE%/*} \
        ${AZURE_CONFIG_DIR} \
        # Set az permissions
        /opt/az && \
    # Set Azure CLI permissions
    chmod -R 755 /opt/az/bin && \
    chmod -R 700 ${AZURE_CONFIG_DIR} && \
    # Set gcloud permissions
    chmod -R 700 ${CLOUDSDK_CONFIG}/credentials && \
    chmod -R 755 ${CLOUDSDK_CONFIG}/logs && \
    # Set directory permissions
    find ${WORKER_BASE_DIR} ${WORKER_CONFIG_DIR} ${WORKER_LIB_DIR} ${WORKER_BIN_DIR} -type d -exec chmod 755 {} + && \
    # Set base file permissions
    find ${WORKER_CONFIG_DIR} -type f -exec chmod 644 {} + && \
    chmod 600 ${WORKER_CONFIG_DIR}/environment && \
    find ${WORKER_LIB_DIR} -type f ! -name process_manager.sh -exec chmod 644 {} + && \
    # Make specific files executable
    chmod 755 \
        ${WORKER_BIN_DIR}/entrypoint.sh \
        ${WORKER_BIN_DIR}/worker_mgmt \
        ${WORKER_LIB_DIR}/process_manager.sh && \
    # Set runtime directories permissions
    chmod 775 ${WORKER_APP_DIR} ${WORKER_DATA_DIR} && \
    # Set home directory executable
    chmod 755 ${HOME}

# Set up supervisor configuration
RUN ln -sf ${WORKER_CONFIG_DIR}/supervisor/supervisord.conf /etc/supervisord.conf

# Copy .bashrc directly to user's home
COPY etc/home/.bashrc "/home/${USER}/.bashrc"

# Switch to the user directory
WORKDIR ${HOME}

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the entrypoint script using shell form
ENTRYPOINT ["/usr/local/worker/bin/entrypoint.sh"]

# Set the default command
CMD ["tail", "-f", "/dev/null"]
