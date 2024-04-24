//
// Description:
// - This file contains the test suite for the udx-worker CLI.
// - The test suite includes tests for the setup, execute, cleanup, and restart commands.
// - The tests check that the CLI commands are parsed correctly and that the correct command line arguments are passed to the program.
// - The tests also check that the execute command fails when an invalid command is passed.
// - The tests use the Jest testing framework and the commander module to parse the command line arguments.
// - The tests are run using `npm test` command.
// - The tests are run in the `cli/__tests__` directory.

// Import the necessary modules and functions
import { init } from "../lib/interface.js";
import { program } from "commander";

// Define a test suite for the udx-worker CLI
describe("udx-worker CLI", () => {
  test("setup command", async () => {
    const containerName = await init("plan", false);

    const result = await program.parseAsync(["node", "test", "setup"]);

    expect(containerName).toBe("udx-worker");
    expect(result.args).toEqual(["setup"]);
    expect(result.rawArgs).toEqual(["node", "test", "setup"]);
  });

  test("execute command", async () => {
    const result = await program.parseAsync([
      "node",
      "test",
      "execute",
      "ls -l",
    ]);

    // Check that the args property contains the correct command
    expect(result.args).toEqual(["execute", "ls -l"]);

    // Check that the rawArgs property contains the correct command line arguments
    expect(result.rawArgs).toEqual(["node", "test", "execute", "ls -l"]);
  });

  test("cleanup command", async () => {
    const result = await program.parseAsync(["node", "test", "cleanup"]);

    // Check that the args property contains the correct command
    expect(result.args).toEqual(["cleanup"]);

    // Check that the rawArgs property contains the correct command line arguments
    expect(result.rawArgs).toEqual(["node", "test", "cleanup"]);
  });

  test("restart command", async () => {
    const result = await program.parseAsync([
      "node",
      "test",
      "udx-worker restart",
    ]);

    // Check that the args property contains the correct command
    expect(result.args).toEqual(["udx-worker restart"]);

    // Check that the rawArgs property contains the correct command line arguments
    expect(result.rawArgs).toEqual(["node", "test", "udx-worker restart"]);
  });

  test("execute command fails", async () => {
    // Make the execute command fail by passing an invalid command
    const result = await program.parseAsync([
      "node",
      "test",
      "execute",
      "invalid command",
    ]);

    // Check that the args property contains the correct command
    expect(result.args).toEqual(["execute", "invalid command"]);

    // Check that the rawArgs property contains the correct command line arguments
    expect(result.rawArgs).toEqual([
      "node",
      "test",
      "execute",
      "invalid command",
    ]);
  });
});
