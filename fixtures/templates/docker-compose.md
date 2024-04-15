#{SERVICE_NAME}:
  container_name: #{SERVICE_NAME}
  build:
    context: .
    dockerfile: Dockerfile
    args:
      - USER=#{USER}
  environment:
    ENV_TYPE: #{SERVICE_NAME}
  volumes:
    - #{APP_PATH}:/home/app
  tty: true
  stdin_open: true
