# DECISIONS

Non-obvious choices, and the landmines. Every entry below was verified against the
code on 2026-08-04 at commit 91fe6cf — none are inferred.

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

### 🔴 `brain-refresh` tells you to write a rules key that silently never loads
`skills/brain-onboard/SKILL.md:221` states plainly that the `paths:` frontmatter key
"is known not to parse — a rule written that way silently never loads", and mandates
`globs:`. But `skills/brain-refresh/SKILL.md:84` instructs moving material into
`.claude/rules/` "with `paths:` globs".

**An agent following brain-refresh produces a dead rule and gets no error.** This is the
exact class of bug the project's own design notes list as a v1 schema error, reintroduced
in prose. Highest-severity item in this file.

### 🔴 A selftest check that can never fail
`bin/selftest.sh:47-48`:
```
[ $? -ne 0 ] && ok "...handles bad input..." || ok "check-features.py ran"
```
Both branches call `ok`. The check passes unconditionally regardless of behaviour.
**The advertised count is therefore one higher than the number of real assertions.**

### 🔴 The gate does nothing in its default state
`templates/pre-commit` enforces scope only when `.brain/plans/ACTIVE.scope` exists and is
non-empty. Absent or empty → warn only, no enforcement. That is the state of every repo
that has not run `brain-plan`, i.e. the common case. The gate feels installed while
enforcing nothing.

### 🟠 Four files are duplicated with no drift check
`templates/{pre-commit,brain-verify.yml,check-features.py}` are copied to `.githooks/` and
`.github/`; `pre-commit` is copied *twice* (`pre-commit` + `pre-merge-commit`). `selftest.sh`
contains **zero** drift assertions. Editing a template without re-running `install-gate.sh`
leaves the live gate on old logic. Verified in sync at 91fe6cf — by hand, not by tooling.

### 🟠 The CI status check is named `verify`, not `brain-verify`
`templates/brain-verify.yml:1` sets `name: brain-verify` (the workflow); line 19 defines job
`verify:`. **Branch protection matches the job name.** Every instruction in this repo —
README, `install-gate.sh:55`, `install.sh` — tells the user to require "brain-verify",
which does not appear in the branch-protection picker. Anyone following the docs fails
to enable the only real enforcement layer.

### 🟠 The debris check matches its own source
`templates/pre-commit` and `templates/brain-verify.yml` contain `<<<<<<<` and `debugger;`
as string literals in their detection code. The CI copy now excludes `':!templates'`;
**the pre-commit copy has no path exemptions at all**, so committing an edit to
`templates/` still requires `BRAIN_OVERRIDE=1`. Known, unfixed.

### 🟠 `install.sh` hides the one message that matters
`install.sh` redirects `install-gate.sh` output to `/dev/null`, swallowing its
"ACTION REQUIRED: make brain-verify a required status check" line. Only a generic note in
the installer's own summary survives.

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

### 🟡 Stale comments contradict behaviour
`templates/pre-commit:9` documents installing to `.git/hooks/pre-commit`, contradicting the
`core.hooksPath` design. Line 79 comments the debris check "warn, not block"; it blocks.

## Tooling

- **LSP:** `typescript-lsp` and `pyright-lsp` are installed on this machine. This repo is
  bash + markdown, so neither contributes much here; they matter for target repos.
- **Available:** `rg`, `ctags`, `jq`, `python3` (3.9.6, system), `gh`, `git`.
- **Absent:** `ast-grep` — `brain-impact` and `brain-onboard` both prefer it and fall back
  to `rg`. Installing it would improve impact precision.
- **`pyyaml` was installed manually** so `selftest.sh`'s YAML check can run. It is not
  declared anywhere; a fresh machine fails that check with "invalid YAML (or pyyaml missing)",
  which misreports a missing dependency as a broken file.
