// Import the necessary modules
import chalk from "chalk";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import yaml from "js-yaml";
import fs from "fs";
import { fileURLToPath } from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Define the functions for each command
const functions = {};

// Read the modules directory
const modulesDir = "modules";
const moduleNames = fs.readdirSync(modulesDir);

// Import the modules and load the commands
const commands = [];
for (const moduleName of moduleNames) {
  const modulePath = path.resolve(__dirname, modulesDir, moduleName, "main.js");
  if (fs.existsSync("modules/app/main.js")) {
    (async () => {
      const module = await import(modulePath);
      functions[moduleName] = module.default;
      const command = yaml.load(
        fs.readFileSync(path.join(modulesDir, moduleName, "config.yml"), "utf8")
      );

      console.log(chalk.green(`Command initialized: ${command.command}`));
      commands.push(command);
    })();
  } else {
    console.log(chalk.red(`Module file not found: ${modulePath}`));
  }
}

// Define the command
const yargsInstance = yargs(hideBin(process.argv));
for (const command of commands) {
  for (const action of Object.keys(command.actions)) {
    const fullCommand = `${command.command} ${action} ${command.actions[
      action
    ].params
      .map((param) => `<${Object.keys(param)[0]}>`)
      .join(" ")}`;
    yargsInstance.command(
      fullCommand,
      command.description,
      (yargs) => {
        for (const param of command.actions[action].params) {
          const paramName = Object.keys(param)[0];
          yargs.positional(paramName, {
            describe: `The ${paramName} argument`,
            type: "string",
            demandOption: param[paramName].isrequired,
          });
        }
      },
      async (argv) => {
        await functions[command.module][action](argv);
      }
    );
  }
}
yargsInstance.argv;
