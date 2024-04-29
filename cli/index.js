#!/usr/bin/env node

// Import necessary modules
import { Command } from "commander";
import chalk from "chalk";
import { execSync } from "child_process";
import { init } from "./lib/interface.js";
import { checkAndStartContainers, executeDockerCommand } from "./lib/docker.js";

// Create a new command line application
const program = new Command();

// Set the version and description of the application
program
  .version("0.0.1")
  .description(
    "UDX Worker CLI: A tool for managing UDX Worker tasks such as setting up, executing commands, building, restarting, and cleaning up."
  )
  .on("--help", () => {
    console.log("");
    console.log("Examples:");
    console.log("  $ udx-worker --version");
    console.log("  $ udx-worker -v");
    console.log("  $ udx-worker --help");
    console.log("  $ udx-worker -h");
    console.log("");
    console.log("Setup Ephemeral Workstation:");
    console.log("  $ udx-worker setup");
    console.log("  $ udx-worker setup --mode apply");
    console.log("  $ udx-worker setup --force");
    console.log("");
    console.log("Execute a Docker command:");
    console.log("  $ udx-worker execute <cmd>");
    console.log("");
    console.log("Build the worker image:");
    console.log("  $ udx-worker build");
    console.log("");
    console.log("Restart the application:");
    console.log("  $ udx-worker restart");
    console.log("  $ udx-worker restart --force");
    console.log("");
    console.log("Cleanup:");
    console.log("  $ udx-worker cleanup");
    console.log("  $ udx-worker cleanup --force");
    console.log("");
  });

// Define the setup command
program
  .command("setup")
  .description(
    "Setup Ephemeral Workstation. This command initializes the workstation and checks the status of the containers. Interactive mode is supported."
  )
  .option(
    "-m, --mode <mode>",
    "Set the mode. Options are 'plan' or 'apply'. Default is 'plan'.",
    "plan"
  )
  .option(
    "-f, --force",
    "Force file creation. If set, existing files will be overwritten.",
    false
  )
  .action(async (cmd) => {
    console.log(chalk.green("Starting the application..."));
    const container_name = await init(cmd.mode, cmd.force);
    console.log(chalk.green("Ephemeral Workstation setup completed."));
    await checkAndStartContainers(container_name);
    console.log(chalk.green("Container check completed."));
  });

// Define the execute command
program
  .command("execute <cmd>")
  .description("Execute a Docker command on the 'udx-worker' container.")
  .action(async (cmd) => {
    console.log(chalk.green("Executing Docker command..."));
    await executeDockerCommand("udx-worker", cmd);
  });

// Define the build command
program
  .command("build")
  .description("Build the worker image using the Docker Compose build command.")
  .action(() => {
    console.log(chalk.green("Executing build script..."));
    const buildCommand = `docker-compose build`;
    execSync(buildCommand, { stdio: "inherit" });
  });

// Define the restart command
program
  .command("restart")
  .description("Restart the application. This command runs a restart script.")
  .option(
    "-f, --force",
    "Force restart. If set, the application will be restarted even if it's currently running.",
    false
  )
  .action((cmd) => {
    console.log(chalk.green("Executing restart script..."));
    const restartCommand = `sh ./cli/bin/restart.sh ${cmd.force ? "-f" : ""}`;
    execSync(restartCommand, { stdio: "inherit" });
  });

// Define the cleanup command
program
  .command("cleanup")
  .description(
    "Execute a cleanup script. This command removes temporary files and resets the application to its initial state."
  )
  .option(
    "-f, --force",
    "Force cleanup. If set, the cleanup script will be run regardless of the current state of the application.",
    false
  )
  .action((cmd) => {
    console.log(chalk.green("Executing cleanup script..."));
    const cleanupCommand = `sh ./cli/bin/cleanup.sh ${cmd.force ? "-f" : ""}`;
    execSync(cleanupCommand, { stdio: "inherit" });
  });

// Parse the command line arguments
program.parse(process.argv);
