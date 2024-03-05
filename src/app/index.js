import chalk from "chalk";
import yargs from "yargs";
import { hideBin } from "yargs/helpers";
import yaml from "js-yaml";
import fs from "fs";
import { fileURLToPath } from "url";
import path from "path";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const modulesDir = "modules";
const moduleNames = fs.readdirSync(modulesDir);

const functions = {};

for (const moduleName of moduleNames) {
  const modulePath = path.resolve(__dirname, modulesDir, moduleName, "main.js");
  if (fs.existsSync(modulePath)) {
    const module = await import(modulePath);
    functions[moduleName] = module.default;
    const command = yaml.load(
      fs.readFileSync(path.join(modulesDir, moduleName, "config.yml"), "utf8")
    );

    console.log(chalk.green(`Command initialized: ${command.command}`));

    yargs(hideBin(process.argv)).command(
      `${command.command} <action> ${Object.keys(command.actions)
        .map((action) => `<${action}>`)
        .join(" ")}`,
      command.description,
      (yargs) => {
        for (const action of command.actions) {
          const actionName = Object.keys(action)[0];
          const params = action[actionName].params;
          for (const param of params) {
            const paramName = Object.keys(param)[0];
            yargs.positional(paramName, {
              describe: `The ${paramName} argument`,
              type: "string",
              demandOption: param[paramName].isrequired,
            });
          }
        }
      },
      async (argv) => {
        const { action } = argv;
        await functions[command.module][action](argv);
      }
    );
  } else {
    console.log(chalk.red(`Module file not found: ${modulePath}`));
  }
}

console.log(chalk.green("CLI initialized"));

runModuleAction(yargs(hideBin(process.argv)).argv);

async function runModuleAction(argv) {

  console.log(argv);

  const {
    _: [moduleName, action],
    ...params
  } = argv;

  if (!moduleName || !action) {
    console.log(chalk.yellow("Module and action are required."));
    return;
  }

  if (!functions[moduleName]) {
    console.log(chalk.red(`Module not found: ${moduleName}`));
    return;
  }

  const module = functions[moduleName];

  if (!module[action]) {
    console.log(chalk.red(`Action not found: ${action}`));
    return;
  }

  await module[action](params);
}
