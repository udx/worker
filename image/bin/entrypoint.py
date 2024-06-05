#!/usr/bin/env python3

import os
import sys
import time
import subprocess
import importlib.util
from colorama import init, Fore

# Initialize colorama
init()

def nice_logs(message, level):
    # Replace this with the actual logic of your nice_logs function
    pass

# Check if pip and python3 are installed
if not subprocess.call('command -v pip', shell=True) or not subprocess.call('command -v python3', shell=True):
    print("pip and python3 are required but not installed. Please install them and try again.")
    sys.exit()

# Load all modules in the modules directory
modules_dir = "bin-modules/modules"
if os.path.isdir(modules_dir):
    for module_file in os.listdir(modules_dir):
        if module_file.endswith('.sh'):
            spec = importlib.util.spec_from_file_location("module.name", os.path.join(modules_dir, module_file))
            foo = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(foo)
else:
    print("Directory bin-modules/modules does not exist.")
    sys.exit()

# Use the colors in logs
nice_logs("Here you go, welcome to UDX Worker Container.", "info")

nice_logs("...")

time.sleep(1)

nice_logs("Init the environment...", "info")

nice_logs("...")

# Add the current directory to the Python path
sys.path.append(os.path.dirname(os.path.realpath(__file__)))

subprocess.call('pip install colorama', shell=True)

# Call the EnvironmentController from the modules environment
import logging
from modules import environment

logging.basicConfig(level=logging.INFO, stream=sys.stdout, format=Fore.GREEN + ' [Environment] %(message)s' + Fore.RESET)

logging.info('Do the configuration...')

try:
    environment.EnvironmentController()
except Exception as e:
    logging.exception('An error occurred: ')

nice_logs("...")

time.sleep(1)

nice_logs("The worker has started successfully.", "success")

# Check if the first argument is "project_init"
if len(sys.argv) > 1 and sys.argv[1] == "project_init":
    from modules import project
    project.init_project("apply", True, sys.argv[2], sys.argv[3])