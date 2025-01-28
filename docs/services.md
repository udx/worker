## Services Configuration

The `services.yaml` file contains a list of services to be managed by the worker. Each service is defined using the following structure:

```yaml
---
kind: workerService
version: udx.io/worker-v1/service
services:
  - name: "<service_name>"
    ignore: "<true/false>"
    command: "<command_to_run>"
    autostart: "<true/false>"
    autorestart: "<true/false>"
    envs:
      - "<ENV_VAR_NAME>=<value>"
```

### Service Fields Explanation

* `name`: Unique identifier for the service. This is used to reference and manage the service within the system.

* `ignore`: Determines whether the service should be ignored. If set to "true", the service will not be managed by the worker. The default value is "false", which means the service is considered for management.

* `command`: The command that the service will execute. This could be a shell script or any executable along with its arguments.

* `autostart`: Indicates whether the service should start automatically when the worker starts. The default is "true", meaning the service will start automatically.

* `autorestart`: Specifies whether the service should automatically restart if it stops. If "true", the service will restart according to the policy defined by the worker management system. The default value is "false", indicating the service will not restart automatically.

* `envs`: An array of environment variables passed to the service in the format `KEY=value`. These variables are made available to the service at runtime.

## Usage

To use this configuration file, make sure to mount it with your application under `/home/udx/`. It doesn't matter where you mount it, it could be autodetected in any subdirectory if it's mounted correctly and named `services.yaml`.