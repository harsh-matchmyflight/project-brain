# project-brain — agent instructions

A Claude Code plugin that gives coding agents a persistent, committed understanding of a
codebase: an index, impact analysis, scope-locked plans, and layered git + CI enforcement.
The product is markdown — skills are instructions a model executes, not code that compiles.

**Read `.brain/INDEX.md` before opening any source file.** It is hop 1 for every
"where is X" or "change Y" request. If it is wrong, fix it — do not route around it.

## Operating loop

```
locate → impact → plan (if wide) → implement → review → commit → refresh
                                        ↘ learn on any miss ↗
```

1. **Index before code.** Never start with a blind grep.
2. **Impact before edit.** Never change shared code, a signature, or a user-visible string
   without knowing every place it is used. Check the non-code surfaces explicitly.
3. **Say what you cannot prove.** Dynamic dispatch and string-built identifiers defeat every
   static tool. Report the limit rather than false confidence.
4. **Plan when it's wide, skip it when it's one line.** Threshold ≈ 4 files, or any shared code.
5. **Every changed line must trace to what was asked.** No drive-by improvements.
6. **Grep before you write a helper.** Reinventing an existing function is the most common
   AI code defect and is invisible unless you look.
7. **Edit in place; don't add a parallel path.** `doThingV2` beside `doThing` is wrong.
8. **Verify by running, not asserting.** Never claim tests pass without executing them.
   Never flip a `features.json` entry to `passes: true` without running its `verify`.
9. **A stated rationale never downgrades a review finding.**
10. **Don't manufacture findings either.** Report only what affects correctness or scope.
11. **Files outside the plan's allowlist: stop and ask.**
12. **Update the brain when you learn something** — same session, or it is lost.
13. **Keep the brain small.** Prune during refresh. Every context system that died here
    died of growth.

## Surgical changes

Least possible change that fully achieves the ask. Production quality, minimal diff.
No speculative abstraction, no error handling for impossible cases, no reformatting,
no rewriting what already works.

## This repo specifically

**Commands** — there is no build step.

```bash
bash bin/selftest.sh              # the only test suite
claude plugin validate .          # manifest schema
bash bin/install-gate.sh --with-ci --claude-settings
```

**Before editing anything, know these:**

- **4 files are duplicated.** `templates/{pre-commit,brain-verify.yml,check-features.py}`
  are copied into `.githooks/` and `.github/`; `pre-commit` twice (`pre-merge-commit` is a
  byte copy). **No drift check exists.** Edit the template *and* re-sync the copies.
- **The CI status check is `verify`, not `brain-verify`.** `brain-verify` is the workflow
  name. Branch protection matches the job name. Docs across this repo get this wrong.
- **`brain-refresh` step 5 tells you to use `paths:` in `.claude/rules/`. That key does not
  parse and the rule silently never loads.** Always use `globs:`.
- **The gate enforces nothing without `.brain/plans/ACTIVE.scope`** — the default state.
- **Editing `templates/` requires `BRAIN_OVERRIDE=1`** to commit: the debris check matches
  its own source patterns.
- Skill `description` frontmatter is always-on context. Editing it changes every session's
  startup cost (~90 tokens per skill, ~782 total).

Full list with file:line in `.brain/DECISIONS.md`. Read it before structural work.

## Enforcement — do not circumvent

Layers, weakest to strongest: these rules (advisory) → `.githooks/pre-commit` (bypassable
with `--no-verify`, `-n`, `core.hooksPath=`, `SKIP=`; does not fire on rebase or cherry-pick)
→ **the CI required status check, which is the only real control.**

Never use `--no-verify` or `BRAIN_OVERRIDE=1` to get a commit through. The one legitimate
use of `BRAIN_OVERRIDE=1` is editing `templates/`, which trips the debris false positive —
say so in the commit message when you do.

## Scope

When a plan is active, `.brain/plans/ACTIVE.scope` lists the files you may touch. Anything
outside it: stop and ask. The gate will block it regardless.
