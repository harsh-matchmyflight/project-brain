---
globs: "templates/**, .githooks/**, .github/**, bin/install-gate.sh"
---
- These files are DUPLICATED. `templates/pre-commit` → `.githooks/pre-commit` AND
  `.githooks/pre-merge-commit`. `templates/brain-verify.yml` → `.github/workflows/`.
  `templates/check-features.py` → `.github/scripts/`. Nothing detects drift — edit the
  template, then re-sync every copy, then verify with `diff -q`.
- Committing a change here trips the debris check, because these files contain
  `<<<<<<<` and `debugger;` as literals in their own detection code. Use
  `BRAIN_OVERRIDE=1` and say why in the commit message.
- The CI status check is the JOB name `verify`, not the workflow name `brain-verify`.
  Renaming the job silently breaks branch protection.
- The scope gate is inert when `.brain/plans/ACTIVE.scope` is missing or empty.
- `pre-merge-commit` exists because git routes merge commits away from `pre-commit`.
