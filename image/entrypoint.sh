#!/bin/bash

# Execute the passed command, or default to the entrypoint script
exec "$@" || exec /home/"${USER}"/bin-modules/entrypoint.sh