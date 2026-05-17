#!/bin/bash
set -euo pipefail

###############################################################################
# Interactive Web Server Package Setup Script
#
# Supported systems:
#   - Debian
#   - Ubuntu
#
# What this script can do:
#   1. Update apt package lists.
#   2. Upgrade installed packages.
#   3. Install common server/web packages.
#   4. Install Nginx.
#   5. Install Docker from Docker's official repository.
#   6. Install Docker Compose plugin.
#   7. Add a user to the docker group.
#   8. Enable and start selected services.
#   9. Clean unused packages.
#
# Run as root:
#   sudo ./packages.sh
###############################################################################

########################
### HELPER FUNCTIONS ###
########################

info() {
    echo
    echo "INFO: $*"
}

warn() {
    echo
    echo "WARNING: $*" >&2
}

error() {
    echo
    echo "ERROR: $*" >&2
    exit 1
}

ask_yes_no() {
    # Returns 0 for yes, 1 for no.
    local prompt="$1"
    local answer

    while true; do
        read -r -p "${prompt} [y/n]: " answer
        case "$answer" in
            y|Y|yes|YES|Yes)
                return 0
                ;;
            n|N|no|NO|No)
                return 1
                ;;
            *)
                echo "Please answer y or n."
                ;;
        esac
    done
}

confirm_yes() {
    # Requires exact YES.
    local prompt="$1"
    local answer

    read -r -p "${prompt} Type YES to continue: " answer

    if [ "$answer" = "YES" ]; then
        return 0
    fi

    return 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

can_manage_services() {
    # Returns success only when systemctl is present and operational.
    command_exists systemctl && systemctl list-unit-files >/dev/null 2>&1
}

enable_and_restart_service() {
    local service_name="$1"

    if [ "$SYSTEMCTL_AVAILABLE" = true ]; then
        systemctl enable "$service_name"
        systemctl restart "$service_name"
    else
        warn "systemctl is unavailable. Could not enable/restart service '${service_name}'."
    fi
}

print_service_status() {
    local service_name="$1"

    if [ "$SYSTEMCTL_AVAILABLE" = true ]; then
        systemctl --no-pager status "$service_name" || true
    else
        warn "systemctl is unavailable. Could not show status for service '${service_name}'."
    fi
}

install_packages() {
    if [ "$#" -eq 0 ]; then
        return 0
    fi

    info "Installing packages: $*"
    apt-get install -y "$@"
}

#####################
### SAFETY CHECKS ###
#####################

if [ "$EUID" -ne 0 ]; then
    error "Please run this script as root, for example: sudo ./packages.sh"
fi

if ! command_exists apt-get; then
    error "apt-get was not found. This script only supports Debian/Ubuntu-style systems."
fi

if [ ! -f /etc/os-release ]; then
    error "/etc/os-release not found. Cannot determine OS."
fi

# shellcheck disable=SC1091
source /etc/os-release

OS_ID="${ID:-unknown}"
OS_CODENAME="${VERSION_CODENAME:-}"

case "$OS_ID" in
    ubuntu|debian)
        info "Detected supported OS: ${PRETTY_NAME:-$OS_ID}"
        ;;
    *)
        warn "Detected OS: ${PRETTY_NAME:-$OS_ID}"
        warn "This script is intended for Debian/Ubuntu systems."
        if ! confirm_yes "Continue anyway?"; then
            error "Aborted."
        fi
        ;;
esac

if [ -z "$OS_CODENAME" ]; then
    if command_exists lsb_release; then
        OS_CODENAME="$(lsb_release -cs)"
    fi
fi

if [ -z "$OS_CODENAME" ]; then
    error "Could not determine OS codename, for example jammy, noble, bookworm, etc."
fi

ARCHITECTURE="$(dpkg --print-architecture)"
SYSTEMCTL_AVAILABLE=false

if can_manage_services; then
    SYSTEMCTL_AVAILABLE=true
else
    warn "systemctl is unavailable or not operational. Service enable/restart steps will be skipped."
fi

info "OS codename: ${OS_CODENAME}"
info "Architecture: ${ARCHITECTURE}"

###########################
### INTERACTIVE OPTIONS ###
###########################

echo
echo "Interactive Web Server Package Setup"
echo "===================================="
echo

UPDATE_APT=false
UPGRADE_PACKAGES=false
INSTALL_COMMON=false
INSTALL_DEV_TOOLS=false
INSTALL_NGINX=false
INSTALL_DOCKER=false
INSTALL_CERTBOT=false
INSTALL_NODEJS=false
INSTALL_POSTGRES_CLIENT=false
INSTALL_REDIS_TOOLS=false
INSTALL_FAIL2BAN=false
INSTALL_UFW=false
ENABLE_SERVICES=false
CLEANUP_AFTER=false

if ask_yes_no "Update apt package lists?"; then
    UPDATE_APT=true
fi

if ask_yes_no "Upgrade installed packages?"; then
    UPGRADE_PACKAGES=true
fi

if ask_yes_no "Install common server utilities?"; then
    INSTALL_COMMON=true
fi

if ask_yes_no "Install development/build tools?"; then
    INSTALL_DEV_TOOLS=true
fi

if ask_yes_no "Install Nginx?"; then
    INSTALL_NGINX=true
fi

if ask_yes_no "Install Docker Engine and Docker Compose plugin?"; then
    INSTALL_DOCKER=true
fi

if ask_yes_no "Install Certbot for Let's Encrypt SSL certificates?"; then
    INSTALL_CERTBOT=true
fi

if ask_yes_no "Install Node.js/npm from OS repository?"; then
    INSTALL_NODEJS=true
fi

if ask_yes_no "Install PostgreSQL client tools?"; then
    INSTALL_POSTGRES_CLIENT=true
fi

if ask_yes_no "Install Redis CLI/tools?"; then
    INSTALL_REDIS_TOOLS=true
fi

if ask_yes_no "Install Fail2Ban?"; then
    INSTALL_FAIL2BAN=true
fi

if ask_yes_no "Install UFW firewall?"; then
    INSTALL_UFW=true
fi

if ask_yes_no "Enable/start installed services where applicable?"; then
    ENABLE_SERVICES=true
fi

if ask_yes_no "Run apt autoremove/autoclean after installation?"; then
    CLEANUP_AFTER=true
fi

#######################
### PACKAGE UPDATE ####
#######################

if [ "$UPDATE_APT" = true ]; then
    info "Updating apt package lists."
    apt-get update
else
    warn "Skipping apt update. Package installation may fail if package lists are stale."
fi

#########################
### PACKAGE UPGRADE #####
#########################

if [ "$UPGRADE_PACKAGES" = true ]; then
    echo
    warn "Upgrading packages can restart services or change system behavior."
    if confirm_yes "Proceed with apt upgrade?"; then
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    else
        warn "Skipping package upgrade."
    fi
fi

################################
### COMMON SERVER UTILITIES ####
################################

COMMON_PACKAGES=(
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
)

if [ "$INSTALL_COMMON" = true ]; then
    install_packages "${COMMON_PACKAGES[@]}"
fi

############################
### DEVELOPMENT TOOLS ######
############################

DEV_PACKAGES=(
    build-essential
    make
    gcc
    g++
    pkg-config
    python3
    python3-pip
    python3-venv
)

if [ "$INSTALL_DEV_TOOLS" = true ]; then
    install_packages "${DEV_PACKAGES[@]}"
fi

###############
### NGINX #####
###############

if [ "$INSTALL_NGINX" = true ]; then
    install_packages nginx

    if [ "$ENABLE_SERVICES" = true ]; then
        info "Enabling and starting Nginx."
        enable_and_restart_service nginx
    fi
fi

##############################
### CERTBOT / LET'S ENCRYPT ##
##############################

if [ "$INSTALL_CERTBOT" = true ]; then
    install_packages certbot python3-certbot-nginx
fi

#########################
### NODE.JS AND NPM #####
#########################

if [ "$INSTALL_NODEJS" = true ]; then
    warn "Installing Node.js/npm from the OS repository."
    warn "This may not be the latest Node.js version."
    warn "For newer versions, consider NodeSource, nvm, or Docker."

    install_packages nodejs npm

    echo
    info "Node.js version:"
    node --version || true

    info "npm version:"
    npm --version || true
fi

###########################
### POSTGRESQL CLIENT #####
###########################

if [ "$INSTALL_POSTGRES_CLIENT" = true ]; then
    install_packages postgresql-client
fi

#####################
### REDIS TOOLS #####
#####################

if [ "$INSTALL_REDIS_TOOLS" = true ]; then
    install_packages redis-tools
fi

################
### FAIL2BAN ###
################

if [ "$INSTALL_FAIL2BAN" = true ]; then
    install_packages fail2ban

    if [ "$ENABLE_SERVICES" = true ]; then
        info "Enabling and starting Fail2Ban."
        enable_and_restart_service fail2ban
    fi
fi

###########
### UFW ###
###########

if [ "$INSTALL_UFW" = true ]; then
    install_packages ufw

    warn "This script installs UFW but does not enable it automatically."
    warn "Before enabling UFW, make sure your SSH port is allowed."
    warn "Example:"
    warn "  ufw allow OpenSSH"
    warn "or:"
    warn "  ufw allow 22/tcp"
fi

##############
### DOCKER ###
##############

if [ "$INSTALL_DOCKER" = true ]; then
    info "Installing Docker from Docker's official apt repository."

    # Remove old/conflicting Docker packages if present.
    warn "Removing old Docker-related packages if installed."
    warn "This may remove container runtimes currently used by existing workloads."

    if confirm_yes "Proceed with removal of conflicting Docker/container packages?"; then
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
            apt-get remove -y "$pkg" >/dev/null 2>&1 || true
        done
    else
        warn "Skipping conflicting package removal. Docker installation may fail if conflicts remain."
    fi

    # Required packages for Docker repository.
    install_packages ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings

    DOCKER_KEYRING="/etc/apt/keyrings/docker.asc"

    info "Adding Docker GPG key."
    curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" -o "$DOCKER_KEYRING"
    chmod a+r "$DOCKER_KEYRING"

    DOCKER_SOURCE_FILE="/etc/apt/sources.list.d/docker.list"

    info "Adding Docker apt repository."
    echo \
      "deb [arch=${ARCHITECTURE} signed-by=${DOCKER_KEYRING}] https://download.docker.com/linux/${OS_ID} ${OS_CODENAME} stable" \
      > "$DOCKER_SOURCE_FILE"

    info "Updating apt package lists after adding Docker repository."
    apt-get update

    install_packages \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    if [ "$ENABLE_SERVICES" = true ]; then
        info "Enabling and starting Docker."
        enable_and_restart_service docker
    fi

    echo
    info "Docker version:"
    docker --version || true

    info "Docker Compose version:"
    docker compose version || true

    echo
    if ask_yes_no "Add a user to the docker group?"; then
        DOCKER_USER=""
        CURRENT_USER=""

        if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ] && id "${SUDO_USER}" >/dev/null 2>&1; then
            CURRENT_USER="${SUDO_USER}"
        fi

        if [ -n "$CURRENT_USER" ]; then
            if ask_yes_no "Add current user '${CURRENT_USER}' to docker group?"; then
                DOCKER_USER="$CURRENT_USER"
            fi
        else
            warn "Could not detect a non-root invoking user automatically."
        fi

        if [ -z "$DOCKER_USER" ]; then
            while true; do
                read -r -p "Enter username to add to docker group: " DOCKER_USER

                if id "$DOCKER_USER" >/dev/null 2>&1; then
                    break
                fi

                echo "User '${DOCKER_USER}' does not exist. Try again."
            done
        fi

        info "Adding '${DOCKER_USER}' to docker group."
        usermod -aG docker "$DOCKER_USER"

        warn "The user '${DOCKER_USER}' must log out and back in for docker group membership to apply."
        warn "Alternatively, they can run: newgrp docker"
        warn "Members of the docker group effectively have root-equivalent privileges."
    fi
fi

###############
### CLEANUP ###
###############

if [ "$CLEANUP_AFTER" = true ]; then
    info "Removing unused packages."
    apt-get autoremove -y

    info "Cleaning apt cache."
    apt-get autoclean -y
fi

###############
### SUMMARY ###
###############

echo
echo "Setup complete."
echo "==============="
echo

echo "Selected actions:"
echo "  Apt update:                 ${UPDATE_APT}"
echo "  Package upgrade:            ${UPGRADE_PACKAGES}"
echo "  Common utilities:           ${INSTALL_COMMON}"
echo "  Development tools:          ${INSTALL_DEV_TOOLS}"
echo "  Nginx:                      ${INSTALL_NGINX}"
echo "  Docker + Compose plugin:    ${INSTALL_DOCKER}"
echo "  Certbot:                    ${INSTALL_CERTBOT}"
echo "  Node.js/npm:                ${INSTALL_NODEJS}"
echo "  PostgreSQL client:          ${INSTALL_POSTGRES_CLIENT}"
echo "  Redis tools:                ${INSTALL_REDIS_TOOLS}"
echo "  Fail2Ban:                   ${INSTALL_FAIL2BAN}"
echo "  UFW:                        ${INSTALL_UFW}"
echo "  Enable/start services:      ${ENABLE_SERVICES}"
echo "  Cleanup:                    ${CLEANUP_AFTER}"
echo

if [ "$INSTALL_NGINX" = true ]; then
    echo "Nginx status:"
    print_service_status nginx
    echo
fi

if [ "$INSTALL_DOCKER" = true ]; then
    echo "Docker status:"
    print_service_status docker
    echo
fi

echo "Recommended next checks:"
echo
echo "  nginx -t                    # Test Nginx config, if installed"
echo "  systemctl status nginx      # Check Nginx status"
echo "  docker run hello-world      # Test Docker, if installed"
echo "  docker compose version      # Check Docker Compose plugin"
echo "  ufw status verbose          # Check firewall, if UFW installed"
echo
