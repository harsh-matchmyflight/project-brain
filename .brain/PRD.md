# PRD — project-brain

Reverse-engineered from README.md, the BOOTSTRAP design document, git history, and
the shipped artifacts. Lines marked `[assumed]` are inference, not verified fact —
correct them and they become permanent ground truth.

## Problem being solved

Coding agents behave as though they have amnesia. Concretely, five failures:

1. The agent re-reads the same code every session.
2. It changes a thing in one place and silently breaks it in three others.
3. It rewrites 400 lines when 20 would do.
4. It has no memory of *why* the project is shaped the way it is.
5. It says it is done without verifying anything.

Failure 3 is measured, not assumed: GitClear's analysis of 623M code changes
(2023–2026) found duplicated blocks up 81%, refactored code down from 21% to 3.8%
of changes, and function reuse down 35%. Agents reinvent rather than reuse.

The competing frameworks fail a sixth way — they eat the context window. BMAD-METHOD
consumes 67–86% of a 200K window before the user types; SuperClaude ~22%. This is why
the design's dominant constraint is *smallness*, not feature count.

## Who uses it

Developers running Claude Code, plus users of any agent that reads `AGENTS.md`
(Codex, Cursor, Windsurf, Cline, opencode, Amp, Gemini CLI, Zed, Warp, Copilot).

`[assumed]` Primary user is a solo developer or small team on an existing codebase,
not a greenfield project — the install path is optimised for "run it in the repo you
already have".

## Core user journeys

1. **Install** — run the one-liner inside an existing repo. Plugin installs, the
   enforcement gate is wired into that repo, next steps are printed.
2. **Onboard** — say "onboard this project". The agent surveys the repo and writes
   `.brain/` (INDEX, ARCHITECTURE, PRD, DECISIONS, GLOSSARY, LESSONS, features.json),
   `AGENTS.md`, the `CLAUDE.md` bridge, and `.claude/rules/`.
3. **Change something** — locate via the index (never a blind grep) → impact analysis
   for the full blast radius → plan with a file allowlist if wide → implement →
   review the diff against the plan → commit through the gate.
4. **Learn from a miss** — when the brain is wrong, `brain-learn` appends to
   `LESSONS.md` immediately; `brain-refresh` later promotes it into the permanent
   artifacts and clears it.
5. **Keep it current** — `brain-refresh` updates the index incrementally from the
   git diff rather than rebuilding.

## Feature inventory

| Area | Feature |
|---|---|
| Navigation | `.brain/INDEX.md` with per-module path, public surface, depends-on, **used-by**, shared identifiers, gotchas; plus a "Where do I change…" lookup table |
| Impact | `brain-impact` — LSP find-references, ast-grep, ripgrep, plus non-code surfaces (i18n, tests, snapshots, migrations, schemas, flags, docs) |
| Scope control | `brain-plan` writes `.brain/plans/ACTIVE.scope`; the git gate blocks commits touching files outside it |
| Review | `brain-review` judges the diff against the plan; `auditor` subagent for high-stakes changes |
| Self-improvement | `brain-learn` capture inbox + two counters in `LESSONS.md` as the quality signal |
| Enforcement | 3 layers: advisory rules → version-controlled git hooks → CI required status check |
| Verification | `features.json` entries may only flip `false → true`, and only after their `verify` command runs green |
| Portability | `AGENTS.md` as single source of truth; `CLAUDE.md` is one `@AGENTS.md` import plus Claude-only extras |
| Context discipline | Hard ~150-line cap on `AGENTS.md`; path-scoped `.claude/rules/` cost nothing until matched; measured ~782-token startup footprint |

## Explicit non-goals

Things the code deliberately does **not** do, each with a stated reason:

- **No vector/embedding code search.** Requires an external DB and API key; Sourcegraph
  removed embeddings from Cody in favour of structural + keyword search. One graph-MCP's
  own preprint reports 83% answer quality vs 92% for a plain file-exploring agent.
- **No third-party memory layer.** Claude Code's native auto-memory is on by default and
  capped; stacking on top of it is rejected.
- **No per-vendor rules formats** (`.cursor/rules/*.mdc`, `.windsurf/rules/`, `.clinerules`).
  Each is maintenance burden for agents that already read `AGENTS.md`.
- **No external dependencies at all** — no vector DB, no API key, no daemon, no service.
- **Does not claim the local git hook is a control.** It is explicitly documented as
  bypassable; only the CI required check is presented as enforcement.

## Open questions

- `[assumed]` The intended primary consumer language is TypeScript — the README's default
  LSP example and the JS/TS-only optional tooling suggest it, but the plugin itself is
  language-agnostic (bash + markdown + Python).
- `[assumed]` Version 2.0.0 implies a v1 that shipped four schema errors (documented in
  BOOTSTRAP §0). No v1 exists in this repo's git history — the first commit is already v2.
- Unresolved: whether `brain-learn`'s counters earn their ~81 tokens. No real-world
  session data exists yet; the system has never been used on a live project.
