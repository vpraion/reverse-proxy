# --------------------------------------------
# 🏔️ 1. Base image
# Using Alpine Linux for a small, efficient container.
# --------------------------------------------
FROM alpine

# --------------------------------------------
# 📦 2. Install required packages
# - nginx: web server & reverse proxy
# - certbot: Let's Encrypt ACME client
# - jq: to parse vhosts.json
# - openssl: for generating self-signed certificates in dev mode
# --------------------------------------------
RUN apk update && \
    apk add --no-cache nginx certbot jq openssl

# --------------------------------------------
# 🧭 3. Copy Nginx configuration
# - nginx.conf: base server configuration (includes sites-enabled)
# - conf-template: directory containing http/https templates and vhosts.json
# --------------------------------------------
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf-template /etc/nginx/conf-template

# --------------------------------------------
# 🗂️ 4. Prepare Nginx directory structure
# - sites-available/http  → generated HTTP configs
# - sites-available/https → generated HTTPS configs
# - sites-enabled         → active configs (symlink targets)
# This mimics the structure commonly used in Debian-based Nginx setups.
# --------------------------------------------
RUN mkdir -p /etc/nginx/sites-available/http
RUN mkdir -p /etc/nginx/sites-available/https
RUN mkdir -p /etc/nginx/sites-enabled

# --------------------------------------------
# 🔐 5. Prepare Let's Encrypt base directory
# This is where Certbot will store issued certificates.
# It's also mounted as a volume in docker-compose.
# --------------------------------------------
RUN mkdir -p /etc/letsencrypt/live

# --------------------------------------------
# ⚙️ 6. Copy helper scripts into the container
# These scripts handle config generation, SSL cert issuance,
# and orchestrating Nginx startup.
# --------------------------------------------
COPY generate-conf.sh /generate-conf.sh
COPY generate-certs.sh /generate-certs.sh
COPY entrypoint.sh /entrypoint.sh

# --------------------------------------------
# 🔓 7. Make scripts executable
# Required so the container can run them directly.
# --------------------------------------------
RUN chmod +x /generate-conf.sh
RUN chmod +x /generate-certs.sh
RUN chmod +x /entrypoint.sh

# --------------------------------------------
# 🚀 8. Entrypoint
# This script:
#   1. Generates config files
#   2. Starts Nginx temporarily for ACME challenges
#   3. Issues or renews SSL certificates
#   4. Restarts Nginx in foreground mode (PID 1)
# --------------------------------------------
ENTRYPOINT [ "/entrypoint.sh" ]
