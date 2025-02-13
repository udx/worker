# UDX Worker CLI Documentation

The UDX Worker provides a command-line interface for managing services, environment variables, and generating Software Bill of Materials (SBOM).

## Commands

### Service Management

* `worker service list`
  - Lists all available services with their current status
  - Shows service name, status, PID, and uptime

* `worker service status <service_name>`
  - Displays detailed status of a specified service
  - Shows service state, uptime, and process information

* `worker service logs <service_name> [options]`
  - Views service output logs
  - Options:
    - `--lines N`: Show last N lines (default: 20)
    - `--nostream`: Show logs without following
    - `err`: Show error logs instead of output logs

* `worker service config`
  - Shows the services configuration settings
  - Displays supervisor configuration for all services

* `worker service start <service_name>`
  - Starts a specified service
  - Creates necessary log files and directories

* `worker service stop <service_name>`
  - Stops a specified service
  - Service can be restarted later

* `worker service restart <service_name>`
  - Restarts a specified service
  - Equivalent to stop followed by start

### Environment Variables

* `worker env set <key> <value>`
  - Sets an environment variable
  - Variable will be available to all services

* `worker env get [key]`
  - Retrieves environment variable(s)
  - If key is provided, shows specific variable
  - If no key, shows all environment variables

### Software Bill of Materials

* `worker sbom generate`
  - Generates container Software Bill of Materials
  - Lists all installed packages with:
    - Package name
    - Version
    - Architecture

## Examples

```bash
# View service status
worker service status my_service

# Get last 100 lines of logs without following
worker service logs my_service --lines=100 --nostream

# Set and verify environment variable
worker env set MY_VAR "my value"
worker env get MY_VAR

# Generate SBOM
worker sbom generate
```

## Exit Codes

- 0: Command completed successfully
- 1: Command failed or invalid usage

## Notes

- All commands use logging levels: INFO, DEBUG, WARN, ERROR
- Service logs are stored in `/var/log/supervisor/`
- Configuration files are in `/etc/supervisord.conf`