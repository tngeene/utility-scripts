# Interactive Sudo User & SSH Hardening Script

This script interactively creates or configures a Linux user with sudo/admin privileges, sets up SSH authentication, optionally configures UFW firewall access, and optionally hardens root SSH login.

It is intended for initial server setup, especially on Debian/Ubuntu-style VPS systems, but it also has partial support for systems using the `wheel` group.

## Quick Start

```bash
cd server-setups
chmod +x user.sh
sudo ./user.sh
```

After the script prompts for testing, open a second terminal and verify SSH login plus sudo before applying root hardening.

---

## What the Script Does

The script can:

- Prompt for a username to create or configure.
- Create the user with a home directory and `/bin/bash` shell if the user does not exist.
- Add the user to the admin group:
  - `sudo` on Debian/Ubuntu systems.
  - `wheel` on RHEL/CentOS/Fedora-style systems.
- Configure authentication using:
  - SSH keys,
  - password login,
  - or both.
- Optionally copy root’s existing `authorized_keys` to the new user.
- Optionally add new SSH public keys interactively.
- Set correct SSH directory permissions.
- Detect the active SSH port from `sshd`.
- Optionally allow the SSH port through UFW.
- Optionally enable SSH password authentication.
- Back up `/etc/ssh/sshd_config` before modifying it.
- Test SSH configuration before restarting SSH.
- Optionally harden root SSH login after confirming the new user works.
- Optionally lock the root password.

---

## What the Script Does **Not** Do Automatically

For safety, the script does **not** automatically:

- Lock the root account.
- Disable root SSH login.
- Expire the new user’s password.
- Copy root’s password hash to the new user.
- Enable UFW without confirmation.
- Require SSH keys if password authentication is selected.

These actions are intentionally interactive to reduce the risk of locking yourself out.

---

## Prerequisites

Run the script as `root` or with equivalent privileges.

Required commands:

- `useradd`
- `usermod`
- `getent`
- `sshd`
- `passwd`
- `systemctl` recommended, but not strictly required
- `ufw` optional

The server should already have OpenSSH server installed and running.

On Debian/Ubuntu:

```bash
apt update
apt install openssh-server sudo
```

Optional firewall:

```bash
apt install ufw
```

---

## How to Run

Save the script, for example:

```bash
nano user.sh
```

Make it executable:

```bash
chmod +x user.sh
```

Run as root:

```bash
./user.sh
```

Or:

```bash
sudo ./user.sh
```

Follow the prompts carefully.

---

## Recommended Safe Workflow

1. Start the script from an existing working SSH session.
2. Create or configure the new sudo user.
3. Choose an authentication method:
   - SSH keys are recommended.
   - Password login is allowed but less secure.
4. If prompted, set a strong password.
5. If using SSH keys, add or copy at least one valid public key.
6. When the script asks you to test login, **open a second terminal**.
7. Test the new user:

   ```bash
   ssh -p <port> <username>@<server-ip>
   ```

8. Test sudo:

   ```bash
   sudo whoami
   ```

   Expected output:

   ```text
   root
   ```

9. Only after confirming the new user works, proceed with root SSH hardening.
10. Keep your original SSH session open until all testing is complete.

---

## Authentication Options

### SSH Key Authentication

Recommended for production servers.

Benefits:

- Stronger protection against brute-force attacks.
- No reusable password sent to the SSH service.
- Works well with root password disabled.

Typical public key format:

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@example
```

Private keys should remain only on your local machine.

---

### Password Authentication

Password SSH login can work, but it is less secure.

If using password authentication:

- Use a long, unique password.
- Consider enabling UFW.
- Consider installing Fail2Ban.
- Disable root SSH login.
- Consider switching to SSH keys later.

The script can optionally set:

```text
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
```

depending on your choices.

---

### Both SSH Keys and Password Login

This is useful during migration or setup.

A common approach is:

1. Enable both temporarily.
2. Confirm SSH key login works.
3. Later disable password authentication.

---

## Root SSH Hardening Options

After confirming the new user can log in and use sudo, the script can configure root SSH access.

Options include:

### `PermitRootLogin prohibit-password`

Disables root password login but may still allow root SSH key login.

This is a moderate hardening option.

### `PermitRootLogin no`

Disables all root SSH login.

This is stricter and generally recommended once a sudo user is confirmed working.

---

## UFW Firewall Notes

The script attempts to detect the active SSH port using:

```bash
sshd -T
```

It can then allow that port through UFW.

Example:

```bash
ufw allow 22/tcp
```

or for a custom port:

```bash
ufw allow 2222/tcp
```

The script does not enable UFW without confirmation.

### Common Firewall Pitfall

If SSH runs on a custom port and that port is not allowed before UFW is enabled, you may lock yourself out.

Always verify the detected SSH port before enabling UFW.

---

## Common Pitfalls

### 1. Closing the original SSH session too early

Keep the original root/admin SSH session open until the new user has been tested.

---

### 2. Choosing SSH-key-only login without adding a key

If password authentication is disabled and no valid key is installed, login will fail.

---

### 3. Locking the user password when sudo requires a password

If the new user’s password is locked, SSH key login may still work, but `sudo` may fail unless passwordless sudo is configured.

---

### 4. Enabling password authentication but not setting a password

Password SSH login requires the user to have a usable password.

---

### 5. Hardening root before testing the new user

Do not disable root SSH login or lock the root password until the new user can:

```bash
ssh
```

and:

```bash
sudo whoami
```

successfully.

---

### 6. Incorrect SSH service name

Some systems use:

```bash
ssh
```

Others use:

```bash
sshd
```

The script tries to detect this automatically, but if detection fails, you may need to restart SSH manually.

---

### 7. SSH config includes external files

Some systems use:

```text
Include /etc/ssh/sshd_config.d/*.conf
```

This script now detects that include pattern and writes managed directives to:

```text
/etc/ssh/sshd_config.d/99-user-hardening.conf
```

Otherwise, it writes directly to:

```text
/etc/ssh/sshd_config
```

Settings in included files may override or conflict with `/etc/ssh/sshd_config`.

If results are unexpected, inspect:

```bash
sshd -T
```

and:

```bash
ls -la /etc/ssh/sshd_config.d/
```

---

### 8. Cloud provider login behavior

Some VPS/cloud images disable password authentication or root login by default.

Provider-specific tools, cloud-init, or metadata-based SSH key injection may affect SSH behavior.

---

## Recovery Tips

If you lose SSH access, use your hosting provider’s:

- web console,
- serial console,
- rescue mode,
- recovery ISO,
- snapshot rollback,
- or disk attach/recovery feature.

Useful recovery commands from console:

```bash
passwd <username>
usermod -aG sudo <username>
sshd -t
systemctl restart ssh || systemctl restart sshd
ufw status verbose
ufw disable
```

To unlock or reset root:

```bash
passwd root
```

---

## Security Considerations

### Prefer SSH keys over passwords

For internet-facing servers, SSH keys are generally safer than password authentication.

Recommended production posture:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Only apply this after confirming SSH key login works for a sudo user.

---

### Use strong passwords

If password authentication is enabled, use a long, unique password.

Avoid passwords reused from other services.

---

### Consider Fail2Ban

For password SSH login, [Fail2Ban](https://github.com/fail2ban/fail2ban) can reduce brute-force risk.

Debian/Ubuntu example:

```bash
apt install fail2ban
systemctl enable --now fail2ban
```

---

### Keep sudo access limited

Only trusted users should be in the `sudo` or `wheel` group.

Check with:

```bash
groups <username>
```

---

### Back up SSH configuration

The script creates a backup of:

```text
/etc/ssh/sshd_config
```

before modifying it.

Example backup name:

```text
/etc/ssh/sshd_config.bak.2026-05-17-215000
```

---

### Delete the script after running?

Usually, yes.

If the script contains no passwords or private keys, keeping it is not immediately dangerous. However, deleting it is still a good practice because:

- It reduces clutter.
- It avoids accidental re-running.
- It prevents future users from seeing setup assumptions.
- It reduces the chance of exposing pasted public keys or comments.

Delete it with:

```bash
rm -f user.sh
```

If you added sensitive information to the script, securely remove it and rotate any exposed credentials.

Note: Public SSH keys are not secret, but private keys and passwords are.

---

## Recommended Final Server State

For a hardened production server, aim for:

```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

With:

- a tested sudo user,
- valid SSH key login,
- UFW allowing the correct SSH port,
- strong package updates,
- and optional Fail2Ban.

Do not apply these stricter settings until you have verified that non-root SSH login and sudo both work.
