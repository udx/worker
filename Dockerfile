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

# Install necessary packages and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    tzdata=2024a-3ubuntu1.1 \
    curl=8.5.0-2ubuntu10.4 \
    bash=5.2.21-2ubuntu4 \
    apt-utils=2.7.14build2 \
    gettext=0.21-14ubuntu2 \
    gnupg=2.4.4-2ubuntu17 \
    ca-certificates=20240203 \
    lsb-release=12.0-2 \
    jq=1.7.1-3build1 \
    zip=3.0-13build1 \
    unzip=6.0-28ubuntu4 \
    vim=2:9.1.0016-1ubuntu7.3 && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install yq (architecture-aware)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"; elif [ "$ARCH" = "aarch64" ]; then ARCH="arm64"; fi && \
    curl -sL https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_${ARCH}.tar.gz | tar xz && \
    mv yq_linux_${ARCH} /usr/bin/yq && \
    rm -rf /tmp/*

# Install Google Cloud SDK
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    apt-transport-https=2.7.14build2 && \
    curl -sSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-cloud-sdk=467.0.0-0 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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
    apt-get install -y --no-install-recommends azure-cli=2.63.0-1~noble && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Bitwarden CLI
RUN curl -Lso /usr/local/bin/bw "https://vault.bitwarden.com/download/?app=cli&platform=linux" && \
    chmod +x /usr/local/bin/bw && \
    rm -rf /tmp/* /var/tmp/*

# Create a new user and group with specific UID and GID, and set permissions
RUN groupadd -g ${GID} ${USER} && \
    useradd -l -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

# Switch to the user directory
WORKDIR /home/${USER}

# Create necessary directories and set permissions for GPG and other files
RUN mkdir -p /home/${USER}/.gnupg && \
    chmod 700 /home/${USER}/.gnupg && \
    mkdir -p /home/${USER}/etc /home/${USER}/.cd/configs && \
    chown -R ${USER}:${USER} /home/${USER}

# Copy the bin, etc, and lib directories
COPY ./etc/home /home/${USER}/etc
COPY ./src/configs /home/${USER}/.cd/configs
COPY ./lib /usr/local/lib
COPY ./bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./bin/test.sh /usr/local/bin/test.sh

# Set executable permissions and ownership for scripts
RUN chmod +x /usr/local/lib/* /usr/local/bin/entrypoint.sh /usr/local/bin/test.sh && \
    chown -R ${USER}:${USER} /usr/local/lib /home/${USER}/etc /home/${USER}/.cd/configs

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the entrypoint script using shell form
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Set the default command to execute bin/test.sh
CMD ["/usr/local/bin/test.sh"]
