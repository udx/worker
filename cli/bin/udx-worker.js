#!/usr/bin/env node

import { fileURLToPath } from "url";
import { dirname, join } from "path";
import { exec } from "child_process";
import { program } from 'commander';
import readline from 'readline';
import fs from 'fs';
import yaml from 'yaml';
import { readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const configPath = '/src/configs/worker.yml';

// Load the worker configuration
const configFile = readFileSync(configPath, 'utf8');
const config = yaml.parse(configFile);

const questions = Object.keys(config.config.env).map(key => ({
  question: `Enter ${key.replace(/_/g, ' ')}: `,
  key
}));

function executeCommand(command, actionName) {
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error ${actionName}:`, error);
      return;
    }
    console.log(`stdout: ${stdout}`);
    console.error(`stderr: ${stderr}`);
  });
}

function executeMake(target, actionName, options = '') {
  const cmd = `make -f ${join(__dirname, '../Makefile')} ${target} ${options}`;
  executeCommand(cmd, actionName);
}

function generateEnvFile() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  let envContent = '';
  let currentQuestionIndex = 0;

  function askNextQuestion() {
    if (currentQuestionIndex < questions.length) {
      rl.question(questions[currentQuestionIndex].question, (answer) => {
        envContent += `${questions[currentQuestionIndex].key}=${answer}\n`;
        currentQuestionIndex++;
        askNextQuestion();
      });
    } else {
      rl.close();
      const envFilePath = join(process.cwd(), '.udx');
      fs.writeFileSync(envFilePath, envContent, 'utf8');
      console.log('.udx environment file generated successfully.');
    }
  }

  askNextQuestion();
}

program
  .command('build')
  .description('Build the Docker image')
  .action(() => executeMake('build', 'building'));

program
  .command('run')
  .description('Run the Docker container')
  .option('-e, --env-file <path>', 'Path to the environment file', './.udx')
  .action((options) => executeMake('run', 'running', `ENV_FILE=${options.envFile}`));

program
  .command('run-interactive')
  .description('Run the Docker container interactively')
  .option('-e, --env-file <path>', 'Path to the environment file', './.udx')
  .action((options) => executeMake('run-interactive', 'running interactively', `ENV_FILE=${options.envFile}`));

program
  .command('exec')
  .description('Exec into the running Docker container')
  .option('-c, --container-name <name>', 'Container name', 'udx-worker-container')
  .action((options) => executeMake('exec', 'executing', `CONTAINER_NAME=${options.containerName}`));

program
  .command('delete')
  .description('Delete the running Docker container')
  .action(() => executeMake('delete', 'deleting'));

program
  .command('log')
  .description('View the Docker container logs')
  .action(() => executeMake('log', 'viewing logs'));

program
  .command('gcr-login')
  .description('Log in to Google Cloud Artifact Registry')
  .action(() => executeMake('gcr-login', 'GCR login'));

program
  .command('generate-env')
  .description('Generate the .udx environment file')
  .action(() => generateEnvFile());

program
  .command('pull')
  .description('Pull Docker image from repository')
  .option('-i, --image <image>', 'Docker image to pull', 'udx-worker/udx-worker:latest')
  .action((options) => executeMake('pull', 'pulling image', `DOCKER_IMAGE=${options.image}`));

program
  .command('help')
  .description('Show this help message')
  .action(() => program.help());

program.parse(process.argv);
