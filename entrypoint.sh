#!/bin/sh
set -e

echo "==> Step 1: Generating configuration files"
/generate-conf.sh

echo "==> Step 2: Starting temporary Nginx instance for ACME challenges"
# Start nginx in the background
nginx

# Wait a few seconds to ensure Nginx is up and listening
sleep 3

echo "==> Step 3: Generating / renewing certificates and enabling HTTPS"
/generate-certs.sh

echo "==> Step 4: Stopping temporary Nginx to restart with fresh HTTPS configuration"
nginx -s quit

echo "==> Step 5: Running Nginx in foreground mode (PID 1)"
# Nginx runs in the foreground to keep the Docker container alive
exec nginx -g "daemon off;"
