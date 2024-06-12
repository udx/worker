# Use a specific version of a minimal base image
FROM ubuntu:20.04

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define arguments
ARG USER=udx-worker

# Set environment variables to avoid interactive prompts and set a fixed timezone
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Set user environment variable directly
ENV USER=udx-worker
ENV HOME=/home/${USER}

# Install necessary packages in a single RUN statement to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata curl bash gnupg wget && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a new user
RUN useradd -m ${USER}

# Switch to the user directory
WORKDIR /home/${USER}

# Copy the bin, etc directories to the image and set correct permissions
COPY ./bin /home/${USER}/bin-modules
COPY ./etc/home /home/${USER}/etc
COPY ./etc/configs /home/${USER}/worker-configs

# Set executable permissions for entrypoint.sh
RUN chmod +x /home/${USER}/bin-modules/entrypoint.sh && \
    chown -R ${USER}:${USER} /home/${USER}/bin-modules /home/${USER}/etc /home/${USER}/worker-configs

# Switch to non-root user
USER ${USER}

# Set the entrypoint to run the new entrypoint script
ENTRYPOINT ["/home/udx-worker/bin-modules/entrypoint.sh"]
