import { exec } from "child_process";
import { promisify } from "util";
import chalk from "chalk";

// Promisify the exec function from child_process
const execSync = promisify(exec);

//
// Define a function to check if a container is running
//
// @param {string} container_name - The name of the container
// @returns {boolean} - A boolean value indicating if the container is running
//
// Example usage:
// const isRunning = await isContainerRunning("udx-worker");
// console.log(isRunning);
//
async function isContainerRunning(container_name) {
  const { stdout } = await execSync("docker-compose ps");
  return stdout.includes(container_name);
}

//
// Define a function to start a container
//
// @param {string} container_name - The name of the container
//
// Example usage:
// await startContainer("udx-worker");
//
async function startContainer(container_name) {
  execSync("docker-compose up -d");
  console.log(chalk.green(`Container ${container_name} started.`));
}

//
// Define a function to check and start containers
//
// @param {string} container_name - The name of the container
//
// Example usage:
// await checkAndStartContainers("udx-worker");
//
export async function checkAndStartContainers(container_name) {
  try {
    if (!(await isContainerRunning(container_name))) {
      console.log(
        chalk.yellow(
          `Container ${container_name} is not running. Starting it...`
        )
      );
      await startContainer(container_name);
    } else {
      console.log(
        chalk.green(`Container ${container_name} is already running.`)
      );
    }
  } catch (error) {
    console.error(chalk.red(`Error: ${error.message}`));
    console.error(error);
  }
}

//
// Define a function to prepare the Docker command
//
// @param {string} container_name - The name of the container
// @param {string} cmd - The command to be executed
//
// Example usage:
//
// prepareDockerCommand("udx-worker");
//
function prepareDockerCommand(container_name, cmd) {
  if (!cmd || cmd.length === 0) {
    console.log(chalk.yellow("No command provided."));
    return;
  }

  console.log(
    chalk.blue(`Preparing Docker command for container ${container_name}`)
  );

  const cmdString = cmd.join(" ");
  const isInteractive = cmd[0] === "bash" || cmd[0] === "sh";

  console.log(chalk.blue(`Executing following shell command: ${cmdString}`));

  if (isInteractive) {
    console.log(chalk.blue("Interactive mode enabled."));
  }

  const command = `docker-compose up -d ${container_name} && docker exec ${
    isInteractive ? "-it" : ""
  } ${container_name} ${cmdString}`;

  console.log(chalk.blue(`Docker command: ${command}`));

  return command;
}

//
// Define a function to execute a Docker command
//
// @param {string} container_name - The name of the container
// @param {string[]} cmd - The command to be executed
//
// Example usage:
// await executeDockerCommand("udx-worker", ["bash"]);
//
export async function executeDockerCommand(container_name, cmd) {
  try {
    console.log(
      chalk.green(`Executing Docker command for container ${container_name}`)
    );

    const dockerCommand = prepareDockerCommand(container_name, cmd);
    const { stdout: output } = await execSync(dockerCommand);
    console.log(chalk.green(`Output: ${output}`));
  } catch (error) {
    console.error(chalk.red(`Error: ${error.message}`));
  }
}

//
// Define a function to build a Docker image
//
// Example usage:
//
export async function buildWorkerImage() {
  try {
    console.log(chalk.green("Building Docker image..."));
    await execSync("docker-compose build");
    console.log(chalk.green("Docker image built successfully."));
  } catch (error) {
    console.error(chalk.red(`Error: ${error.message}`));
  }
}
