import fs from "fs";
import chalk from "chalk";
import { parse, stringify } from "yaml";
import prompt from "prompt";

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

  const properties = Object.keys(inputs).map((key) => {
    let defaultValue = inputs[key];

    if (Array.isArray(defaultValue)) {
      defaultValue = defaultValue.join(",");
    }
    return {
      name: key,
      description: `Enter the ${key.replace("_", " ")}`,
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

  for (const variable in inputs) {
    let value;

    // if (variable === "volumes") {
    //   value = inputs.volumes
    //     ? inputs.volumes
    //         .split(",")
    //         .map((volume) => `- ${volume.trim()}`)
    //         .join("\n")
    //     : "";
    // } else {
    value = inputs[variable];
    // }

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
    containerName = Object.keys(composeFile.services)[0];
  } else {
    const inputs = await getInputs(interactive);
    containerName = inputs.container_name;

    // @TODO: Move template to configs repo and update the logic
    // const templatePath = "./cli/templates/docker-compose.template";
    // const template = formatTemplate(inputs, templatePath);
    const template = {
      services: {
        "udx-worker": {
          container_name: inputs.container_name,
          // @TODO
          image: "udx-worker-udx-worker:latest",
          volumes: inputs.volumes
            ? inputs.volumes.map((volume) => `${volume.trim()}`)
            : [],
        },
      },
    };

    fs.writeFileSync(composePath, stringify(template));
    console.log(chalk.green(`Successfully created ${composePath}`));
  }

  // Return the container name
  return Promise.resolve(containerName);
}
