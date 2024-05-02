#
# UDX Worker Docker Image
# This Dockerfile is used to build a Docker image for a UDX Worker.
#
# The image is based on the official Ubuntu image 
# Includes Ubuntu, essential libraries, Node.js, NPM, Python (installed via pyenv), and some global NPM and Python packages.
# 
# ARGs: 
# - USER: The user to be created in the image (Default: udx-worker).
# - NODE_VERSION: The version of Node.js to be installed in the image (Default: 20.x)
# - PYTHON_VERSION: The version of Python to be installed in the image (Default: 3.12.2)
# 
# ENVs:
# - USER: The user to be created in the image (Default: udx-worker inherited from USER arg).
# - PYTHONUNBUFFERED: Set to 1 to run Python unbuffered
# - HOME: Set to the home directory of the created user
# - PYENV_ROOT: Set to the pyenv installation directory
# - PATH: Updated to include the pyenv shims and bin directories
# 
# The Dockerfile also creates a new user, installs necessary packages as root, switches to the non-root user after all commands that require root permissions have been executed, sets the home directory for the non-root user, installs pyenv and Python as non-root user, copies the bin, etc directories to the image, creates a new directory for user, and sets the entrypoint to run bin/entrypoint.sh.
#

# Create a new image based on the latest Ubuntu image
FROM ubuntu:latest

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define arguments
ARG USER=udx-worker

# Set NodeJS version to 20.x by default
ARG NODE_VERSION=20.x

# Set Python version to 3.12.2 by default
ARG PYTHON_VERSION=3.12.2

# Copy user as an environment variable from arg
ENV USER=${USER}

# Set the environment variable to run Python unbuffered
ENV PYTHONUNBUFFERED=1

# Install necessary packages as root
RUN apt-get update && \
    apt-get install -y curl gnupg wget build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev git && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install npm packages globally
RUN npm install -g grunt-cli pm2 mocha should gulp-cli should-type axios

# Create a new user
RUN useradd -m ${USER}

# Create a new directory for the user and change ownership
RUN mkdir -p /home/${USER} && chown -R ${USER}:${USER} /home/${USER}

# Switch to the non-root user after all commands that require root permissions have been executed
USER ${USER}

# Set the home directory for the non-root user
ENV HOME /home/${USER}

# Set the environment variables for pyenv
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# Install pyenv and Python as non-root user
RUN curl https://pyenv.run | bash && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    pip install pyyaml pyOpenSSL

# Copy the bin, etc directories to the image
COPY --chown=${USER}:${USER} ./bin              /home/${USER}/bin-modules
COPY --chown=${USER}:${USER} ./etc/home         /home/${USER}/etc
COPY --chown=${USER}:${USER} ./etc/configs      /home/${USER}/worker-configs

# Create a new directory for user
WORKDIR /home/${USER}

# Set the entrypoint to run bin/entrypoint.sh
ENTRYPOINT ["sh", "-c", "/home/${USER}/bin-modules/entrypoint.sh"]