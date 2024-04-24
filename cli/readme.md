# UDX Worker CLI

UDX Worker CLI is a command-line interface tool for managing UDX Worker tasks. It provides a set of commands to setup, execute, and cleanup tasks in an efficient manner.

## Installation

To install the UDX Worker CLI, you can use npm and run the following from the root of your project:

```bash
npm install udx-worker-cli --save-dev
```

Or add it to `package.json` as dev dependency and run:

```bash
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

### Setup

The `setup` command is used to setup the Ephemeral Workstation. It supports interactive mode.

```bash
udx-worker setup
udx-worker setup -m plan
udx-worker setup -m apply
udx-worker setup -f
udx-worker setup -m plan -f
```

### Execute

The `execute` command is used to execute a Docker command utilizing ephemeral tooling worker (based on udx-worker or udx-worker itself).

```bash
udx-worker execute "ls -l"
udx-worker execute "pwd"
udx-worker execute "bash -c 'echo Hello, World!'"
udx-worker execute nodejs /home/${USER}/bin/sync-history.js
```

### Bin Scripts

#### Cleanup

The `cleanup` command is used to execute a cleanup script. It stops worker containers and deletes built images.

```bash
udx-worker cleanup
```

#### Restart

The `restart` command is used to execute a cleanup script. It stops all running containers, removes all images, rebuilds images, and starts new containers.

```bash
udx-worker restart
```

## Testing

To run the unit tests, use the following command:

```bash
npm test
```

For more information about the tests, see the [README.md](./__tests__/README.md) file in the `__tests__` directory.
