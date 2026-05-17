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

## Download With curl

Download directly from GitHub into `/tmp` and run:

Latest from `main`:

```bash
curl -L https://raw.githubusercontent.com/tngeene/utility-scripts/main/server-setups/user.sh -o /tmp/user.sh
chmod +x /tmp/user.sh
sudo /tmp/user.sh
```

<img width="641" height="599" alt="Screenshot 2026-05-17 at 21 48 03" src="https://github.com/user-attachments/assets/2eed70f9-4ce4-48e9-87bf-8e6b8faed379" />


```bash
curl -L https://raw.githubusercontent.com/tngeene/utility-scripts/main/server-setups/packages.sh -o /tmp/packages.sh
chmod +x /tmp/packages.sh
sudo /tmp/packages.sh
```

<img width="855" height="768" alt="Screenshot 2026-05-17 at 22 25 05" src="https://github.com/user-attachments/assets/e1e16bf1-3715-4040-a706-75eef0279492" />


Pinned commit (reproducible):

```bash
curl -L https://raw.githubusercontent.com/tngeene/utility-scripts/597e48b37018d69219f3204a47f3f386930d6a48/server-setups/user.sh -o /tmp/user.sh
chmod +x /tmp/user.sh
sudo /tmp/user.sh
```

```bash
curl -L https://raw.githubusercontent.com/tngeene/utility-scripts/597e48b37018d69219f3204a47f3f386930d6a48/server-setups/packages.sh -o /tmp/packages.sh
chmod +x /tmp/packages.sh
sudo /tmp/packages.sh
```

Use `main` for newest updates and pinned commit URLs for stable/repeatable runs.

## Install Pre-commit Hooks

Install and enable hooks locally before committing:

```bash
python3 -m pip install --user pre-commit
pre-commit install
pre-commit run --all-files
```

## Safety Notes

- Keep your current SSH session open until login tests pass.
- Do not enable UFW until SSH access is explicitly allowed.
- Treat docker-group membership as root-equivalent access.
- If anything goes wrong, use your provider console/recovery mode.

## Contributing

- See `CONTRIBUTING.md` for contribution expectations.
- Pull requests use `.github/PULL_REQUEST_TEMPLATE.md`.
- Issues use `.github/ISSUE_TEMPLATE/` forms.
- Security issues should be reported privately via GitHub Security Advisories.
