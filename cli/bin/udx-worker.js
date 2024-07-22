#!/usr/bin/env node

import { execFile } from 'child_process';
import { program } from 'commander';
import { join } from 'path';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const makefilePath = join(__dirname, '../../image/Makefile');

function runMakeTarget(target, options = '') {
  const args = ['-f', makefilePath, target, ...options.split(' ')];
  execFile('make', args, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error executing ${target}:`, error);
      return;
    }
    console.log(stdout);
    if (stderr) console.error(stderr);
  });
}

function getMakefileTargets() {
  const makefileContent = fs.readFileSync(makefilePath, 'utf-8');
  const targetRegex = /^([a-zA-Z0-9_-]+):/gm;
  let targets = [];
  let match;

  while ((match = targetRegex.exec(makefileContent)) !== null) {
    if (match.index === targetRegex.lastIndex) {
      targetRegex.lastIndex++;
    }
    targets.push(match[1]);
  }

  return targets;
}

const targets = getMakefileTargets();

targets.forEach(target => {
  program
    .command(target)
    .description(`Run the '${target}' target from the Makefile`)
    .action(() => runMakeTarget(target));
});

program.parse(process.argv);
