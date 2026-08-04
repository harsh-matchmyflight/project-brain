# Plan: fix the verified landmines

## In scope — clear bugs with unambiguous fixes

| # | Fix | File |
|---|---|---|
| 1 | `paths:` → `globs:` (rule silently never loads) | skills/brain-refresh/SKILL.md |
| 2 | selftest assertion that calls ok() on both branches | bin/selftest.sh |
| 3 | add template↔installed drift detection | bin/selftest.sh |
| 4 | debris check has no path exemptions | templates/pre-commit + 2 copies |
| 5 | docs say check is `brain-verify`; it is `verify` | README, install-gate.sh, install.sh, brain-onboard |
| 6 | install.sh swallows the ACTION REQUIRED message | install.sh |
| 7 | stale comments contradicting behaviour | templates/pre-commit |
| 8 | pyyaml missing misreported as invalid YAML | bin/selftest.sh |

## OUT OF SCOPE — deliberately not touching

- **Gate inert without ACTIVE.scope.** Correct behaviour: blocking every commit when no
  plan is active would be unusable. It already prints "Scope not enforced". No change.
- **`.brain/.stale` never auto-cleared.** Changing this is a design decision about whether
  hooks may delete state, not a bug fix.
- **pre-merge-commit as byte copy.** Deliberate in install-gate.sh; a symlink would not
  survive some checkouts.
- **Duplicated review/auditor checklists.** Merging them is a design change.
- **Unreferenced templates.** Wiring them in changes brain-onboard's contract.
- **Renaming the CI job to brain-verify.** Would require re-pointing branch protection;
  fixing the docs is the smaller change with no lockout risk.

## Verification

`bash bin/selftest.sh` green, `claude plugin validate .` green, CI green after push,
and the new drift check must actually fail when a copy is desynced.
