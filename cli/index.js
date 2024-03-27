import { exec } from "child_process";
import fs from "fs";
import program from "commander";

program
  .version("1.0.0")
  .description("CLI")
  .option("-t, --type <type>", "Type of the Docker service")
  .arguments("<cmd> [args...]")
  .action((cmd, args, options) => {
    const { type } = options;

    // Map type to Docker service name
    let container;
    switch (type) {
      case "service":
        container = "udx-worker-service";
        break;
      case "task":
        container = "udx-worker-task";
        break;
      default:
        console.error(`Error: Unknown type "${type}".`);
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

    let dockerCommand = `docker exec ${container} ${cmd} ${args.join(" ")}`;

    // If the command is a shell, run it interactively
    if (cmd === "bash" || cmd === "sh") {
      dockerCommand = `docker exec -it ${container} ${cmd} ${args.join(" ")}`;
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
  });

program.parse(process.argv);
