# project-brain

**A persistent brain for coding agents.** Stops the agent re-reading your codebase every session, stops it breaking three things while fixing one, and stops it rewriting 400 lines when 20 would do.

Works with Claude Code as a full plugin, and with Codex, Cursor, Antigravity, Windsurf, Cline, opencode, Amp, Gemini CLI and others through `AGENTS.md`.

No vector database. No embeddings. No API key. No daemon. No external service.

```bash
curl -fsSL https://raw.githubusercontent.com/harsh-matchmyflight/project-brain/main/install.sh | bash
```

Run that **from inside the repo you want it on**. It installs the plugin, wires the enforcement gate into that repo, and prints what to do next. It is idempotent — safe to re-run, and it detects rather than overwrites an existing `.githooks/`, `.claude/settings.json` or `.gitignore`.

---

**Contents** — [Quick start](#quick-start) · [What it does](#the-five-failures-it-targets) · [What it adds to your repo](#what-it-puts-in-your-repo) · [The loop](#the-loop) · [Install options](#install) · [Enforcement](#enforcement-is-layered-and-the-layers-are-not-equal) · [Troubleshooting](#troubleshooting) · [Why it's small](#why-its-small) · [Limits](#honest-limits)

---

## Quick start

**On an existing codebase** — this is the normal case; nothing needs to be greenfield.

```bash
cd ~/code/your-existing-repo
curl -fsSL https://raw.githubusercontent.com/harsh-matchmyflight/project-brain/main/install.sh | bash
```

Then:

1. **Restart Claude Code.** Skills load at session start — a mid-session install won't appear until you do.
2. Install the language server that powers impact analysis: `/plugin install typescript-lsp@claude-plugins-official`
3. In the agent, say: **`onboard this project`**
4. Mark `brain-verify` a **required** status check in branch protection. (See [Enforcement](#enforcement-is-layered-and-the-layers-are-not-equal) — this is the step people skip, and it's the one that matters.)

Onboarding reads the codebase once and writes `.brain/`. Budget a few minutes on a large repo. **For a monorepo, onboard per package** rather than all at once — see [Limits](#honest-limits).

After that, every session starts from the index instead of re-reading your code.

### Prerequisites

| Need | Why | If missing |
|---|---|---|
| `git` | the gate is git hooks + CI | required |
| `python3` | the CI feature check | required |
| `claude` CLI | installs the plugin half | `curl -fsSL https://claude.ai/install.sh \| bash` |
| An LSP plugin | precise find-references | falls back to `ast-grep`/`ripgrep`, less precise |

## The five failures it targets

1. The agent re-reads the same code every session.
2. It changes a thing in one place and silently breaks it in three others.
3. It rewrites 400 lines when 20 would do.
4. It has no memory of *why* the project is shaped the way it is.
5. It says it's done without verifying anything.

## What it puts in your repo

```
AGENTS.md             Source of truth. Read natively by ~everything except Claude Code.
CLAUDE.md             One line: @AGENTS.md — plus Claude-only extras. Nothing duplicated.
.brain/
  INDEX.md            The map. Module → path → public surface → depends on → USED BY.
                      Read before opening any code file.
  ARCHITECTURE.md     How it fits together, with Mermaid diagrams.
  PRD.md              Reverse-engineered product requirements.
  DECISIONS.md        Why it is the way it is. Constraints and landmines.
  GLOSSARY.md         Project vocabulary, so your shorthand resolves.
  LESSONS.md          What the brain got wrong. Capture inbox + the quality signal.
  features.json       Machine-checkable feature list. `passes` may only go false → true.
  plans/ACTIVE.scope  File allowlist for the change in flight. The gates read this.
.claude/rules/*.md    Path-scoped conventions. Zero startup cost until a match is read.
.githooks/            Version-controlled hooks. core.hooksPath is set, so they survive cloning.
.github/workflows/    brain-verify — the gate that actually holds.
```

All of it is committed on purpose. `.brain/` diffs get reviewed like code — that's the mitigation for memory poisoning, not an afterthought.

## The loop

```
locate → impact → plan → implement → review → commit → refresh
                                          ↘ learn ↗
```

| Skill | Fires when |
|---|---|
| `brain-onboard` | New project. Builds everything above. |
| `brain-locate` | "Where is X" / "change the button on Y". Index first, never blind grep. |
| `brain-impact` | Before any edit. Every usage — including i18n, tests, migrations, schemas, flags, and dynamically built identifiers. |
| `brain-plan` | 4+ files or shared code. Emits a file allowlist and an explicit OUT OF SCOPE list. |
| `brain-review` | After implementing. Judges the diff against the plan. |
| `brain-learn` | The moment the brain is wrong. Two lines to `LESSONS.md`, immediately — sessions end before a refresh runs. |
| `brain-refresh` | Keeps the brain current, incrementally. Drains `LESSONS.md` into permanent artifacts. |

Plus two subagents: **scout** (read-only explorer — returns findings, not file dumps) and **auditor** (independent diff reviewer that can't be talked out of a finding).

### How it improves itself

`brain-learn` captures misses cheaply as they happen; `brain-refresh` promotes them into `INDEX`, `DECISIONS` or a rules file, then clears them. Two counters in `LESSONS.md` are the quality signal:

- **All-time climbing, since-last-refresh returning to 0** — working. Misses happen, get promoted, stop recurring.
- **Since-last-refresh stays high across refreshes** — the index is structurally wrong, not incomplete. More rows won't fix it; re-onboard that area.
- **Both flat at 0 for weeks of real work** — almost certainly not being invoked, rather than a perfect brain. Models skip available skills; check `brain-locate` is being used at all.

## Install

The one-liner above is the recommended path. The pieces individually:

**Claude Code plugin only** (once per machine)

```bash
/plugin marketplace add harsh-matchmyflight/project-brain
/plugin install project-brain@project-brain-marketplace
```

**Language intelligence** (once per machine — this is the impact-analysis engine)

```bash
/plugin install typescript-lsp@claude-plugins-official
```

or `pyright-lsp`, `gopls-lsp`, `rust-analyzer-lsp`, `clangd-lsp`, `jdtls-lsp`, `csharp-lsp`, `php-lsp`, `swift-lsp`, `kotlin-lsp`, `lua-lsp`, `ruby-lsp`. For anything else, [Serena](https://github.com/oraios/serena) covers 40+ languages over MCP.

**Gate only, any agent** (once per repo)

```bash
bash ~/.local/share/project-brain/bin/install-gate.sh --with-ci --claude-settings
```

**Optional, JS/TS** — `brain-impact` uses these when present, degrades gracefully when absent:

```bash
npm i -D dependency-cruiser knip
```

See [docs/PORTABILITY.md](docs/PORTABILITY.md) for per-agent wiring beyond Claude Code.

## Enforcement is layered, and the layers are not equal

| Layer | Blocks | Fails when |
|---|---|---|
| `AGENTS.md` rules | nothing | any time the model chooses otherwise |
| `PreToolUse` hook | some tool calls | agent routes around Edit via Bash/perl/python — documented, closed "not planned" |
| `.githooks/pre-commit` | local commits | `--no-verify`, `-n`, `-c core.hooksPath=`, `SKIP=`; not fired on rebase or cherry-pick; `.git` read-only in some agent sandboxes |
| **CI required status check** | **everything reaching the branch** | only if you actually mark it required |

Setting `core.hooksPath=.githooks` (which the installer does) fixes the most common silent failure — hooks living in `.git/hooks` never survive a fresh clone. But be clear-eyed: the local hook is fast feedback, not control.

**Making `brain-verify` required:** repo → Settings → Branches → Add branch ruleset → Require status checks to pass → select `brain-verify`. Until you do this, an agent that runs `git commit --no-verify` faces nothing at all.

`BRAIN_OVERRIDE=1 git commit` is the documented escape hatch when you legitimately need past the local hook.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Skills don't appear after install | Skills load at session start | Restart Claude Code |
| `claude: command not found` in the installer | `curl \| bash` doesn't source your shell rc | Installer checks `~/.local/bin` itself; if still missing, install the CLI |
| CI red: `.brain/INDEX.md missing` | Gate installed, project not onboarded yet | Say `onboard this project` |
| CI red: `refusing to allow an OAuth App to... workflow` on push | Token lacks `workflow` scope | `gh auth refresh -h github.com -s workflow` |
| Pre-commit blocks a commit that only edits `templates/` | Known: the debris check matches its own source patterns | `BRAIN_OVERRIDE=1 git commit` |
| Gate never fires on a cloned repo | `core.hooksPath` isn't set in that clone | Re-run `install-gate.sh` |
| `brain-impact` vague about references | No LSP plugin installed | Install the one for your language |

## Why it's small

Every framework in this space fails the same way — it eats the context window. Measured: BMAD-METHOD at 67–86% of a 200K window before you type; SuperClaude at ~22%; GitHub Spec Kit generating 2,577 lines of markdown to produce 689 lines of code. Anthropic removed **over 80%** of Claude Code's system prompt with no measured loss on coding evals.

So: `AGENTS.md` is capped at ~150 lines, conventions live in path-scoped rules that cost nothing until matched, `INDEX.md` loads on demand, and the session-start hook injects a ~150-token pointer rather than a payload. **Measured startup footprint: ~782 tokens** for all 7 skills and 2 agents.

And the problem it targets is measured, not assumed — GitClear's analysis of 623M code changes (2023–2026) found duplicated blocks up 81%, refactored code down from 21% to 3.8% of changes, and function reuse down 35%. Agents reinvent rather than reuse. The "grep before you write a helper" and "edit in place, don't add a parallel path" rules are load-bearing.

## Development

```bash
bash bin/selftest.sh
```

Validates JSON, the manifest schema against `claude plugin validate`, hook shape, shell syntax, skill frontmatter against the Agent Skills spec, and proves the gate actually blocks an out-of-scope commit. All checks must pass before publishing.

## Honest limits

- Static analysis can't prove completeness where identifiers are built at runtime. `INDEX.md` has a "Dynamic references" section to make that gap **visible**, not to close it.
- The index can go stale. Refresh and the freshness warning mitigate; they don't eliminate. Spot-check five entries when you lean on it.
- Twelve of the thirteen operating rules are advisory. This raises the floor; it doesn't guarantee it.
- Auto-captured project knowledge can be poisoned by untrusted content (OWASP ASI06). `.brain/` is committed partly so you review its diffs like code.
- Onboarding a very large monorepo is expensive. Onboard per package, with per-directory `CLAUDE.md`.
- `templates/pre-commit` matches its own detection patterns, so editing the templates needs `BRAIN_OVERRIDE=1`. Known, unfixed.

MIT.
