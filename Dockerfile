# Dockerfile
FROM ubuntu:latest

ARG USER

# Install curl and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and npm
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs

# Create a new user
RUN useradd -m ${USER}

# Switch to the non-root user after all commands that require root permissions have been executed
USER ${USER}

# Create a new directory for your application
WORKDIR /home/app

# Copy package.json and package-lock.json
COPY /src/app/package*.json ./

# Install application dependencies
RUN npm install

# Copy the rest of the application
COPY --chown=${USER}:${USER} /src/app .

# Copy the CLI script and make it executable
COPY --chown=${USER}:${USER} bin/cli.sh /usr/local/bin/cli

# Make the CLI script executable
RUN chmod +x /usr/local/bin/cli

# Change the ownership of the app directory to the new user
# RUN chown -R ${USER}:${USER} /home/${USER}/app

# Set the entrypoint to the CLI script
ENTRYPOINT ["/bin/sh", "-c", "/usr/local/bin/cli"]
