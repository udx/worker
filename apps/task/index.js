/**
 *
 * Mock service that logs a message every 5 seconds.
 *
 */

console.log(`[${new Date().toLocaleTimeString()}] Task is running ...`);

// Simulate a long running task
setTimeout(() => {
  // Call the callback function to signal that the task is completed
  console.log(`[${new Date().toLocaleTimeString()}] Task is completed!`);
  process.exit(1);
}, 5000);
