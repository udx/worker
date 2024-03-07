# Install pm2
npm install pm2

# Set the entrypoint to start pm2 processes
exec pm2-runtime start /home/etc/ecosystem.config.js
