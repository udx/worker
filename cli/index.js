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
  .description("A CLI tool for managing UDX Worker tasks.")
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
program
  .command("setup")
  .description("Setup Ephemeral Workstation [interactive mode supported]")
  .option("-m, --mode <mode>", "set the mode (plan or apply)", "plan")
  .option("-f, --force", "force file creation", false)
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
  .description("Execute Docker command")
  .action(async (cmd) => {
    console.log(chalk.green("Executing Docker command..."));
    await executeDockerCommand("udx-worker", cmd);
  });

// Define the cleanup command
program
  .command("cleanup")
  .description("Execute cleanup script")
  .option("-f, --force", "force cleanup", false)
  .action((cmd) => {
    console.log(chalk.green("Executing cleanup script..."));
    const cleanupCommand = `sh ./cli/bin/cleanup.sh ${cmd.force ? "-f" : ""}`;
    execSync(cleanupCommand, { stdio: "inherit" });
  });

// Parse the command line arguments
program.parse(process.argv);
