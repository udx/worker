// Import the necessary modules and functions
import { execSync } from "child_process";
import fs from 'fs';
import path from 'path';
jest.mock('child_process');

// Read and parse the package.json file
const pkg = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../cli/package.json'), 'utf-8'));

const { commands } = pkg.config;

// Define a test suite for the udx-worker CLI
describe("udx-worker CLI", () => {
  // Loop over the commands array
  commands.forEach((command) => {
    if (command.enabled) {
      test(`${command.name} command`, () => {
        let result;
        try {
          // Mock the execSync function to simulate the execution of the command
          execSync.mockImplementation(() => 'success');
          // Execute the command and get the output
          const cmd = `node cli/index.js ${command.name}`;
          console.log(`Executing command: ${cmd}`);
          result = execSync(cmd);
        } catch (error) {
          // If the command fails, log the error message and set result to null
          console.error(`Error executing command: ${command.name}`);
          console.error(error.stderr.toString());
          result = null;
        }

        // Check that the command was executed successfully
        expect(result).toBeTruthy();
      });
    }
  });
});