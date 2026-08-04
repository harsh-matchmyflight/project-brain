# Portability

project-brain is built around two facts:

1. **`AGENTS.md` is the only instruction file that nearly every coding agent reads.** It is stewarded by the Agentic AI Foundation under the Linux Foundation, used in ~60k public repos, and has no schema — it is plain Markdown.
2. **Claude Code does not read `AGENTS.md`.** It reads `CLAUDE.md`. The supported bridge is a single `@AGENTS.md` import line.

So `brain-onboard` writes `AGENTS.md` as the source of truth and `CLAUDE.md` as a one-line import plus Claude-only extras. Nothing is duplicated.

## What each agent picks up

| Agent | Reads `AGENTS.md` | Reads `SKILL.md` from | MCP | Gets from project-brain |
|---|---|---|---|---|
| **Claude Code** | No — via `@AGENTS.md` in `CLAUDE.md` | `.claude/skills/`, plugin | ✅ | Everything: skills, subagents, hooks, rules, gates |
| **Codex CLI** | ✅ native (32 KiB cap on the chain) | `.agents/skills/` | ✅ | AGENTS.md + skills + gates |
| **Codex cloud** | ✅ | ✅ | ❌ | AGENTS.md + skills + CI gate |
| **Cursor** | ✅ (also reads `CLAUDE.md`) | `.agents/skills/`, `.cursor/skills/`, `.claude/skills/` | ✅ | AGENTS.md + skills + gates |
| **Google Antigravity** | ⚠️ CLI only; IDE/2.0 unverified | `.agents/skills/`, `~/.gemini/config/skills/` | ✅ (`serverUrl` key) | AGENTS.md (CLI) + skills + gates |
| **Windsurf / Devin Desktop** | ✅ | `.windsurf/skills/`, `.agents/skills/` | ✅ | AGENTS.md + skills + gates |
| **Gemini CLI** | Opt-in via `.gemini/settings.json` | `.agents/skills/` | ✅ | AGENTS.md (after opt-in) + skills + gates |
| **Cline** | ✅ automatic | `.agents/skills/`, `.claude/skills/` | ✅ | AGENTS.md + skills + gates |
| **opencode** | ✅ primary | `.agents/skills/`, `.claude/skills/` | ✅ | AGENTS.md + skills + gates |
| **Amp** | ✅ primary | `.agents/skills/`, `.claude/skills/` | ✅ | AGENTS.md + skills + gates |
| **Zed, Warp, Copilot, Jules, Factory, Goose, Kilo, Roo, Junie** | ✅ | `.agents/skills/` (most) | mostly ✅ | AGENTS.md + gates |

**Universal:** `AGENTS.md` at repo root. **Near-universal:** `.agents/skills/<name>/SKILL.md` and MCP. Nothing else is portable — per-vendor rules formats (`.cursor/rules/*.mdc`, `.windsurf/rules/`, `.clinerules`) buy nothing that `AGENTS.md` doesn't already deliver, at the cost of a format you must maintain.

## Wiring the skills for non-Claude agents

The six skills ship inside the Claude Code plugin at `skills/<name>/SKILL.md`. They are written to the strict Agent Skills spec — `name` matches the directory, `description` present, no consecutive hyphens — so they satisfy the strictest implementer (Codex) and every looser one.

To expose them to other agents, symlink rather than copy:

```bash
mkdir -p .agents/skills
for s in <plugin-root>/skills/*/; do
  ln -sfn "$(cd "$s" && pwd)" ".agents/skills/$(basename "$s")"
done
```

Two caveats worth knowing before you rely on this:

- **Gemini CLI's `context.fileName` setting is additive.** Setting it to `AGENTS.md` unions with `GEMINI.md` rather than replacing it; you cannot turn `GEMINI.md` off.
- **Models demonstrably skip skills.** The MCP Skills working group's own experiments found agents reaching for tools directly and ignoring available skills. Anything that *must* happen belongs in the gate, not in a skill.

## Why enforcement is layered, and where each layer fails

This is the part most systems get wrong, so it is stated plainly.

| Layer | Blocks | Fails when |
|---|---|---|
| `AGENTS.md` / `CLAUDE.md` rules | nothing | any time the model chooses otherwise |
| Claude `PreToolUse` hook | some tool calls | agent routes around Edit via Bash, perl, python; documented and closed "not planned" |
| `.githooks/pre-commit` | local commits | `--no-verify`, `-n`, `git -c core.hooksPath=…`, `SKIP=`; not installed in a fresh clone unless `core.hooksPath` is committed; does not fire on rebase or cherry-pick; `.git` is read-only in the Codex sandbox |
| `.githooks/pre-merge-commit` | local merge commits | same bypasses |
| **CI required status check** | **everything that reaches the branch** | only if you actually mark it required |

`install-gate.sh` sets `core.hooksPath=.githooks` so the hooks are version-controlled and survive cloning — this alone fixes the most common silent failure. But **the required status check is the only layer that holds against an agent that decides to bypass, against commits created through a hosting API, and against web-UI squash merges.**

Install it. Mark it required. Treat the local hook as fast feedback, not control.

## Keeping hooks sandbox-survivable

Agent sandboxes break hooks in predictable ways. The shipped `pre-commit` is written to avoid all of them — under 1 second, no network, no TTY prompts, no Docker, no watchman, no external dependency beyond `git`, `grep`, `sed` and `awk`. If you extend it, keep those constraints. A hook that hangs waiting for a TTY turns your gate into a denial of service, and agents that time out on a slow hook tend to assume success and retry-loop.
