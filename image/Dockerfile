# A new image based on the latest Ubuntu image
FROM ubuntu:latest

# Set the maintainer of the image
LABEL maintainer="UDX CAG Team"

# Define arguments
ARG USER=udx-worker

# Define runtime versions
ARG NODE_VERSION=20.x
ARG PYTHON_VERSION=3.12.2

# Copy user as an environment variable from arg
ENV USER=${USER}

# Set the environment variable to run Python unbuffered
ENV PYTHONUNBUFFERED=1

# Install necessary packages as root
RUN apt-get update && \
    apt-get install -y curl bash gnupg wget build-essential libssl-dev zlib1g-dev libbz2-dev \
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

# Switch back to the root user to install pyenv, Python, and pip
USER root

# Set the home directory for the non-root user
ENV HOME /home/${USER}

# Set the environment variables for pyenv
ENV PYENV_ROOT $HOME/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH

# Install pyenv, Python, and pip as root user
RUN curl https://pyenv.run | bash && \
    export PATH="/root/.pyenv/bin:$PATH" && \
    eval "$(pyenv init -)" && \
    eval "$(pyenv virtualenv-init -)" && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py && \
    pip install pyyaml pyOpenSSL colorama

# Switch back to the non-root user
USER ${USER}

# Copy the bin, etc directories to the image
COPY --chown=${USER}:${USER} ./bin              /home/${USER}/bin-modules
COPY --chown=${USER}:${USER} ./etc/home         /home/${USER}/etc
COPY --chown=${USER}:${USER} ./etc/configs      /home/${USER}/worker-configs

# Create a new directory for user
WORKDIR /home/${USER}

# Set the entrypoint to run bin/entrypoint.py
ENTRYPOINT python3 /home/${USER}/bin-modules/entrypoint.py