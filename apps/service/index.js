/**
 * 
 * Mock service that logs a message every 5 seconds.
 * 
 */

function sleep(seconds) {
  const milliseconds = seconds * 1000;
  const start = Date.now();
  while (true) {
    const current = Date.now();
    if (current - start >= milliseconds) {
      break;
    }
  }
}

while (true) {
  console.log(`[${new Date().toLocaleTimeString()}] Service is up and running!`);
  sleep(5);
}
