# Security Policy

## Supported Scope

This repository contains infrastructure and server setup scripts. Treat all changes as potentially high impact.

## Reporting A Vulnerability

Please do not open public issues for security vulnerabilities.

Report vulnerabilities privately through GitHub Security Advisories:

- https://github.com/tngeene/utility-scripts/security/advisories/new

Include:

- affected script and version/commit
- environment details (distro/version)
- reproduction steps
- impact assessment
- suggested mitigation if known

## Response Expectations

- We will acknowledge receipt as soon as possible.
- We will validate and prioritize based on impact.
- We will coordinate disclosure once a fix is available.

## Hardening Guidance

When contributing security-sensitive changes, include:

- explicit rollback guidance
- lockout avoidance notes for SSH/UFW changes
- confirmation prompts for destructive actions
