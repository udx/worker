# Tests

This directory contains the unit tests for the udx-worker CLI.

## Running the Tests

To run the tests, use the following command:

```bash
npm test
```

## Test Files

index.test.js: This file contains tests for the main functionality of the udx-worker CLI. It tests the following commands:

- `setup`: Checks that the setup command initializes the container correctly.
- `execute`: Checks that the execute command runs the specified command and returns the correct result.
- `cleanup`: Checks that the cleanup command cleans up the container correctly.
- `restart`: Checks that the restart command restarts the container correctly.

It also checks that the execute command fails correctly when given an invalid command.
Each test checks that the command was parsed correctly by checking the args and rawArgs properties of the result object.

## Test Libraries

The tests use the following libraries:

- Jest: A JavaScript testing framework used to write and run the tests.
- Commander: A library for writing command-line interfaces in Node.js. It's used to parse the command-line arguments in the tests.
