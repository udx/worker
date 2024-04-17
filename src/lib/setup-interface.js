import fs from "fs";
import chalk from "chalk";
import yaml from "yaml";
import prompt from "prompt";

let container_name;

export async function handleSetup(
  interactive = false,
  composePath = "./docker-compose.yml",
  templatePath = "./src/templates/docker-compose.md",
  force = false
) {
  // Check if docker-compose template exists
  if (!fs.existsSync(templatePath)) {
    console.error(chalk.red(`Error: ${templatePath} template does not exist.`));
    return;
  }

  if (fs.existsSync(composePath) && !force) {
    console.log(chalk.yellow(`${composePath} already exists. Skipping Setup.`));

    const composeFile = yaml.parse(fs.readFileSync(composePath, "utf8"));
    container_name = Object.keys(composeFile.services)[0];
  } else {
    // Get package.json
    const packageJson = JSON.parse(fs.readFileSync("./package.json", "utf-8"));

    // Get config from package.json
    const config = packageJson.config;

    let inputs = config.environment;

    if (interactive) {
      // Define the properties for the prompt
      const properties = [
        {
          name: "container_name",
          description: "Enter the service name",
          default: config.environment.container_name,
        },
        {
          name: "user",
          description: "Enter the user",
          default: config.environment.user,
        },
        {
          name: "volumes",
          description:
            "Enter multiple volumes separated by comma: ./src:/home/app,./bin:/home/bin",
          default: config.environment.volume,
        },
      ];

      // Start the prompt
      prompt.start();

      // Get the user input
      inputs = await new Promise((resolve, reject) => {
        prompt.get(properties, function (err, result) {
          if (err) {
            reject(err);
          } else {
            resolve(result);
          }
        });
      });
    }

    container_name = inputs.container_name;

    // Read the contents of the template file
    let template = fs.readFileSync(templatePath, "utf8");

    // Replace variables in the template with their default values
    for (const variable in inputs) {
      let value;

      if (variable === "volumes") {
        value = inputs.volumes.split(",").map((volume) => volume.trim());
      } else {
        value = inputs[variable];
      }

      const regex = new RegExp(`#{${variable.toUpperCase()}}`, "g");
      template = template.replace(regex, value);
    }

    // Use the template to create a new docker-compose.yml file
    fs.writeFileSync(composePath, template);

    console.log(chalk.green(`Successfully created ${composePath}`));
  }

  return Promise.resolve(container_name);
}
