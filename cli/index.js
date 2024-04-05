import { exec } from "child_process";
import fs from "fs";
import nopt from "nopt";

// Define options
const options = {
  "type": [String, null],
  "cmd": [String, Array],
};

// Parse command line arguments
const parsed = nopt(options, {}, process.argv, 2);

// Map type to Docker service name
let container;
switch (parsed.type) {
  case "service":
    container = "udx-worker-service";
    break;
  case "task":
    container = "udx-worker-task";
    break;
  default:
    console.error(`Error: Unknown type "${parsed.type}".`);
    return;
}

// Check if docker-compose.yml exists
if (!fs.existsSync("./docker-compose.yml")) {
  console.error("Error: docker-compose.yml does not exist.");
  return;
}

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