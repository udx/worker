#{CONTAINER_NAME}:
  container_name: #{CONTAINER_NAME}
  build:
    context: ./docker-image
    dockerfile: Dockerfile
    args:
      - USER=#{USER}
  volumes:
    - #{APP_PATH}:/home/app
  tty: true
  stdin_open: true
