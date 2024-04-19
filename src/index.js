#!/usr/bin/env node

import nopt from "nopt";

import { handleSetup } from "./lib/setup-interface.js";
import { checkAndStartContainers, executeDockerCommand } from "./lib/docker.js";
import help from "./lib/help.js";

async function main() {
  // Setup Ephemeral Workstation with interactive mode
  const container_name = await handleSetup(true);

  // Check if container is running and start it
  await checkAndStartContainers(container_name);

  // Define options
  const options = { cmd: [String, null] };

  const parsed = nopt(options, {}, process.argv, 2);

  // Execute Docker command
  if (!parsed.cmd) {
    console.log("No command provided. Configuration mode enabled.");
    // help.showHelp(container_name);
    await executeDockerCommand("udx-worker", ["project_init"]);
  } else {
    await executeDockerCommand("udx-worker", parsed.cmd);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
