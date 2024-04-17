import { exec as execCb } from "child_process";
import { promisify } from "util";

const exec = promisify(execCb);

export async function checkAndStartContainers(container_name) {
  try {
    const { stdout } = await exec("docker-compose ps");

    if (!stdout.includes(container_name)) {
      console.log(`Container ${container_name} is not running. Starting it...`);
      await exec("docker-compose up -d");
    } else {
      console.log(`Container ${container_name} is already running.`);
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
  }
}

export async function executeDockerCommand(container_name, cmd) {
  if (!cmd) {
    console.log("No command provided.");
    return;
  }

  let dockerCommand = `docker exec ${container_name} ${cmd}`;

  console.log(`Executing following shell command: ${cmd}`);

  // If the command is a shell, run it interactively
  if (cmd[0] === "bash" || cmd[0] === "sh") {
    console.log("Interactive mode enabled.");
    dockerCommand = `docker exec -it ${container_name} ${cmd}`;
  }

  try {
    const { stdout: output } = await exec(dockerCommand);
    console.log(`Output: ${output}`);
  } catch (error) {
    console.error(`Error: ${error.message}`);
  }
}
