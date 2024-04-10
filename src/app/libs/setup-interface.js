import fs from "fs";
import inquirer from "inquirer";
import chalk from "chalk";

export async function handleSetup(
  parsed,
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
    return;
  }

  // Read the contents of the template file
  let template = fs.readFileSync(templatePath, "utf8");

  // Ask for user input
  const answers = await inquirer.prompt([
    {
      name: "service_name",
      message: "Enter the service name:",
      default: parsed.service_name || "#{CONTAINER_NAME}",
    },
    {
      name: "user",
      message: "Enter the user:",
      default: parsed.user || "#{USER}",
    },
    {
      name: "app_path",
      message: "Enter the app path:",
      default: parsed.app_path || "#{APP_PATH}",
    },
  ]);

  // Replace variables in the template with their default values
  for (const variable in answers) {
    const value = answers[variable];
    const regex = new RegExp(variable, "g");
    template = template.replace(regex, value);
  }

  // Use the template to create a new docker-compose.yml file
  fs.writeFileSync(composePath, template);

  console.log(chalk.green(`Successfully created ${composePath}`));
}
