import fs from "fs";
import path from "path";
import chalk from "chalk";
import yaml from "yaml";
import prompt from "prompt";

//
// Define the default compose path
//
async function getInputs(interactive, config) {
  let inputs = config.environment;

  if (!interactive) {
    console.log(
      chalk.yellow("Running in non-interactive mode. Using default values.")
    );
    return inputs;
  }

  const properties = Object.keys(config.environment).map((key) => {
    return {
      name: key,
      description: `Enter the ${key.replace("_", " ")}`,
      default: Array.isArray(config.environment[key])
        ? config.environment[key].join(",")
        : config.environment[key],
    };
  });

  prompt.start();

  inputs = await new Promise((resolve, reject) => {
    prompt.get(properties, function (err, result) {
      if (err) {
        reject(err);
      } else {
        resolve(result);
      }
    });
  });

  return inputs;
}

//
// Define a function to format docker-compose.template
//
// @param {object} inputs - The inputs to be passed to the template as variables
// @param {string} templatePath - The path to the template file
// @returns {string} - The formatted template
//
function formatTemplate(inputs, templatePath) {
  if (!fs.existsSync(templatePath)) {
    console.error(chalk.red(`Error: ${templatePath} template does not exist.`));
    return;
  }

  let template = fs.readFileSync(templatePath, "utf8");

  for (const variable in inputs) {
    let value;

    if (variable === "volumes") {
      value = inputs.volumes
        ? inputs.volumes
            .split(",")
            .map((volume) => `- ${volume.trim()}`)
            .join("\n")
        : "";
    } else {
      value = inputs[variable];
    }

    const regex = new RegExp(`#{${variable.toUpperCase()}}`, "g");
    template = template.replace(regex, value);
  }

  return template;
}

//
// Define an asynchronous function to initialize the setup
//
// @param {boolean} interactive - A boolean value to enable interactive mode
// @param {boolean} force - A boolean value to force file creation
// @param {string} composePath - The path to the docker-compose file
// @param {string} templatePath - The path to the template file
// @returns {Promise<string>} - The container name
//
// @example
//
// init(); - Default mode
// init(true); - Interactive mode
// init(false, true); - Force file creation
// init(true, true); - Interactive mode and force file creation
//
export async function init(interactive = false, force = false) {
  // Get package config
  const packageJson = JSON.parse(
    fs.readFileSync(
      path.join(__dirname, "../../package.json"),
      "utf-8"
    )
  );

  const config = packageJson.config;

  // Get the compose path
  const composePath = config.compose_path || composePath;

  let containerName;

  // Check if the docker-compose file exists
  // If it exists and force is false, skip setup
  // Otherwise, get the inputs and create the file
  if (fs.existsSync(composePath) && !force) {
    console.log(chalk.yellow(`${composePath} already exists. Skipping Setup.`));
    const composeFile = yaml.parse(fs.readFileSync(composePath, "utf8"));
    containerName = Object.keys(composeFile.services)[0];
  } else {
    const inputs = await getInputs(interactive, config);
    containerName = inputs.container_name;

    const templatePath = config.template_path;
    const template = formatTemplate(inputs, templatePath);

    fs.writeFileSync(composePath, template);
    console.log(chalk.green(`Successfully created ${composePath}`));
  }

  // Return the container name
  return Promise.resolve(containerName);
}
