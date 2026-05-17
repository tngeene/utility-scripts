## Summary

<!-- What changed and why? Keep this concise. -->

## Type Of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactor (no behavior change)
- [ ] Breaking change
- [ ] CI/CD or tooling change
- [ ] Security-related change

## Related Issues

<!-- Example: Closes #123 -->

- Closes #
- Related #

## Scope

- Scripts impacted:
- Docs impacted:
- Platforms validated (for example Ubuntu 22.04, Debian 12):

## How To Test

<!-- Provide exact commands and expected results. -->

1.
2.
3.

## Risk Assessment

- [ ] Low risk
- [ ] Medium risk
- [ ] High risk

### Operational Risk Notes

<!-- Mention lockout risk, service restart impact, or package removal impact. -->

## Checklist

### Code Quality

- [ ] Script uses strict mode where appropriate (set -euo pipefail)
- [ ] Variables are quoted safely
- [ ] Changes are idempotent or intentionally documented as non-idempotent
- [ ] Interactive prompts are clear and safe
- [ ] Error messages are actionable

### Security And Safety

- [ ] No secrets, tokens, private keys, or passwords committed
- [ ] Privilege boundaries are clear (root vs non-root actions)
- [ ] Potentially destructive actions require explicit confirmation
- [ ] SSH and firewall changes include lockout safeguards
- [ ] Docker/group privilege implications are documented when relevant

### Testing And Validation

- [ ] Commands tested on at least one supported distro
- [ ] Happy path tested
- [ ] Failure/rollback path tested where applicable
- [ ] Existing behavior re-validated for unchanged options
- [ ] Manual verification steps included in this PR

### Documentation

- [ ] README/docs updated to reflect behavior changes
- [ ] Examples and command names match actual files in repo
- [ ] Caveats and recovery steps are updated when needed

### Backward Compatibility

- [ ] No breaking changes
- [ ] Breaking changes are clearly explained with migration steps

### Open Source Hygiene

- [ ] Commit messages are clear and scoped
- [ ] PR title is descriptive
- [ ] Reviewer notes added for non-obvious decisions

## Before / After (Optional)

<!-- For UX or output changes, paste short terminal excerpts. -->

## Reviewer Notes

<!-- Anything reviewers should focus on first. -->
