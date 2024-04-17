version: "3"
services:
  #{CONTAINER_NAME}:
    container_name: #{CONTAINER_NAME}
    build:
      context: ./docker-image
      dockerfile: Dockerfile
      args:
        - USER=#{USER}
    volumes:
      #{VOLUMES}
    tty: true
    stdin_open: true
