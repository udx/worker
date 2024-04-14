import { exec } from "child_process";
import fs from "fs";
import nopt from "nopt";

// Define options
const options = {
  type: [String, null],
  cmd: [String, Array],
  service_name: [String, null],
  user: [String, null],
  app_path: [String, null],
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
// Check if docker-compose.md exists in the templates directory
if (!fs.existsSync("./fixtures/templates/docker-compose.md")) {
  console.error("Error: docker-compose.md template does not exist.");
  return;
}

if (fs.existsSync("./docker-compose.yml")) {
  console.log("docker-compose.yml already exists.");
} else {
  // Read the contents of the template file
  let template = fs.readFileSync(
    "./fixtures/templates/docker-compose.md",
    "utf8"
  );

  // Define default values
  let defaults = {
    "#{SERVICE_NAME}": "udx-worker",
    "#{USER}": "udx-worker",
    "#{APP_PATH}": ".",
  };

  // Override default values with command line arguments, if provided
  if (parsed.service_name) defaults["#{SERVICE_NAME}"] = parsed.service_name;
  if (parsed.user) defaults["#{USER}"] = parsed.user;
  if (parsed.app_path) defaults["#{APP_PATH}"] = parsed.app_path;

  // Replace variables in the template with their default values
  for (const variable in defaults) {
    const value = defaults[variable];
    const regex = new RegExp(variable, "g");
    template = template.replace(regex, value);
  }

  // Use the template to create a new docker-compose.yml file
  fs.writeFileSync("./docker-compose.yml", template);
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
