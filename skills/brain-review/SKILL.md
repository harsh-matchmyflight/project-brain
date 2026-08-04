---
name: brain-review
description: Review the working diff against the active plan before committing or declaring a task done — checks scope creep, duplication, broken references, missing tests, and whether the change is minimal. Use after implementing any change, and whenever the user asks whether something is safe to commit or actually finished.
---

# Review the diff

## Get the diff, and judge only the diff

```bash
git --no-pager diff --stat
git --no-pager diff
git status --porcelain
```

**The diff's context lines are the file.** Do not open a changed file separately unless a hunk you must judge is cut off mid-function. Do not crawl the broader codebase. Inspect code outside the diff only to evaluate a concrete risk you can name.

This constraint matters: a reviewer that wanders becomes as expensive as the implementation, and starts inventing work.

## Checks, in order

**1. Scope.** Compare changed files against `.brain/plans/ACTIVE.scope` and the plan's file table. Any file outside it is a finding — severity high, no exceptions. Any file inside it changed far beyond its estimated size is a finding.

**2. Minimality.** For each hunk: does this line trace directly to the stated goal? Flag unrelated formatting, reordered imports, renamed locals, "while I was in here" cleanups, added abstraction with one call site, defensive error handling for impossible cases, and speculative configurability.

**3. Duplication.** Does this diff add logic that already exists elsewhere? Grep the new function/constant names and a distinctive line of the new logic. This is the highest-frequency defect in AI-authored diffs and it is invisible unless you look for it deliberately.

**4. Broken references.** Every symbol, string or key the diff changed — is every downstream use updated? Re-run the `brain-impact` searches. Check specifically: i18n files, tests and snapshots, migrations, API schemas, config, docs, and dynamically constructed identifiers.

**5. Deletions.** Was anything removed that was not the implementer's own mess? Pre-existing dead code, comments, or error handling deleted without being asked is a finding.

**6. Tests and verification.** Do the plan's verification steps actually pass? Run them. Not "the tests look right" — run them. A review that ends without executing the build and test commands is incomplete.

**7. Index freshness.** If the diff added, moved, renamed or removed a module, a public export, or a route, does `.brain/INDEX.md` still describe reality? If not, that is a finding, and `brain-refresh` fixes it.

## The rule that makes this worth running

> A stated rationale never downgrades a finding's severity.

"Left it for YAGNI", "kept it simple deliberately", "this is out of scope but harmless", "I'll clean it up later" — these are claims by the implementer about their own work, not evidence. Judge the code on its merits. If the code is wrong, the finding stands regardless of how well it is justified.

Equally: do not manufacture findings. A reviewer asked to find gaps will find some even when the work is sound, and chasing every one produces exactly the over-engineering this system exists to prevent. **Report only gaps that affect correctness, scope, or the stated requirements.** Not style preferences.

## Output

```markdown
## Review: <plan slug>

**Verdict:** ship / fix first / rethink

### Blocking
1. `admin/RefundPanel.tsx` was modified but is not in ACTIVE.scope — out of plan.
2. `de.json` still holds the old string; the UI will show stale German copy.

### Non-blocking
1. `refund.ts:88` duplicates `lib/money.ts:formatMinor` — reuse it.

### Verified
- `npm test -- refund` ✅ 14 passed
- `npm run build` ✅
- `rg 'refund\('` → 0 old-signature callers

### Not verified
- Manual admin-panel check — needs a human.
```

Be explicit about what you could **not** verify. Silence there reads as confidence, and false confidence is what causes the outage.

## For high-stakes changes

Delegate to the **auditor** subagent instead of reviewing inline. It reviews in its own context window, which keeps the implementer's reasoning from contaminating the judgement — and keeps the main context clean.
