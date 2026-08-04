# DECISIONS

Non-obvious choices, and the landmines. Every entry below was verified against the
code on 2026-08-04 — none are inferred. Fixed entries are retained deliberately:
they explain why the code looks the way it does.

## Architectural choices

### Markdown is the product, not documentation of it
Skills are instructions executed by a model. There is no compile step and no package
manifest. **Consequence:** a typo in a `description` is a behaviour change, and the
only test that exists is `bin/selftest.sh` plus reading it carefully.

### Enforcement is layered and deliberately unequal
Advisory rules → git hooks → CI required check. The README and skills are explicit that
layer 2 is bypassable. **Constrains:** never present the local hook as a guarantee;
BOOTSTRAP's stated reason is that false confidence is worse than no gate.

### `core.hooksPath=.githooks` instead of `.git/hooks`
`.git/hooks` is not version-controlled and never survives a fresh clone — documented as
the most common silent gate failure in the wild. **Would break if reversed:** every
cloned copy of a protected repo silently loses its gate.

### Zero external dependencies
No vector DB, no embedding API, no daemon. Rejected explicitly after evidence that
embedding-based code search underperforms plain file exploration (83% vs 92% answer
quality in one graph-MCP's own preprint).

### `AGENTS.md` is the source of truth; `CLAUDE.md` is a one-line bridge
Claude Code does not read `AGENTS.md` natively. **Constrains:** never duplicate content
between them, and never let `CLAUDE.md` grow — it is an `@import`, and imports are
expanded into context at launch so they save nothing.

## Landmines — verified, not inferred

> ✅ = fixed. 🔴🟠🟡 = still open, severity descending.
> Fixed entries are kept, not deleted: they record why the code looks the way it does.

### ✅ FIXED (b1b126e+) — `brain-refresh` told you to write a rules key that never loads
`skills/brain-onboard/SKILL.md:221` states plainly that the `paths:` frontmatter key
"is known not to parse — a rule written that way silently never loads", and mandates
`globs:`. But `skills/brain-refresh/SKILL.md:84` instructs moving material into
`.claude/rules/` "with `paths:` globs".

An agent following brain-refresh produced a dead rule with no error — the exact class of
bug the design notes list as a v1 schema error, reintroduced in prose.
**Fixed:** brain-refresh now says `globs:` and states explicitly that `paths:` never loads.

### ✅ FIXED — a selftest check that could never fail
`bin/selftest.sh:47-48`:
```
[ $? -ne 0 ] && ok "...handles bad input..." || ok "check-features.py ran"
```
Both branches called `ok`, so the assertion passed regardless of behaviour and the
advertised count overstated the real one by one.
**Fixed:** the failing branch now calls `bad`.

### 🔴 The gate does nothing in its default state
`templates/pre-commit` enforces scope only when `.brain/plans/ACTIVE.scope` exists and is
non-empty. Absent or empty → warn only, no enforcement. That is the state of every repo
that has not run `brain-plan`, i.e. the common case. The gate feels installed while
enforcing nothing.

### ✅ FIXED — four files duplicated, now with a drift check
`templates/{pre-commit,brain-verify.yml,check-features.py}` are copied to `.githooks/` and
`.github/`; `pre-commit` is copied *twice* (`pre-commit` + `pre-merge-commit`). `selftest.sh`
had **zero** drift assertions, so editing a template without re-running `install-gate.sh`
left the live gate on stale logic.
**Fixed:** selftest now `cmp`s all four pairs. Negative-tested — desyncing a copy fails it.

### ✅ FIXED (docs) — the CI status check is named `verify`, not `brain-verify`
`templates/brain-verify.yml:1` sets `name: brain-verify` (the workflow); line 19 defines job
`verify:`. **Branch protection matches the job name.** Every instruction in this repo —
README, `install-gate.sh:55`, `install.sh` — tells the user to require "brain-verify",
which does not appear in the branch-protection picker, so anyone following the docs failed
to enable the only real enforcement layer.
**Fixed (docs only):** README, install-gate.sh, install.sh and brain-onboard now say `verify`.
The job was *not* renamed — that would require re-pointing existing branch protection.

### ✅ FIXED — the debris check matched its own source
`templates/pre-commit` and `templates/brain-verify.yml` contain `<<<<<<<` and `debugger;`
as string literals in their detection code, and the `.brain/` docs describe those patterns
in prose. The pre-commit copy had no path exemptions, so it blocked its own source and its
own documentation.
**Fixed:** pre-commit now exempts `templates/`, `.githooks/`, `.github/`, `.brain/` and
`*.md`, mirroring the CI check.

### ✅ FIXED — `install.sh` hid the one message that matters
`install.sh` redirects `install-gate.sh` output to `/dev/null`, swallowing its
"ACTION REQUIRED" line — the single most important instruction in the install.
**Fixed:** output is captured and the ACTION REQUIRED lines are printed.

### 🟡 `install-gate.sh` creates `.brain/plans/` before onboarding exists
Any `-d .brain` existence test therefore gives a false positive on a gated-but-not-onboarded
repo. `hooks/session-start.sh:9` now tests `.brain/INDEX.md` instead — reintroducing a
directory test would restore the bug.

### 🟡 `.brain/.stale` is never cleared automatically
Written by `hooks/mark-stale.sh`; only removed if an agent voluntarily follows
`brain-refresh`. It accumulates silently.

### 🟡 `pre-merge-commit` is a byte copy, not a symlink
Editing the installed `pre-commit` alone leaves merge commits ungated.

### 🟡 Duplicated review logic
`skills/brain-review/SKILL.md` and `agents/auditor.md` carry near-identical checklists;
auditor has a "Gate integrity" check the skill lacks. No shared source.

### 🟡 Three templates are referenced by nothing
`templates/{INDEX.md.tpl,features.json.tpl,rule-example.md}` — their formats are duplicated
inline in `brain-onboard`. `features.json.tpl` is touched only by `selftest.sh`.

### ✅ FIXED — stale comments contradicted behaviour
`templates/pre-commit:9` documents installing to `.git/hooks/pre-commit`, contradicting the
`core.hooksPath` design. Line 79 commented the debris check "warn, not block"; it blocks.
**Fixed:** both corrected.

## Tooling

- **LSP:** `typescript-lsp` and `pyright-lsp` are installed on this machine. This repo is
  bash + markdown, so neither contributes much here; they matter for target repos.
- **Available:** `rg`, `ctags`, `jq`, `python3` (3.9.6, system), `gh`, `git`.
- **Absent:** `ast-grep` — `brain-impact` and `brain-onboard` both prefer it and fall back
  to `rg`. Installing it would improve impact precision.
- **`pyyaml` was installed manually** so `selftest.sh`'s YAML check can run. Still undeclared,
  but the check now distinguishes "pyyaml not installed" from "invalid YAML" instead of
  conflating them — that conflation cost real debugging time on first run.
