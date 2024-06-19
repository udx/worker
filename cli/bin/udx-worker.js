#!/usr/bin/env node

import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { execFile } from "child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function executeScript(scriptName, actionName) {
  const script = join(__dirname, `${scriptName}.sh`);
  execFile(script, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error ${actionName}:`, error);
      return;
    }
    console.log(`stdout: ${stdout}`);
    console.error(`stderr: ${stderr}`);
  });
}

const commands = {
  start: () => executeScript("start", "starting"),
  restart: () => executeScript("restart", "restarting"),
  help: () => console.log("Usage: udx-worker <start|restart|help>")
};

// Command line arguments handling
const args = process.argv.slice(2);
if (args.length > 0) {
  const command = commands[args[0]];
  if (command) {
    command();
  } else {
    console.log(`Unknown command: ${args[0]}`);
    commands.help();
  }
} else {
  commands.help();
}