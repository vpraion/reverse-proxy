# 🧭 Automated Reverse Proxy with SSL (Nginx + Certbot + Docker)

This project provides a **fully automated HTTPS reverse proxy** using [Nginx](https://nginx.org) and [Certbot](https://certbot.eff.org), wrapped in a lightweight Docker container.
It is designed to make SSL management **simple, reproducible, and portable**, whether you're working locally (self-signed) or in production (Let's Encrypt).

---

## ✨ Features

- 🚀 Automatic **HTTP and HTTPS Nginx config generation** from a simple JSON file
- 🔐 **ACME certificate issuance and renewal** (Let's Encrypt in production, OpenSSL self-signed in dev)
- 🐳 Lightweight Docker image (based on Alpine)
- ♻️ Safe initialization with templates (`.env` & `vhosts.json`)
- 📜 Clean startup orchestration (temporary HTTP → SSL issuance → HTTPS reload)
- 🔁 Works seamlessly with multiple domains


---

## 🧰 Requirements

- 🐳 Docker & Docker Compose
- A domain name pointing to your server (for production SSL)
- Ports `80` and `443` from your router redirected to the computer that will run
this solution
- `make` to launch the Makefile commands

---

## Usage

### 🌍 Production Mode (Let's Encrypt)

```bash
make prod
```

- Runs the container
- Issues real SSL certificates with Let's Encrypt
- Configures auto-renewal

*👉 Make sure your domain DNS points correctly to your server and that ports 80 & 443 are open.*

### 🚧 Development Mode (Self-signed SSL for testing)

```bash
make dev
```

- Runs the container
- Generates self-signed certificates
- Useful for local testing with HTTPS

### 🧹 Maintenance Commands

|Command|Description |
|---|---|
|`make init`|Initialize config files if missing
|`make prod`|Launch stack with Let's Encrypt certificates
|`make down`|Stop all running containers
|`make dev`|Launch stack with self-signed certificates
|`make prune`|Stop & prune the stack (containers, volumes, images for this project)
|`make logs`|View container logs in real-time

---

## 🏗️ Project Structure

```graphql
.
├── conf-template/
│   ├── http.template            # Base HTTP server block
│   ├── https.template           # Base HTTPS server block
│   ├── vhosts.json.dist         # Example virtual hosts definition
├── nginx.conf                   # Main Nginx configuration
├── generate-conf.sh             # Generates site configs from templates
├── generate-certs.sh            # Issues or renews SSL certificates
├── entrypoint.sh                # Orchestrates startup process
├── Dockerfile                   # Container build file
├── docker-compose.yml           # Stack definition
├── .env.dev.dist                # Example dev environment file
├── .env.prod.dist               # Example prod environment file
└── Makefile                     # Automation commands (init, build, run, prune...)
```

---

## 🧾 Configuration

### 1. Initialize environment

```bash
make init
```

### 2. Edit `conf-template/vhosts.json`

```json
[
    {
        "domain": "some-url.xyz",
        "host": "192.168.1.5",
        "port": 8081,
        "mail": "admin@admin.xyz"
    },
    {
        "domain": "some-other-website.com",
        "host": "192.168.1.5",
        "port": 8096,
        "mail": "admin@admin.xyz"
    }
]
```
- domain: the domain name to serve
- host: the backend target host
- port: the backend port
- mail: the mail that will be given to Let's Encrypt

---

## 🔐 Volumes & Data

This stack uses Docker volumes to persist SSL certificates:

```yml
volumes:
  letsencrypt_data:
```

Certificates are stored in:

```plaintext
/etc/letsencrypt/live/<your-domain>/
```

This ensures they survive container rebuilds.

---

## 🪄 How It Works Internally
- `entrypoint.sh` runs at container start:
- - Generates HTTP & HTTPS configs
- - Starts Nginx temporarily to serve ACME challenges
- - Runs `certbot` or `openssl` to get certs
- - Restarts `nginx` in foreground (PID 1)
- `generate-conf.sh` uses `sed` and `jq` to build Nginx's vhost configs from templates.
- `generate-certs.sh`:
- - Checks if a cert already exists
- - Creates a self-signed one in dev
- - Or requests/renews a Let's Encrypt one in prod
- Nginx runs as a reverse proxy and auto-renews certificates periodically.
