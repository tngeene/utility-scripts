# Interactive Web Server Package Setup Script

This script interactively updates a Debian/Ubuntu server and installs common packages used for web server deployments.

It can install general server utilities, development tools, Nginx, Docker Engine, Docker Compose plugin, Certbot, Node.js/npm, PostgreSQL client tools, Redis tools, Fail2Ban, and UFW.

## Quick Start

Run this after user bootstrap is complete.

```bash
cd server-setups
chmod +x packages.sh
sudo ./packages.sh
```

Tip: if this is a remote VPS, keep your current SSH session open until service and firewall checks pass.

---

## What the Script Does

The script can interactively:

- Update `apt` package lists.
- Upgrade installed system packages.
- Install common server utilities.
- Install development/build tools.
- Install Nginx.
- Install Docker Engine from Docker’s official `apt` repository.
- Install Docker Compose plugin.
- Install Certbot for Let’s Encrypt SSL certificates.
- Install Node.js and npm from the OS repository.
- Install PostgreSQL client tools.
- Install Redis CLI/tools.
- Install Fail2Ban.
- Install UFW firewall.
- Enable and start selected services.
- Run `apt autoremove` and `apt autoclean`.

---

## Supported Systems

This script is intended for:

- Ubuntu
- Debian

It requires `apt-get`.

It is **not intended** for:

- CentOS
- RHEL
- Fedora
- Arch Linux
- Alpine Linux
- macOS

---

## Packages It Can Install

### Common Server Utilities

The script can install:

```text
ca-certificates
curl
wget
gnupg
lsb-release
apt-transport-https
software-properties-common
unzip
zip
tar
gzip
nano
vim
git
htop
tree
rsync
jq
net-tools
dnsutils
iputils-ping
traceroute
telnet
ncdu
cron
logrotate
```

These are useful for administration, debugging, deployments, downloads, archives, networking, monitoring, and log management.

---

### Development Tools

The script can install:

```text
build-essential
make
gcc
g++
pkg-config
python3
python3-pip
python3-venv
```

These are useful for compiling packages, running Python tooling, building native dependencies, and general development tasks.

---

### Nginx

The script can install:

```text
nginx
```

Nginx is commonly used as:

- a web server,
- a reverse proxy,
- a TLS termination proxy,
- a static file server,
- a load balancer for simple deployments.

Optional service actions:

```bash
systemctl enable nginx
systemctl restart nginx
```

Useful checks:

```bash
nginx -t
systemctl status nginx
```

---

### Docker and Docker Compose

The script installs Docker from Docker’s official `apt` repository.

It installs:

```text
docker-ce
docker-ce-cli
containerd.io
docker-buildx-plugin
docker-compose-plugin
```

Docker Compose is installed as the modern Docker CLI plugin and is used like this:

```bash
docker compose up -d
```

not usually like this:

```bash
docker-compose up -d
```

Useful checks:

```bash
docker --version
docker compose version
docker run hello-world
systemctl status docker
```

---

### Certbot

The script can install:

```text
certbot
python3-certbot-nginx
```

Certbot is used to request and renew Let’s Encrypt TLS/SSL certificates.

Common Nginx usage:

```bash
certbot --nginx -d example.com -d www.example.com
```

Before running Certbot, make sure:

- your domain DNS points to the server,
- ports `80` and `443` are reachable,
- Nginx is configured correctly.

---

### Node.js and npm

The script can install:

```text
nodejs
npm
```

These come from the OS package repository.

Caveat: the OS repository version may be older than the latest Node.js LTS release.

For newer Node.js versions, consider:

- NodeSource,
- `nvm`,
- Docker,
- asdf.

Useful checks:

```bash
node --version
npm --version
```

---

### PostgreSQL Client

The script can install:

```text
postgresql-client
```

This provides tools such as:

```bash
psql
pg_dump
pg_restore
```

It does **not** install the PostgreSQL server.

---

### Redis Tools

The script can install:

```text
redis-tools
```

This provides tools such as:

```bash
redis-cli
```

It does **not** install the Redis server.

---

### Fail2Ban

The script can install:

```text
fail2ban
```

Fail2Ban monitors logs and can ban IPs that repeatedly fail authentication.

It is commonly used to protect SSH from brute-force attempts.

Useful checks:

```bash
systemctl status fail2ban
fail2ban-client status
```

---

### UFW

The script can install:

```text
ufw
```

UFW is a simple firewall frontend.

The script installs UFW but does **not** blindly enable it unless you choose that option.

Before enabling UFW, make sure your SSH port is allowed.

Examples:

```bash
ufw allow OpenSSH
```

or:

```bash
ufw allow 22/tcp
```

For a custom SSH port:

```bash
ufw allow 2222/tcp
```

Check status:

```bash
ufw status verbose
```

---

## Prerequisites

Run the script as root or with sudo:

```bash
sudo ./packages.sh
```

Required:

- Debian or Ubuntu
- `apt-get`
- internet access
- working DNS resolution
- root/sudo privileges

Recommended:

- working SSH access through a sudo-capable user
- recent system snapshot or backup
- UFW/firewall awareness before changing network services

---

## How to Run

Save the script as:

```bash
packages.sh
```

Make it executable:

```bash
chmod +x packages.sh
```

Run it:

```bash
sudo ./packages.sh
```

Then answer the prompts.

---

## Recommended Usage

For a typical Docker-based web server, choose:

- Update apt package lists: **yes**
- Upgrade installed packages: **optional**
- Install common server utilities: **yes**
- Install development/build tools: **optional**
- Install Nginx: **yes**
- Install Docker Engine and Docker Compose plugin: **yes**
- Install Certbot: **yes**, if using HTTPS with Nginx
- Install Node.js/npm: **no**, if your apps run inside Docker
- Install PostgreSQL client: **yes**, if you connect to PostgreSQL
- Install Redis tools: **yes**, if you use Redis
- Install Fail2Ban: **yes**
- Install UFW: **yes**
- Enable/start installed services: **yes**
- Cleanup after installation: **yes**

---

## Typical Post-Install Checks

Check Nginx:

```bash
nginx -t
systemctl status nginx
```

Check Docker:

```bash
docker --version
docker compose version
docker run hello-world
systemctl status docker
```

Check Fail2Ban:

```bash
systemctl status fail2ban
fail2ban-client status
```

Check UFW:

```bash
ufw status verbose
```

Check listening ports:

```bash
ss -tulpen
```

---

## Docker Group Security Warning

The script can add a user to the `docker` group.

This allows the user to run Docker commands without `sudo`.

Example:

```bash
usermod -aG docker username
```

However, membership in the `docker` group is effectively **root-equivalent**.

A user in the `docker` group can often gain full root access to the host.

Only add trusted users.

After adding a user to the `docker` group, the user must log out and back in.

Alternatively:

```bash
newgrp docker
```

---

## Firewall Caveats

Be careful when enabling UFW on a remote server.

Before enabling UFW, allow SSH:

```bash
ufw allow OpenSSH
```

or:

```bash
ufw allow 22/tcp
```

If SSH uses a custom port:

```bash
ufw allow <ssh-port>/tcp
```

Example:

```bash
ufw allow 2222/tcp
```

If you forget to allow SSH before enabling UFW, you may lock yourself out.

For web servers, you commonly also need:

```bash
ufw allow 80/tcp
ufw allow 443/tcp
```

or:

```bash
ufw allow "Nginx Full"
```

---

## Package Upgrade Caveats

Running:

```bash
apt-get upgrade -y
```

can update critical system packages and restart services.

Possible effects:

- SSH may restart.
- Nginx may restart.
- Docker may restart.
- application dependencies may change.
- kernel packages may be upgraded.
- a reboot may be required.

Check if reboot is required:

```bash
test -f /var/run/reboot-required && cat /var/run/reboot-required
```

or:

```bash
ls /var/run/reboot-required
```

---

## Docker Installation Caveats

The script removes old/conflicting Docker-related packages before installing Docker CE:

```text
docker.io
docker-doc
docker-compose
podman-docker
containerd
runc
```

This is recommended by Docker’s official installation process.

However, if you already use distro-provided Docker or Podman compatibility packages, review this before proceeding.

---

## Node.js Caveat

The script installs Node.js from the OS repository.

This may be outdated for modern JavaScript applications.

If your deployment requires a specific Node.js version, consider using:

```text
nvm
NodeSource
Docker
asdf
```

For Docker-based deployments, you may not need Node.js installed on the host at all.

---

## Certbot Caveats

Before using Certbot with Nginx:

- DNS must point to the server.
- Nginx must have a valid server block.
- Ports `80` and `443` should be reachable.
- Firewall/security groups should allow HTTP and HTTPS.

Example:

```bash
certbot --nginx -d example.com -d www.example.com
```

Certificate renewal is usually handled automatically by a systemd timer or cron job.

Check with:

```bash
systemctl list-timers | grep certbot
```

---

## Fail2Ban Caveats

Installing Fail2Ban alone may not fully configure protections for all services.

After installation, check:

```bash
fail2ban-client status
```

On some systems, SSH jail configuration may need adjustment.

Common local configuration file:

```text
/etc/fail2ban/jail.local
```

Do not edit `jail.conf` directly unless you know what you are doing, because package updates may overwrite it.

---

## Common Pitfalls

### 1. Running the script without updating apt

If you skip `apt-get update`, package installation may fail due to stale package lists.

---

### 2. Enabling UFW before allowing SSH

This can lock you out of a remote server.

Always allow SSH first.

---

### 3. Adding an untrusted user to the Docker group

The Docker group is root-equivalent.

Only add trusted users.

---

### 4. Assuming Docker Compose uses `docker-compose`

Modern Docker Compose is usually:

```bash
docker compose
```

with a space.

---

### 5. Installing host Node.js unnecessarily

If you deploy apps with Docker, you may not need Node.js/npm on the host.

---

### 6. Installing Certbot before DNS is ready

Certbot certificate issuance will fail if the domain does not point to the server.

---

### 7. Forgetting to enable/start services

If you choose not to enable services, packages may install successfully but services may not be running.

Check with:

```bash
systemctl status nginx
systemctl status docker
systemctl status fail2ban
```

---

## Security Considerations

### Keep the system updated

Regularly run:

```bash
apt update
apt upgrade
```

For unattended security updates, consider:

```bash
apt install unattended-upgrades
```

---

### Minimize installed packages

Only install what you need.

Every installed service or tool increases maintenance responsibility and potential attack surface.

---

### Secure SSH first

Before exposing web services, make sure SSH is secure:

- disable root SSH login,
- prefer SSH keys,
- use strong passwords if password login is enabled,
- consider Fail2Ban,
- allow only necessary firewall ports.

---

### Expose only required ports
