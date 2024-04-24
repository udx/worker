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
//
// Example usage:
//
// $ udx-worker --version
// $ udx-worker -v
// $ udx-worker --help
// $ udx-worker -h
//
program
  .version("0.0.1")
  .description("A CLI tool for managing UDX Worker tasks.")
  // Add options for mode and force
  .option("-m, --mode <mode>", "set the mode (plan or apply)", "plan")
  .option("-i, --interactive", "enable interactive mode", false)
  .option("-f, --force", "force file creation", false)
  // Add help command
  .on("--help", () => {
    console.log("");
    console.log("Examples:");
    console.log("  $ udx-worker --version");
    console.log("  $ udx-worker -v");
    console.log("  $ udx-worker --help");
    console.log("  $ udx-worker -h");
    console.log("");
  });

// Define the setup command
//
// Modes:
// - plan: Plan the setup without applying changes
// - apply: Apply the changes
//
// Flags:
// - -f, --force: Force file creation
//
// Example usage:
// $ cli setup
// $ cli setup -m plan
// $ cli setup -m apply
// $ cli setup -f
// $ cli setup -m plan -f
program
  .command("setup")
  .description("Setup Ephemeral Workstation [interactive mode supported]")
  .action(async () => {
    // Start the application
    console.log(chalk.green("Starting the application..."));

    // Handle the setup and get the container name
    const container_name = await init(program.mode, program.force);

    // Log the completion of the setup
    console.log(chalk.green("Ephemeral Workstation setup completed."));

    // Check and start the containers
    await checkAndStartContainers(container_name);

    // Log the completion of the container check
    console.log(chalk.green("Container check completed."));
  });

// Define the execute command
//
// Example usage:
// $ udx-worker execute "ls -l"
// $ udx-worker execute "pwd"
// $ udx-worker execute "bash -c 'echo Hello, World!'"
// $ udx-worker execute nodejs /home/${USER}/bin/sync-history.js
//
program
  .command("execute <cmd>")
  .description("Execute Docker command")
  .action(async (cmd) => {
    // Log the execution of the Docker command
    console.log(chalk.green("Executing Docker command..."));

    // Execute the Docker command
    await executeDockerCommand("udx-worker", cmd);
  });

// Define the cleanup command
program
  .command("cleanup")
  .description("Execute cleanup script")
  .action(() => {
    // Log the execution of the cleanup script
    console.log(chalk.green("Executing cleanup script..."));

    // Execute the cleanup script
    execSync("cli/bin/cleanup.sh", { stdio: "inherit" });
  });

// Define the restart command
program
  .command("restart")
  .description("Restart the container")
  .action(() => {
    // Log the restart of the container
    console.log(chalk.green("Executing restart script..."));

    // Execute the restart command
    execSync("./cli/bin/restart.sh", { stdio: "inherit" });
  });

// Parse the command line arguments
program.parse(process.argv);
