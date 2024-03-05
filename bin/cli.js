#!/usr/bin/env node

import chalk from "chalk";
import fs from "fs";
import path from "path";
import YAML from "yaml";
import { spawnSync } from "child_process";

// Get the command line arguments
const args = process.argv.slice(2);

if (args.length !== 0 && args.includes("--help")) {
  console.log("");
  console.log(chalk.blueBright("Welcome to the UDX Worker CLI"));
  console.log("---------------------------------");
  console.log("");
  console.log(chalk.blueBright("Available commands:"));
  console.log("---------------------------------");
  console.log("");

  const scanDirAndGetConfigs = async (dirPath) => {
    try {
      const files = await fs.promises.readdir(dirPath);

      for (const file of files) {
        const filePath = path.join(dirPath, file);
        const stats = await fs.promises.stat(filePath);

        if (stats.isDirectory()) {
          await scanDirAndGetConfigs(filePath);
        } else if (stats.isFile() && file === "config.yml") {
          try {
            const configPath = path.join(dirPath, "config.yml");
            const data = await fs.promises.readFile(configPath, "utf8");
            const config = YAML.parse(data);
            console.log(chalk.greenBright(`${config.command}:`));
            console.log("");

            const actions = config.actions;
            for (const action of Object.keys(actions)) {
              try {
                console.log(` - ${chalk.green(`${action}`)}`);
                console.log(
                  `   ${chalk.cyanBright(
                    `udx-worker ${config.command} ${action} ...`
                  )}`
                );
              } catch (error) {
                console.error(chalk.red(`Error: ${error.message}`));
              }
            }

            console.log("");
            console.log("");
          } catch (error) {
            console.error(chalk.red(`Error: ${error.message}`));
          }
        } else {
          // console.log(chalk.gray(`Skipping file: ${file}`));
        }
      }
    } catch (error) {
      console.error(chalk.red(`Error: ${error.message}`));
    }
  };

  const modulesDir = "./src/app/modules";
  const scanModulesAndExit = async () => {
    try {
      const modules = await fs.promises.readdir(modulesDir);

      for (const module of modules) {
        try {
          const modulePath = path.join(modulesDir, module);
          await scanDirAndGetConfigs(modulePath);
        } catch (error) {
          console.error(chalk.red(`Error: ${error.message}`));
        }
      }
    } catch (error) {
      console.error(chalk.red(`Error: ${error.message}`));
    }
  };

  // Move the code inside the else block here
  scanModulesAndExit();
} else {
  const checkContainerRunning = () => {
    const result = spawnSync("docker", ["ps", "--format", "{{.Names}}"]);
    const runningContainers = result.stdout.toString().split("\n");

    return runningContainers.includes("udx-worker");
  };

  if (!checkContainerRunning()) {
    console.log("The container is not running. Starting the container...");
    spawnSync("docker-compose", ["up", "-d"], { stdio: "inherit" });
  }

  const result = spawnSync(
    "docker-compose",
    ["exec", "udx-worker", "cli", ...args],
    { stdio: "inherit" }
  );

  if (result.error) {
    console.error(chalk.red(`Error: ${result.error.message}`));
  }

  console.log(
    chalk.green("\nUDX Worker is ready to work. What can I do for you? ")
  );
  console.log("---------------------------------");
  console.log(
    chalk.yellow(
      `\nUse --help for more information: ${chalk.bgBlue("udx-worker --help")})`
    )
  );
  console.log("...");
  console.log("...");
  console.log("");
}
