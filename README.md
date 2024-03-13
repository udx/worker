# UDX Worker CLI
---

UDX Worker CLI is a powerful npm package tool that provides a consistent interface for running any type of software or cloud applications. 

It leverages Docker technology to encapsulate applications into isolated environments, ensuring consistent behavior across different platforms and systems.

Whether you're deploying a complex cloud application or running routine tasks, UDX Worker CLI provides the tools you need to get the job done efficiently and effectively.
<br />

## Docker Image and NPM Package

The UDX Worker CLI is designed to be flexible and can be used in two different ways: as a standalone Docker image, or as an npm package.

### Docker Image

The Docker image provides a consistent environment for running your applications. This is particularly useful when you need to ensure that your application behaves the same way across different systems and platforms. The Docker image encapsulates everything your application needs to run, including the operating system, system libraries, and application code.

You can use the Docker image to run your applications in any environment that supports Docker, including development, staging, and production environments. This ensures that your application will behave the same way, regardless of where it's run.

#### Container File Structure

- `/home/app`: This directory contains the application code.
- `/home/bin`: This directory contains executable scripts, such as the entrypoint script.
- `/home/etc`: This directory contains configuration files, such as the `ecosystem.config.js` file.
- `/home/fixtures`: This directory contains any fixtures for the application.

### NPM Package

The npm package is designed for local development. It can be installed globally on local machine and used it to run and test cloud applications or scripts, generate configuration manifests, etc. The npm package acts as a wrapper to the Docker CLI, providing a simplified, user-friendly interface for running Docker commands.

By using the npm package, you can take advantage of the consistency provided by Docker, while also enjoying the convenience of a simple command-line interface. This makes it easy to develop and test your applications locally, before deploying them to a production environment.



