#!/bin/bash
set -euo pipefail

###############################################################################
# Interactive safe sudo-user bootstrap and SSH hardening script
#
# What this script can do:
#   1. Ask for a username interactively.
#   2. Create the user if missing.
#   3. Add the user to the sudo/wheel group.
#   4. Set a password interactively, lock password login, or leave unchanged.
#   5. Optionally configure SSH keys.
#   6. Optionally enable SSH password authentication.
#   7. Optionally configure UFW safely for the detected SSH port.
#   8. Ask you to test the new user before changing root SSH access.
#   9. Optionally disable root SSH login or root password login.
#  10. Optionally lock the root password.
#
# Notes:
#   - SSH keys are recommended, but not mandatory if password auth is enabled.
#   - Password SSH login is less secure than key login.
#   - Keep your current SSH session open while testing.
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

confirm_yes() {
    local prompt="$1"
    local answer

    read -r -p "${prompt} Type YES to continue: " answer

    if [ "$answer" = "YES" ]; then
        return 0
    fi

    return 1
}

ask_yes_no() {
    # Returns 0 for yes, 1 for no.
    local prompt="$1"
    local answer

    while true; do
        read -r -p "${prompt} [y/n]: " answer
        case "$answer" in
            y | Y | yes | YES | Yes)
                return 0
                ;;
            n | N | no | NO | No)
                return 1
                ;;
            *)
                echo "Please answer y or n."
                ;;
        esac
    done
}

set_or_append_sshd_config() {
    # Usage:
    #   set_or_append_sshd_config "Directive" "value"
    #
    # This edits the selected SSH config target file by replacing an existing directive,
    # even if commented, or appending it if not found.
    local directive="$1"
    local value="$2"
    local target_file="${SSH_CONFIG_TARGET:-/etc/ssh/sshd_config}"

    if grep -qE "^[#[:space:]]*${directive}[[:space:]]+" "$target_file"; then
        sed -i "s|^[#[:space:]]*${directive}[[:space:]].*|${directive} ${value}|" "$target_file"
    else
        echo "${directive} ${value}" >>"$target_file"
    fi
}

#####################
### SAFETY CHECKS ###
#####################

if [ "$EUID" -ne 0 ]; then
    error "Please run this script as root."
fi

command -v useradd >/dev/null 2>&1 || error "useradd command not found."
command -v usermod >/dev/null 2>&1 || error "usermod command not found."
command -v getent >/dev/null 2>&1 || error "getent command not found."
command -v sshd >/dev/null 2>&1 || error "sshd command not found."

SSH_CONFIG_TARGET="/etc/ssh/sshd_config"

if grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config &&
    [ -d /etc/ssh/sshd_config.d ]; then
    SSH_CONFIG_TARGET="/etc/ssh/sshd_config.d/99-user-hardening.conf"
    if [ ! -f "$SSH_CONFIG_TARGET" ]; then
        info "Detected include-based SSH config. Creating ${SSH_CONFIG_TARGET}."
        install -m 0644 /dev/null "$SSH_CONFIG_TARGET"
    else
        info "Detected include-based SSH config. Using ${SSH_CONFIG_TARGET}."
    fi
else
    info "Using /etc/ssh/sshd_config for SSH directives."
fi

###########################
### INTERACTIVE OPTIONS ###
###########################

echo
echo "Interactive sudo user setup"
echo "==========================="

while true; do
    read -r -p "Enter the username to create/configure [sammy]: " USERNAME
    USERNAME="${USERNAME:-sammy}"

    if [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
        break
    fi

    echo "Invalid username. Use lowercase letters, numbers, underscore, or hyphen."
    echo "The username must start with a lowercase letter or underscore."
done

echo
echo "Authentication options"
echo "======================"
echo
echo "You can use:"
echo "  1) SSH key authentication, recommended"
echo "  2) Password authentication"
echo "  3) Both SSH key and password authentication"
echo

SETUP_SSH_KEYS=false
ENABLE_PASSWORD_AUTH=false

while true; do
    read -r -p "Choose authentication mode [1/2/3]: " auth_choice

    case "$auth_choice" in
        1)
            SETUP_SSH_KEYS=true
            ENABLE_PASSWORD_AUTH=false
            break
            ;;
        2)
            SETUP_SSH_KEYS=false
            ENABLE_PASSWORD_AUTH=true
            break
            ;;
        3)
            SETUP_SSH_KEYS=true
            ENABLE_PASSWORD_AUTH=true
            break
            ;;
        *)
            echo "Please choose 1, 2, or 3."
            ;;
    esac
done

CONFIGURE_UFW=false
if ask_yes_no "Do you want to configure UFW firewall for SSH?"; then
    CONFIGURE_UFW=true
fi

OFFER_ROOT_SSH_HARDENING=false
if ask_yes_no "Do you want to harden root SSH login after testing the new user?"; then
    OFFER_ROOT_SSH_HARDENING=true
fi

#####################
### CREATE USER #####
#####################

if id "$USERNAME" >/dev/null 2>&1; then
    info "User '${USERNAME}' already exists. Skipping user creation."
else
    info "Creating user '${USERNAME}' with home directory and bash shell."
    useradd --create-home --shell /bin/bash "$USERNAME"
fi

# Add the user to the appropriate admin group.
if getent group sudo >/dev/null 2>&1; then
    info "Adding '${USERNAME}' to sudo group."
    usermod -aG sudo "$USERNAME"
    ADMIN_GROUP="sudo"
elif getent group wheel >/dev/null 2>&1; then
    warn "Group 'sudo' not found. Adding '${USERNAME}' to 'wheel' group instead."
    usermod -aG wheel "$USERNAME"
    ADMIN_GROUP="wheel"
else
    error "Neither 'sudo' nor 'wheel' group exists. Cannot grant sudo privileges safely."
fi

home_directory="$(getent passwd "$USERNAME" | cut -d: -f6)"

if [ -z "$home_directory" ]; then
    error "Could not determine home directory for '${USERNAME}'."
fi

if [ ! -d "$home_directory" ]; then
    info "Home directory '${home_directory}' does not exist. Creating it."
    mkdir -p "$home_directory"
    chown "$USERNAME:$USERNAME" "$home_directory"
fi

#########################
### PASSWORD HANDLING ###
#########################

echo
echo "Password setup for '${USERNAME}'"
echo "==============================="
echo

if [ "$ENABLE_PASSWORD_AUTH" = true ]; then
    echo "You selected password authentication."
    echo "A usable password is required for SSH password login and usually for sudo."
    echo
    info "Setting password for '${USERNAME}'."
    passwd "$USERNAME"
else
    echo "You selected SSH-key-only authentication."
    echo
    echo "For sudo, many systems still require the user's password."
    echo "You may still want to set a password for sudo, even if SSH password login is disabled."
    echo

    if ask_yes_no "Do you want to set a local/sudo password for '${USERNAME}'?"; then
        passwd "$USERNAME"
    else
        warn "No password set for '${USERNAME}'."
        warn "If sudo requires a password, sudo may not work for this user."
        if ask_yes_no "Do you want to lock '${USERNAME}' password login?"; then
            passwd --lock "$USERNAME"
        fi
    fi
fi

#####################
### SSH KEY SETUP ###
#####################

if [ "$SETUP_SSH_KEYS" = true ]; then
    info "Setting up SSH keys for '${USERNAME}'."

    mkdir -p "${home_directory}/.ssh"
    touch "${home_directory}/.ssh/authorized_keys"

    if [ -f /root/.ssh/authorized_keys ]; then
        if ask_yes_no "Copy root's existing authorized_keys to '${USERNAME}'?"; then
            info "Copying root's authorized_keys."
            cat /root/.ssh/authorized_keys >>"${home_directory}/.ssh/authorized_keys"
        fi
    else
        warn "/root/.ssh/authorized_keys does not exist, so there are no root keys to copy."
    fi

    echo
    echo "You can now add one or more public SSH keys."
    echo "Paste a public key, then press Enter."
    echo "Leave blank and press Enter when done."
    echo
    echo "Example:"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIexample user@example"
    echo

    while true; do
        read -r -p "Public SSH key: " pub_key

        if [ -z "$pub_key" ]; then
            break
        fi

        if [[ "$pub_key" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)[[:space:]]+ ]]; then
            echo "$pub_key" >>"${home_directory}/.ssh/authorized_keys"
            info "Key added."
        else
            warn "That does not look like a standard SSH public key."
            if ask_yes_no "Add it anyway?"; then
                echo "$pub_key" >>"${home_directory}/.ssh/authorized_keys"
                info "Key added."
            else
                warn "Key skipped."
            fi
        fi
    done

    # Remove duplicate keys and blank lines.
    sort -u "${home_directory}/.ssh/authorized_keys" -o "${home_directory}/.ssh/authorized_keys"
    sed -i '/^[[:space:]]*$/d' "${home_directory}/.ssh/authorized_keys"

    chown -R "${USERNAME}:${USERNAME}" "${home_directory}/.ssh"
    chmod 700 "${home_directory}/.ssh"
    chmod 600 "${home_directory}/.ssh/authorized_keys"

    if [ ! -s "${home_directory}/.ssh/authorized_keys" ]; then
        warn "No SSH keys were added for '${USERNAME}'."
        if [ "$ENABLE_PASSWORD_AUTH" = false ]; then
            error "SSH-key-only authentication was selected, but no SSH keys were configured."
        fi
    fi
else
    info "SSH key setup skipped because password authentication was selected without key setup."
fi

#############################
### DETECT SSH SERVICE ######
#############################

if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files | grep -q '^ssh.service'; then
        SSH_SERVICE="ssh"
    elif systemctl list-unit-files | grep -q '^sshd.service'; then
        SSH_SERVICE="sshd"
    else
        SSH_SERVICE=""
        warn "Could not determine SSH systemd service name automatically."
    fi
else
    SSH_SERVICE=""
    warn "systemctl not found. SSH restart may need to be handled manually."
fi

if [ -n "$SSH_SERVICE" ]; then
    info "Detected SSH service: ${SSH_SERVICE}"
fi

#######################
### DETECT SSH PORT ###
#######################

SSH_PORT="$(sshd -T 2>/dev/null | awk '/^port / {print $2; exit}')"

if [ -z "$SSH_PORT" ]; then
    SSH_PORT="22"
    warn "Could not detect SSH port. Falling back to port 22."
fi

info "Detected SSH port: ${SSH_PORT}"

###########################
### SSH CONFIG BACKUP #####
###########################

info "Testing current SSH configuration."

if ! sshd -t; then
    error "Current SSH configuration is invalid. Refusing to continue."
fi

backup_file="${SSH_CONFIG_TARGET}.bak.$(date +%F-%H%M%S)"

info "Backing up ${SSH_CONFIG_TARGET} to ${backup_file}."
cp "$SSH_CONFIG_TARGET" "$backup_file"

#################################
### PASSWORD AUTH SSH CONFIG ####
#################################

if [ "$ENABLE_PASSWORD_AUTH" = true ]; then
    warn "You selected SSH password authentication."
    warn "This is convenient but less secure than SSH key authentication."

    if confirm_yes "Enable SSH password authentication in sshd_config?"; then
        info "Enabling SSH password authentication."

        set_or_append_sshd_config "PasswordAuthentication" "yes"
        set_or_append_sshd_config "KbdInteractiveAuthentication" "yes"
        set_or_append_sshd_config "UsePAM" "yes"

        info "Testing SSH configuration after password-auth changes."

        if sshd -t; then
            if [ -n "$SSH_SERVICE" ]; then
                info "Restarting SSH service: ${SSH_SERVICE}"
                systemctl restart "$SSH_SERVICE"
            else
                warn "SSH config is valid, but SSH service was not restarted automatically."
                warn "Restart SSH manually."
            fi
        else
            warn "SSH configuration became invalid. Restoring backup."
            cp "$backup_file" "$SSH_CONFIG_TARGET"

            if [ -n "$SSH_SERVICE" ]; then
                systemctl restart "$SSH_SERVICE" || true
            fi

            error "Password authentication configuration failed. Backup restored."
        fi
    else
        warn "PasswordAuthentication was not changed."
        warn "If it is disabled in SSH config, password login may still fail."
    fi
fi

####################
### FIREWALL UFW ###
####################

if [ "$CONFIGURE_UFW" = true ]; then
    if command -v ufw >/dev/null 2>&1; then
        info "Allowing detected SSH port ${SSH_PORT}/tcp through UFW."
        ufw allow "${SSH_PORT}/tcp"

        echo
        ufw status verbose || true
        echo

        if confirm_yes "Do you want to enable UFW now?"; then
            info "Enabling UFW."
            ufw --force enable
        else
            warn "Skipping UFW enable."
        fi
    else
        warn "UFW is not installed. Skipping firewall configuration."
    fi
else
    info "Skipping UFW configuration."
fi

################################
### MANUAL LOGIN TEST PROMPT ###
################################

cat <<EOF

Now test the new user from ANOTHER terminal.

Run:

    ssh -p ${SSH_PORT} ${USERNAME}@YOUR_SERVER_IP

If your server IP is 91.92.136.118, run:

    ssh -p ${SSH_PORT} ${USERNAME}@91.92.136.118

Then test sudo:

    sudo whoami

Expected output:

    root

Important:
  - Keep this current session open.
  - Do not continue until the new login works.
  - If using password authentication, make sure password login succeeds.
  - If using SSH keys, make sure key login succeeds.

EOF

###########################
### ROOT SSH HARDENING ####
###########################

if [ "$OFFER_ROOT_SSH_HARDENING" = true ]; then
    if confirm_yes "Have you confirmed that '${USERNAME}' can log in over SSH and run sudo?"; then
        echo
        echo "Root SSH hardening options"
        echo "=========================="
        echo
        echo "1) Disable only root password login: PermitRootLogin prohibit-password"
        echo "   Root SSH key login may still work."
        echo
        echo "2) Disable all root SSH login: PermitRootLogin no"
        echo "   Root cannot log in over SSH at all."
        echo
        echo "3) Skip root SSH changes"
        echo

        while true; do
            read -r -p "Choose 1, 2, or 3: " root_choice

            case "$root_choice" in
                1)
                    info "Setting PermitRootLogin prohibit-password."
                    set_or_append_sshd_config "PermitRootLogin" "prohibit-password"
                    break
                    ;;
                2)
                    info "Setting PermitRootLogin no."
                    set_or_append_sshd_config "PermitRootLogin" "no"
                    break
                    ;;
                3)
                    warn "Skipping root SSH changes."
                    break
                    ;;
                *)
                    echo "Please choose 1, 2, or 3."
                    ;;
            esac
        done

        if [ "$root_choice" != "3" ]; then
            # Keep public key authentication enabled if keys are being used.
            if [ "$SETUP_SSH_KEYS" = true ]; then
                set_or_append_sshd_config "PubkeyAuthentication" "yes"
            fi

            info "Testing SSH configuration after root SSH changes."

            if sshd -t; then
                if [ -n "$SSH_SERVICE" ]; then
                    info "Restarting SSH service: ${SSH_SERVICE}"
                    systemctl restart "$SSH_SERVICE"
                else
                    warn "SSH config is valid, but SSH service was not restarted automatically."
                    warn "Restart SSH manually."
                fi
            else
                warn "SSH configuration became invalid. Restoring backup."
                cp "$backup_file" "$SSH_CONFIG_TARGET"

                if [ -n "$SSH_SERVICE" ]; then
                    systemctl restart "$SSH_SERVICE" || true
                fi

                error "Root SSH hardening failed. Backup restored."
            fi

            echo
            if ask_yes_no "Do you also want to lock the root password?"; then
                warn "Only do this if your sudo user definitely works."
                if confirm_yes "Really lock the root password?"; then
                    passwd --lock root
                    info "Root password locked."
                else
                    warn "Root password was not locked."
                fi
            else
                warn "Root password was not locked."
            fi
        fi
    else
        warn "Skipping root SSH hardening because you did not confirm the new user works."
    fi
else
    info "Root SSH hardening was not requested."
fi

################
### SUMMARY ####
################

cat <<EOF

Done.

Summary:
  User:                 ${USERNAME}
  Admin group:          ${ADMIN_GROUP}
  Home directory:       ${home_directory}
  SSH port:             ${SSH_PORT}
    SSH config target:    ${SSH_CONFIG_TARGET}
  SSH config backup:    ${backup_file}
  SSH key setup:        ${SETUP_SSH_KEYS}
  Password SSH auth:    ${ENABLE_PASSWORD_AUTH}

Recommended login test:

    ssh -p ${SSH_PORT} ${USERNAME}@YOUR_SERVER_IP

EOF
