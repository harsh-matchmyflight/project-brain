# project-brain

**A persistent brain for coding agents.** Stops the agent re-reading your codebase every session, stops it breaking three things while fixing one, and stops it rewriting 400 lines when 20 would do.

Works with Claude Code as a full plugin, and with Codex, Cursor, Antigravity, Windsurf, Cline, opencode, Amp, Gemini CLI and others through `AGENTS.md`.

No vector database. No embeddings. No API key. No daemon. No external service.

---

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
  features.json       Machine-checkable feature list. `passes` may only go false → true.
  plans/ACTIVE.scope  File allowlist for the change in flight. The gates read this.
.claude/rules/*.md    Path-scoped conventions. Zero startup cost until a match is read.
.githooks/            Version-controlled hooks. core.hooksPath is set, so they survive cloning.
.github/workflows/    brain-verify — the gate that actually holds.
```

## The loop

```
locate → impact → plan → implement → review → commit → refresh
```

| Skill | Fires when |
|---|---|
| `brain-onboard` | New project. Builds everything above. |
| `brain-locate` | "Where is X" / "change the button on Y". Index first, never blind grep. |
| `brain-impact` | Before any edit. Every usage — including i18n, tests, migrations, schemas, flags, and dynamically built identifiers. |
| `brain-plan` | 4+ files or shared code. Emits a file allowlist and an explicit OUT OF SCOPE list. |
| `brain-review` | After implementing. Judges the diff against the plan. |
| `brain-refresh` | Keeps the brain current, incrementally. |

Plus two subagents: **scout** (read-only explorer — returns findings, not file dumps) and **auditor** (independent diff reviewer that can't be talked out of a finding).

## Install

**Claude Code**

```bash
/plugin marketplace add harsh-matchmyflight/project-brain
/plugin install project-brain@project-brain-marketplace
```

Then, once per machine, install the language intelligence that powers impact analysis:

```
/plugin install typescript-lsp@claude-plugins-official
```

(or `pyright-lsp`, `gopls-lsp`, `rust-analyzer-lsp`, `clangd-lsp`, `jdtls-lsp`, `csharp-lsp`, `php-lsp`, `swift-lsp`, `kotlin-lsp`, `lua-lsp`. For anything else, [Serena](https://github.com/oraios/serena) covers 40+ languages over MCP.)

**Any agent** — clone the repo, then in your project:

```bash
bash /path/to/project-brain/bin/install-gate.sh --with-ci
```

Then ask your agent to *"onboard this project"*. See [docs/PORTABILITY.md](docs/PORTABILITY.md) for per-agent wiring.

**⚠️ One required manual step:** after installing, mark `brain-verify` as a **required status check** in branch protection. Local git hooks are bypassable; the required check is the layer that actually holds. See below.

## Enforcement is layered, and the layers are not equal

| Layer | Blocks | Fails when |
|---|---|---|
| `AGENTS.md` rules | nothing | any time the model chooses otherwise |
| `PreToolUse` hook | some tool calls | agent routes around Edit via Bash/perl/python — documented, closed "not planned" |
| `.githooks/pre-commit` | local commits | `--no-verify`, `-n`, `-c core.hooksPath=`, `SKIP=`; not fired on rebase or cherry-pick; `.git` read-only in some agent sandboxes |
| **CI required status check** | **everything reaching the branch** | only if you actually mark it required |

Setting `core.hooksPath=.githooks` (which the installer does) fixes the most common silent failure — hooks living in `.git/hooks` never survive a fresh clone. But be clear-eyed: the local hook is fast feedback, not control.

## Why it's small

Every framework in this space fails the same way — it eats the context window. Measured: BMAD-METHOD at 67–86% of a 200K window before you type; SuperClaude at ~22%; GitHub Spec Kit generating 2,577 lines of markdown to produce 689 lines of code. Anthropic removed **over 80%** of Claude Code's system prompt with no measured loss on coding evals.

So: `AGENTS.md` is capped at ~150 lines, conventions live in path-scoped rules that cost nothing until matched, `INDEX.md` loads on demand, and the session-start hook injects a ~150-token pointer rather than a payload. Startup footprint is a few hundred tokens over baseline.

And the problem it targets is measured, not assumed — GitClear's analysis of 623M code changes (2023–2026) found duplicated blocks up 81%, refactored code down from 21% to 3.8% of changes, and function reuse down 35%. Agents reinvent rather than reuse. The "grep before you write a helper" and "edit in place, don't add a parallel path" rules are load-bearing.

## Development

```bash
bash bin/selftest.sh    # validates JSON, hook schema, frontmatter, and proves the gate blocks
```

## Honest limits

- Static analysis can't prove completeness where identifiers are built at runtime. `INDEX.md` has a "Dynamic references" section to make that gap **visible**, not to close it.
- The index can go stale. Refresh and the freshness warning mitigate; they don't eliminate. Spot-check five entries when you lean on it.
- Twelve of the thirteen operating rules are advisory. This raises the floor; it doesn't guarantee it.
- Auto-captured project knowledge can be poisoned by untrusted content (OWASP ASI06). `.brain/` is committed partly so you review its diffs like code.

MIT.
