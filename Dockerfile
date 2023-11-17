# Dockerfile
FROM docker:latest

WORKDIR /app

COPY bin/cli.sh /usr/local/bin/cli
RUN chmod +x /usr/local/bin/cli