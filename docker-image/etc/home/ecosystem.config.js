/**
 *
 * This file is used to configure options and settings for the pm2 process manager.
 *
 *
 */

module.exports.apps = [
  {
    name: process.env.ENV_TYPE,
    script: "/home/app/index.js",
    kill_timeout: "2000",
    merge_logs: true,
    vizion: false,
    exec_mode: "fork",
    restart_delay: 10000,
    instances: 1,
  },
];