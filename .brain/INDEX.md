# INDEX

> Read this before opening any source file. If it's wrong, fix it — do not route around it.
> Last verified: 2026-08-04 against commit 91fe6cf

**Shape:** 35 tracked files, ~2,350 lines. No compile step, no package manifest.
Bash + Markdown + a little Python. The product *is* the markdown: skills are
instructions, not code.

## Modules

### skills — the brain lifecycle
- **Path:** `skills/<name>/SKILL.md` (7 skills)
- **Owns:** onboard → locate → impact → plan → review → learn → refresh
- **Public surface:** frontmatter `name` (must equal directory name) + `description`
  (the only text loaded at session start — ~90 tokens each)
- **Depends on:** `.brain/*` artifacts, the `scout` and `auditor` subagents
- **Used by:** Claude Code skill loader; `bin/selftest.sh` validates every frontmatter
- **Shared identifiers:** verdict vocabulary `ship | fix first | rethink` (brain-review +
  auditor); impact verdicts `Contained | Wide | Risky`; markers `[assumed]`, `(unverified)`
- **Gotchas:** a skill's `description` is always-on context — editing it changes every
  session's startup cost. Renaming a directory without its frontmatter `name` fails selftest.

### agents — context isolation
- **Path:** `agents/{scout,auditor}.md`
- **Owns:** scout = read-only explorer returning findings not file dumps; auditor =
  independent diff reviewer
- **Public surface:** frontmatter `tools:` as a **comma-separated string**, capitalised
- **Used by:** `brain-onboard` (scout fan-out), `brain-review` (auditor)
- **Gotchas:** `auditor.md` duplicates ~90% of `brain-review`'s checklist but adds a
  "Gate integrity" check the skill lacks. Editing one does not update the other.

### bin — installers and verification
- **Path:** `bin/{install-gate.sh,selftest.sh}`, `install.sh` (repo root)
- **Public surface:** `install-gate.sh --with-ci --claude-settings`;
  `install.sh --skip-plugin --skip-gate`; env `PROJECT_BRAIN_HOME`
- **Writes:** `.githooks/{pre-commit,pre-merge-commit}`, `core.hooksPath=.githooks`,
  `.brain/plans/`, `.gitignore` entry, `.github/workflows/`, `.github/scripts/`,
  `.claude/settings.json`
- **Used by:** `install.sh` calls `install-gate.sh`; `brain-onboard` step 11 calls it
- **Gotchas:** `install-gate.sh` creates `.brain/plans/` **before** onboarding exists —
  any `-d .brain` existence test elsewhere gives a false positive. `install.sh` swallows
  install-gate's output, hiding its "ACTION REQUIRED: mark brain-verify required" message.

### hooks — Claude Code integration
- **Path:** `hooks/{hooks.json,session-start.sh,mark-stale.sh}`
- **Public surface:** `SessionStart` and `PostToolUse` events
- **Reads:** `.brain/INDEX.md`, `.brain/.stale`, `.brain/plans/ACTIVE.scope`
- **Writes:** `mark-stale.sh` appends edited paths to `.brain/.stale`
- **Shared identifiers:** `${CLAUDE_PLUGIN_ROOT}` (hooks.json only — not always injected,
  which is why every command ends `|| true`)
- **Gotchas:** nothing clears `.brain/.stale` except an agent voluntarily following
  `brain-refresh`. Advisory, not enforced.

### templates — the shipped payload
- **Path:** `templates/` (9 files)
- **Owns:** what gets copied into a target repo
- **Used by:** `install-gate.sh` copies `pre-commit`, `brain-verify.yml`,
  `check-features.py`; skills reference the `.tpl` files by bare path
- **Gotchas:** **4 files are duplicated** into `.githooks/` and `.github/` with no drift
  check anywhere. `INDEX.md.tpl`, `features.json.tpl` and `rule-example.md` are referenced
  by no skill — their formats are duplicated inline in `brain-onboard`, so they can drift
  silently.

### enforcement — the gate
- **Path:** `templates/pre-commit` → `.githooks/`; `templates/brain-verify.yml` → `.github/workflows/`
- **Public surface:** env `BRAIN_OVERRIDE=1`, `BRAIN_MAX_FILES` (25), `BRAIN_MAX_DIFF_LINES` (600)
- **Blocks on:** staged file outside `ACTIVE.scope`; conflict markers / `debugger;` / `binding.pry`
- **Warns only:** file-count tripwire, diff-size tripwire, INDEX freshness
- **Gotchas:** see DECISIONS — several, and they matter.

## Shared identifiers — rename one, break all of these

| Identifier | Files | Notes |
|---|---|---|
| `.brain/INDEX.md` | 14 | highest coupling in the repo |
| `.brain/plans/ACTIVE.scope` | 13 | the gate's input; `# plan: ` prefix is parsed |
| `core.hooksPath` / `.githooks` | 10 | survives cloning only because of this |
| `.brain/features.json` + keys `id`/`passes` | 10 | `check-features.py` parses these |
| `brain-verify` | 7 | **workflow** name; the CI *check* is `verify` — see gotcha |
| `BRAIN_OVERRIDE` | 5 | the documented escape hatch |
| `.brain/.stale` | 5 | written by hook, consumed by refresh, gitignored |
| `.brain/LESSONS.md` + `Promoted: no` | 4 | drained by brain-refresh |

## Where do I change...

| I want to change | Go to | Also check |
|---|---|---|
| what the gate blocks | `templates/pre-commit` | `.githooks/pre-commit` **and** `.githooks/pre-merge-commit` (byte copies), `templates/brain-verify.yml` — CI and local must agree |
| what CI checks | `templates/brain-verify.yml` | `.github/workflows/brain-verify.yml` (copy), `bin/selftest.sh` |
| a skill's trigger wording | `skills/<name>/SKILL.md` frontmatter `description` | always-on token cost; `bin/selftest.sh` frontmatter checks |
| the feature-regression rule | `templates/check-features.py` | `.github/scripts/check-features.py` (copy), `templates/features.json.tpl` |
| install behaviour | `install.sh` | `bin/install-gate.sh` (it calls this and swallows output), `README.md` quick start |
| what onboarding writes | `skills/brain-onboard/SKILL.md` | `templates/*.tpl` — formats are duplicated inline and can drift |
| the review checklist | `skills/brain-review/SKILL.md` | `agents/auditor.md` — near-duplicate, not shared |
| session startup message | `hooks/session-start.sh` | `hooks/hooks.json`, `.claude/settings.json` absolute-path fallback |

## Dynamic references — static tools cannot prove these

- `${CLAUDE_PLUGIN_ROOT}` is expanded by the Claude Code harness at hook-run time, not by
  any script here. Documented as not always injected.
- `templates/*.tpl` are cited by bare relative path in several skills; whether they resolve
  depends on the agent's cwd, which is the *target* repo, not the plugin root. `(unverified)`
- Branch-protection status-check matching is a string comparison performed by GitHub against
  the **job** name. Nothing in this repo can verify it.
