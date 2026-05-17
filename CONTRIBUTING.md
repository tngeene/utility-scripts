# Contributing

Thanks for contributing.

## Development Principles

- Prefer safe defaults for server operations.
- Avoid hidden destructive behavior.
- Keep scripts understandable and auditable.
- Document operational risk clearly (SSH, firewall, package removal, service restarts).

## Local Workflow

1. Create a branch from main.
2. Make focused changes.
3. Update docs with any behavior change.
4. Open a pull request using the PR template.

## Script Quality Expectations

- Use clear prompts for interactive scripts.
- Validate prerequisites early.
- Keep rollback paths explicit when changing SSH or firewall settings.
- Quote shell variables and avoid unsafe expansions.

## Recommended Checks

Run what is available in your environment:

- shellcheck for static shell analysis
- shfmt for formatting consistency
- manual dry-run style walkthrough of interactive prompts
- test on at least one supported distro

## Pull Requests

Please include:

- What changed and why
- How you tested it
- Any risk or rollback notes
- Related issue references

For high-risk changes (for example SSH login, UFW, Docker runtime replacement), include explicit recovery guidance in the PR body.
