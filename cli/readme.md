# UDX Worker CLI

UDX Worker CLI is a command-line interface tool for managing UDX Worker tasks. It provides a set of commands to setup, execute, and cleanup tasks in an efficient manner.

## Installation

To install the UDX Worker CLI, you can use npm and run the following from the root of your project:

```bash
npm install github:udx/udx-worker#latest --save-dev
```

Or add it to `package.json` as a dev dependency:

```json
"devDependencies": {
  "udx-worker": "github:udx/udx-worker#latest"
}
```

Then run:

```
npm install
```

## Usage

### General

You can check the version and get help on how to use the CLI with the following commands:

```bash
udx-worker --version
udx-worker -v
udx-worker --help
udx-worker -h
```

## Testing

To run the unit tests, use the following command:

```bash
npm test
```

For more information about the tests, see the [README.md](./__tests__/README.md) file in the `__tests__` directory.
