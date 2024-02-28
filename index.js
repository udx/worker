#!/usr/bin/env node

import { exec } from 'child_process';

const args = process.argv.slice(2).join(' ');

exec(`docker run cli ${args}`, (error, stdout, stderr) => {
  if (error) {
    console.error(`exec error: ${error}`);
    return;
  }
  console.log(`stdout: ${stdout}`);
  console.error(`stderr: ${stderr}`);
});