/**
 *
 *
 * ENABLE_MYSQL=true pm2 startOrReload ~/ecosystem.config.js
 *
 * @type {*[]}
 */

// const _ = require('lodash');

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
    // "error_file": "/var/log/wpcloud.site/deployment.log",
    // "out_file": "/var/log/wpcloud.site/deployment.log",
    // "log_date_format": "YYYY-MM-DD HH:mm Z"
  },
];

// if (process.env.ENABLE_CRON === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/bin/wpcloud.site.cron",
//         "name": "cron",
//         "kill_timeout": "2000",
//         "merge_logs": true,
//         "vizion": false,
//         "exec_mode": "fork",
//         "restart_delay": 10000,
//         "instances": 1,
//         "error_file": "/var/log/wpcloud.site/cron.log",
//         "out_file": "/var/log/wpcloud.site/cron.log",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     })

// }
