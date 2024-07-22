#!/usr/bin/env node

import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { execFile, exec } from "child_process";
import { program } from 'commander';

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

function executeMake(target, actionName) {
  exec(`make -f ${join(__dirname, 'Makefile')} ${target}`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error ${actionName}:`, error);
      return;
    }
    console.log(`stdout: ${stdout}`);
    console.error(`stderr: ${stderr}`);
  });
}

// Define CLI commands using commander
program
  .command('start')
  .description('Start the worker')
  .action(() => executeScript("start", "starting"));

program
  .command('restart')
  .description('Restart the worker')
  .action(() => executeScript("restart", "restarting"));

program
  .command('build')
  .description('Build the Docker image')
  .action(() => executeMake('build', 'building'));

program
  .command('run')
  .description('Run the Docker container')
  .option('-e, --env-file <path>', 'Path to the environment file', './.udx')
  .action((options) => executeMake(`run ENV_FILE=${options.envFile}`, 'running'));

program
  .command('run-interactive')
  .description('Run the Docker container interactively')
  .option('-e, --env-file <path>', 'Path to the environment file', './.udx')
  .action((options) => executeMake(`run-interactive ENV_FILE=${options.envFile}`, 'running interactively'));

program
  .command('exec')
  .description('Exec into the running Docker container')
  .option('-c, --container-name <name>', 'Container name', 'udx-worker-container')
  .action((options) => executeMake(`exec CONTAINER_NAME=${options.containerName}`, 'executing'));

program
  .command('delete')
  .description('Delete the running Docker container')
  .action(() => executeMake('delete', 'deleting'));

program
  .command('log')
  .description('View the Docker container logs')
  .action(() => executeMake('log', 'viewing logs'));

program
  .command('trivy-basic')
  .description('Perform basic Trivy scanning')
  .option('-i, --docker-image <image>', 'Docker image to scan', 'your-docker-image:tag')
  .action((options) => executeMake(`trivy-basic DOCKER_IMAGE=${options.dockerImage}`, 'Trivy scanning'));

program
  .command('trivy-severity')
  .description('Perform Trivy scanning with specific severity')
  .option('-i, --docker-image <image>', 'Docker image to scan', 'your-docker-image:tag')
  .option('-s, --severity <severity>', 'Severity level', 'CRITICAL')
  .action((options) => executeMake(`trivy-severity DOCKER_IMAGE=${options.dockerImage} TRIVY_SEVERITY=${options.severity}`, 'Trivy scanning'));

program
  .command('gcr-login')
  .description('Log in to Google Cloud Artifact Registry')
  .action(() => executeMake('gcr-login', 'GCR login'));

program
  .command('help')
  .description('Show this help message')
  .action(() => program.help());

program.parse(process.argv);
