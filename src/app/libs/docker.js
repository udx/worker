import { exec } from "child_process";

export function checkAndStartContainers(container) {
  // Check if Docker containers are running
  exec("docker-compose ps", (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${error.message}`);
      return;
    }

    if (stderr) {
      console.error(`Error: ${stderr}`);
      return;
    }

    // If Docker containers are not running, start them
    if (!stdout.includes(container)) {
      exec("docker-compose up -d", (error, stdout, stderr) => {
        if (error) {
          console.error(`Error: ${error.message}`);
          return;
        }

        if (stderr) {
          console.error(`Error: ${stderr}`);
          return;
        }

        console.log(`Output: ${stdout}`);
      });
    }
  });
}

export function executeDockerCommand(container, parsed) {
  let dockerCommand = `docker exec ${container} ${parsed.cmd.join(" ")}`;

  // If the command is a shell, run it interactively
  if (parsed.cmd[0] === "bash" || parsed.cmd[0] === "sh") {
    dockerCommand = `docker exec -it ${container} ${parsed.cmd.join(" ")}`;
  }

  exec(dockerCommand, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error: ${error.message}`);
      return;
    }

    if (stderr) {
      console.error(`Error: ${stderr}`);
      return;
    }

    console.log(`Output: ${stdout}`);
  });
}
