import fs from "fs";
import chalk from "chalk";
import { parse, stringify } from "yaml";
import prompt from "prompt";
import _ from "lodash";

//
// Define the default compose path
//
async function getInputs(interactive) {
  let inputs = {
    container_name: "udx-worker",
    user: "udx-worker",
    volumes: ["./fixtures/apps/task:/home/app"],
  };

  if (!interactive) {
    console.log(
      chalk.yellow("Running in non-interactive mode. Using default values.")
    );
    return inputs;
  }

  const properties = _.map(inputs, (defaultValue, key) => {
    if (_.isArray(defaultValue)) {
      defaultValue = defaultValue.join(",");
    }
    return {
      name: key,
      description: `Enter the ${_.replace(key, "_", " ")}`,
      default: defaultValue,
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

  _.forIn(inputs, (value, variable) => {
    const regex = new RegExp(`#{${_.toUpper(variable)}}`, "g");
    template = _.replace(template, regex, value);
  });

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
export async function init(
  interactive = false,
  force = false,
  composePath = "./docker-compose.yml"
) {
  let containerName;

  // Check if the docker-compose file exists
  // If it exists and force is false, skip setup
  // Otherwise, get the inputs and create the file
  if (fs.existsSync(composePath) && !force) {
    console.log(chalk.yellow(`${composePath} already exists. Skipping Setup.`));
    const composeFile = parse(fs.readFileSync(composePath, "utf8"));
    containerName = _.head(_.keys(composeFile.services));
  } else {
    const inputs = await getInputs(interactive);
    containerName = inputs.container_name;

    const template = {
      services: {
        "udx-worker": {
          container_name: inputs.container_name,
          image: "cli-udx-worker:latest",
          // volumes: _.map(inputs.volumes, (volume) => `${_.trim(volume)}`),
        },
      },
    };

    fs.writeFileSync(composePath, stringify(template));
    console.log(chalk.green(`Successfully created ${composePath}`));
  }

  // Return the container name
  return Promise.resolve(containerName);
}