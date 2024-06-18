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

# Set user environment variable directly
ENV USER=udx
ENV HOME=/home/${USER}

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
    npm && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a new user and ensure home directory permissions are set correctly
RUN useradd -m ${USER}

# Switch to the user directory
WORKDIR /home/${USER}

# Install PM2 and Grunt CLI globally
RUN npm install -g pm2@5.3.0 grunt-cli@1.4.3

# Copy the bin, etc directories to the image and set correct permissions
COPY ./bin /home/${USER}/bin-modules
COPY ./etc/home /home/${USER}/etc
COPY ./etc/configs /home/${USER}/.cd/configs

# Set executable permissions for entrypoint.sh
RUN chmod +x /home/${USER}/bin-modules/entrypoint.sh && \
    chown -R ${USER}:${USER} /home/${USER}/bin-modules /home/${USER}/etc /home/${USER}/.cd/configs

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the new entrypoint script
ENTRYPOINT ["/home/udx/bin-modules/entrypoint.sh"]

# Default command to display NodeJS version in the desired format
CMD ["sh", "-c", "echo NodeJS@$(node -v)"]
