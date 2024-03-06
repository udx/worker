/**
 *
 *
 * ENABLE_MYSQL=true pm2 startOrReload ~/ecosystem.config.js
 *
 * @type {*[]}
 */

// const _ = require('lodash');

module.exports.apps = [{
    "script": "/home/app/index.js",
    "name": "application",
    "kill_timeout": "2000",
    "merge_logs": true,
    "vizion": false,
    "exec_mode": "fork",
    "restart_delay": 10000,
    "instances": 1,
    // "error_file": "/var/log/wpcloud.site/deployment.log",
    // "out_file": "/var/log/wpcloud.site/deployment.log",
    // "log_date_format": "YYYY-MM-DD HH:mm Z"
}];

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

// if (process.env.ENABLE_FIREBASE === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/bin/wpcloud.site.firebase",
//         "name": "firebase",
//         "kill_timeout": "2000",
//         "merge_logs": true,
//         "vizion": false,
//         "exec_mode": "fork",
//         "restart_delay": 10000,
//         "instances": 1,
//         "error_file": "/var/log/wpcloud.site/firebase.log",
//         "out_file": "/var/log/wpcloud.site/firebase.log",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     })

// }

// if (process.env.ENABLE_NGINX === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/sbin/nginx",
//         "args": "-c /etc/nginx/nginx.conf -g 'daemon off;'  -p /var/log/wpcloud.site/nginx",
//         "name": "nginx",
//         "merge_logs": true,
//         "vizion": false,
//         "restart_delay": 10000,
//         "max_restarts": 50,
//         "error_file": "/var/log/wpcloud.site/nginx/error.log",
//         "out_file": "/var/log/wpcloud.site/nginx/access.log",
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     })

// }

// if (process.env.ENABLE_PHP7_FPM === 'true') {

//     if (!process.env.PHP_VERSION) {
//         process.env.PHP_VERSION = "7.0"
//     }

//     module.exports.apps.push({
//         "script": "/usr/sbin/php-fpm" + process.env.PHP_VERSION,
//         "args": "-c /etc/php/" + process.env.PHP_VERSION + "/fpm/php.ini --fpm-config=/etc/php/" + process.env.PHP_VERSION + "/fpm/php-fpm.conf --nodaemonize",
//         "name": "php" + process.env.PHP_VERSION,
//         "merge_logs": true,
//         "vizion": false,
//         "error_file": "/var/log/wpcloud.site/fpm/php-fpm.log",
//         "out_file": "/var/log/wpcloud.site/fpm/php-fpm.log",
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z",
//         "env": {}
//     });

// }

// if (process.env.ENABLE_PHP8_FPM === 'true') {

//     if (!process.env.PHP_VERSION) {
//         process.env.PHP_VERSION = "8.1"
//     }

//     module.exports.apps.push({
//         "script": "/usr/sbin/php-fpm" + process.env.PHP_VERSION,
//         "args": "-c /etc/php/" + process.env.PHP_VERSION + "/fpm/php.ini --fpm-config=/etc/php/" + process.env.PHP_VERSION + "/fpm/php-fpm.conf --nodaemonize",
//         "name": "php" + process.env.PHP_VERSION,
//         "merge_logs": true,
//         "vizion": false,
//         "error_file": "/var/log/wpcloud.site/fpm/php-fpm.log",
//         "out_file": "/var/log/wpcloud.site/fpm/php-fpm.log",
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z",
//         "env": {}
//     });

// }

// if (process.env.ENABLE_PROXY === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/bin/wpcloud.site.proxy",
//         "name": "proxy",
//         "kill_timeout": "2000",
//         "merge_logs": true,
//         "vizion": false,
//         "exec_mode": "fork",
//         "restart_delay": 10000,
//         "instances": 1,
//         "error_file": "/var/log/wpcloud.site/proxy.log",
//         "out_file": "/var/log/wpcloud.site/proxy.log",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     })

// }

// if (process.env.ENABLE_APACHE2 === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/sbin/apache2",
//         "args": "-DFOREGROUND -e error -E /var/log/wpcloud.site/apache.start.log",
//         "env": {
//             "APACHE_CONFDIR": "/etc/apache2",
//             "APACHE_PID_FILE": "/var/run/apache2/apache2.pid",
//             "APACHE_RUN_DIR": "/var/run/apache2",
//             "APACHE_LOG_DIR": "/var/log/wpcloud.site",
//             "APACHE_LOCK_DIR": "/var/lock/apache2",
//             "APACHE_RUN_USER": "core",
//             "APACHE_RUN_GROUP": "core",
//             "APACHE_ENVVARS": "/etc/apache2/envvars"
//         },
//         "out_file": "/var/log/wpcloud.site/apache.start.log",
//         "error_file": "/var/log/wpcloud.site/apache.start.log",
//         "name": "apache2",
//         "merge_logs": true,
//         "restart_delay": 10000,
//         "max_restarts": 50,
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     });

// }

// if (process.env.ENABLE_PHP5_FPM === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/sbin/php-fpm5.6",
//         "args": "-c /etc/php/5.6/fpm/php.ini --fpm-config=/etc/php/5.6/fpm/php-fpm.conf --nodaemonize",
//         "name": "php5",
//         "merge_logs": true,
//         "vizion": false,
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     })

// }

// if (process.env.ENABLE_MEMCACHED === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/bin/memcached",
//         "args": "-P /var/run/wpcloud.site/memcached.pid -m 64 -p 11311 -I 1M -u memcache -l 127.0.0.1",
//         "name": "memcached",
//         "merge_logs": true,
//         "vizion": false,
//         "out_file": null,
//         "error_file": null,
//         "restart_delay": 10000,
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     });

// }

// if (process.env.ENABLE_MYSQL === 'true') {
//     module.exports.apps.push({
//         "name": "mariadb",
//         "script": "/usr/sbin/mysqld",
//         "args": [
//             "--basedir=/usr",
//             "--datadir=/var/lib/wpcloud.mysql",
//             "--plugin-dir=/usr/lib/mysql/plugin",
//             "--log-error=/var/log/wpcloud.site/mysql",
//             "--user=core",
//             "--skip-log-error",
//             "--pid-file=/var/run/mysqld/mysqld.pid",
//             "--socket=/var/run/mysqld/mysqld.sock",
//             "--port=" + (_.get(process, 'env.MYSQL_SERVICE_PORT', '3306'))
//         ].join(" "),
//         "merge_logs": true,
//         "vizion": false,
//         "out_file": "/var/log/wpcloud.site/mysql",
//         "pid_file	": "/var/run/mysqld/mysqld.pid",
//         "error_file": "/var/log/wpcloud.site/mysql",
//         "restart_delay": 10000,
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     });

// }

// if (process.env.ENABLE_REDIS === 'true') {

//     module.exports.apps.push({
//         "script": "/usr/bin/redis-server",
//         "args": "--port 16379",
//         "name": "redis",
//         "out_file": null,
//         "error_file": null,
//         "merge_logs": true,
//         "vizion": false,
//         "exec_mode": "fork",
//         "log_date_format": "YYYY-MM-DD HH:mm Z"
//     })

// }