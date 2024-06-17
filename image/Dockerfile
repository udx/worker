# Use the latest version of the Ubuntu image
FROM ubuntu:24.04

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define arguments
ARG USER=udx
ARG NODE_VERSION=20.x

# Set environment variables to avoid interactive prompts and set a fixed timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Set user environment variable directly
ENV USER=udx
ENV HOME=/home/${USER}

# Install necessary packages in a single RUN statement to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata curl bash gnupg wget && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get update && \
    apt-get install -y nodejs npm

# Verify Node.js and npm installation
RUN node -v && npm -v

# Install PM2 and Grunt
RUN npm install -g pm2 grunt-cli

# Create a new user
RUN useradd -m ${USER}

# Switch to the user directory
WORKDIR /home/${USER}

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

# Default command to display Node.js version
CMD ["sh", "-c", "echo NodeJS@$(node -v)"]
