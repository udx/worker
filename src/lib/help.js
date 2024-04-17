// @TODO
// @TODO

import { executeDockerCommand } from "./lib/docker.js";

function showHelp(container_name) {
  console.log("Hello, world. This is the UDX Worker Command Line Interface.");
  console.log("Here are the available commands:");

  let command = "get_available_commands --format=json";
  const commands = executeDockerCommand(container_name, command);

  for (const i in commands) {
    let command = commands[i];
    console.log(`udx-worker ${command.value} - ${command.description}`);
  }

  // console.log("");
  // console.log("udx-worker - Display this help message.");
  // console.log("");
  // console.log("udx-worker - Initialize a new UDX Worker project.");
  // console.log(
  //   "This will create a new directory with the necessary files and folders. If the directory already exists, the logic will detect this and prompt the user to overwrite the existing files/configurations."
  // );
  // console.log("");
  // console.log("udx-worker build - Build the UDX Worker project.");
  // console.log(
  //   "This will compile the source code and generate the necessary files for deployment."
  // );
  // console.log("");
  // console.log("udx-worker test - Test the UDX Worker project.");
  // console.log(
  //   "This will run the test suite to ensure the UDX Worker project is functioning as expected."
  // );
  // console.log("");
  // console.log("udx-worker release - Release the UDX Worker project.");
  // console.log(
  //   "This will create a new release version of the UDX Worker project and upload it to the UDX Worker Registry."
  // );
  // console.log("");
  // console.log("udx-worker deploy - Deploy the UDX Worker project.");
  // console.log(
  //   "This will deploy the UDX Worker project locally or to a remote server."
  // );
}

export default {
  showHelp,
};
