import { Command } from "commander";
import chalk from "chalk";
import { execSync } from "child_process";
import { init } from "./lib/interface.js";
import { checkAndStartContainers, executeDockerCommand } from "./lib/docker.js";
import fs from "fs";
import path, { dirname } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Read and parse the package.json file
const filePath = path.join(__dirname, "package.json");
const pkg = JSON.parse(fs.readFileSync(filePath, "utf-8"));

const { commands } = pkg.config;

const program = new Command();

program
  .version(pkg.version)
  .description(
    "UDX Worker CLI: A tool for managing UDX Worker tasks such as setting up, executing commands, building, restarting, and cleaning up."
  )
  .on("--help", () => {
    console.log("");
    console.log("Examples:");
    commands.forEach((command) => {
      if (command.enabled) {
        console.log(`  $ udx-worker ${command.name}`);
      }
    });
    console.log("");
  });

commands.forEach((command) => {
  if (command.enabled) {
    const cmd = program.command(command.name).description(command.description);

    command.options?.forEach((option) => {
      cmd.option(option.flags, option.description, option.defaultValue);
    });

    cmd.action(async (options) => {
      // You can use a switch statement or a map of functions to call the correct function based on the action name
      switch (command.action) {
        case "init":
          console.log(chalk.green("Starting the application..."));
          const container_name = await init(options.mode, options.force);
          console.log(chalk.green("Ephemeral Workstation setup completed."));
          await checkAndStartContainers(container_name);
          console.log(chalk.green("Container check completed."));
          break;
        case "executeDockerCommand":
          console.log(chalk.green("Executing Docker command..."));
          await executeDockerCommand("udx-worker", options.command);
          break;
        case "build":
          console.log(chalk.green("Executing build script..."));
          const buildCommand = `docker-compose build`;
          execSync(buildCommand, { stdio: "inherit" });
          break;
        case "restart":
          console.log(chalk.green("Executing restart script..."));
          const restartCommand = `sh ./bin/restart.sh ${cmd.force ? "-f" : ""}`;
          execSync(restartCommand, { stdio: "inherit" });
          break;
        case "cleanup":
          console.log(chalk.green("Executing cleanup script..."));
          const cleanupCommand = `sh ./bin/cleanup.sh ${cmd.force ? "-f" : ""}`;
          execSync(cleanupCommand, { stdio: "inherit" });
          break;
      }
    });
  }
});

program.parse(process.argv);
