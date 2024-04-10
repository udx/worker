import fs from "fs";
import nopt from "nopt";
import { handleSetup } from "./libs/setup-interface";
import { checkAndStartContainers, executeDockerCommand } from "./libs/docker";

const packageJson = require("../../package.json");

// Get config from package.json
const config = packageJson.config;

// Define options
const options = {
  type: [String, null],
  cmd: [String, Array],
  service_name: [String, null],
  user: [String, null],
  app_path: [String, null],
};

// Parse command line arguments
const parsed = nopt(options, {}, process.argv, 2);

// Apply defaults if not provided
parsed.container_name = parsed.container_name || config.container_name;
parsed.user = parsed.user || config.user;
parsed.app_path = parsed.app_path || config.app_path;

// Setup Ephemeral Workstation
handleSetup(parsed);

// Check if container is running and start it
checkAndStartContainers(container);

// Execute Docker command
executeDockerCommand(container, parsed);
