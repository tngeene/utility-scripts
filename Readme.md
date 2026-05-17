# Server Setup Scripts

Small interactive scripts for first-time Linux server setup (Debian/Ubuntu).

## Contents

- `server-setups/user.sh`: Create/configure a sudo user and harden SSH access.
- `server-setups/packages.sh`: Install common server packages (Nginx, Docker, Certbot, UFW, and more).
- `server-setups/user_setup.md`: Full guide and safety notes for `user.sh`.
- `server-setups/packages.md`: Full guide and package notes for `packages.sh`.

## Recommended Order

1. Run `user.sh` first and confirm non-root SSH + sudo works.
2. Run `packages.sh` to install required services and tools.
3. Validate services and firewall before closing your original session.

## Quick Run

```bash
cd server-setups
chmod +x user.sh packages.sh
sudo ./user.sh
sudo ./packages.sh
```

## Safety Notes

- Keep your current SSH session open until login tests pass.
- Do not enable UFW until SSH access is explicitly allowed.
- Treat docker-group membership as root-equivalent access.
- If anything goes wrong, use your provider console/recovery mode.
