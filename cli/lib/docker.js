import { exec } from "child_process";
import { promisify } from "util";
import chalk from "chalk";
import _ from "lodash";

// Promisify the exec function from child_process
const execSync = promisify(exec);

async function isContainerRunning(container_name) {
  const { stdout } = await execSync("docker-compose ps");
  return _.includes(stdout, container_name);
}

async function startContainer(container_name) {
  execSync("docker-compose up -d");
  console.log(chalk.green(`Container ${container_name} started.`));
}

function prepareDockerCommand(container_name, cmd) {
  if (_.isEmpty(cmd)) {
    console.log(chalk.yellow("No command provided."));
    return;
  }

  console.log(
    chalk.blue(`Preparing Docker command for container ${container_name}`)
  );

  const cmdString = _.join(cmd, " ");
  const isInteractive = _.includes(["bash", "sh"], _.head(cmd));

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

export async function buildWorkerImage() {
  try {
    console.log(chalk.green("Building Docker image..."));
    await execSync("docker-compose build");
    console.log(chalk.green("Docker image built successfully."));
  } catch (error) {
    console.error(chalk.red(`Error: ${error.message}`));
  }
}