# <PROJECT NAME>

<One line: what this is.>
<One line: who uses it.>
<One line: the single most important thing to know before touching it.>

<!--
  This is AGENTS.md — the cross-agent instruction file, read natively by Codex,
  Cursor, Windsurf/Devin, Cline, opencode, Amp, Zed, Warp, Copilot, Jules,
  Factory and others. Claude Code does NOT read it; CLAUDE.md imports it with a
  single `@AGENTS.md` line, so this file stays the one source of truth.

  Keep it under ~150 lines. Codex caps the combined instruction chain at 32 KiB.
  Bloated instruction files cause agents to ignore the rules that matter.
-->

## Before you touch code

1. **Read `.brain/INDEX.md` first.** It maps every module to its path, public surface, dependents and shared identifiers. Do not search the repo to find something the index already names. If an entry is wrong, fix the entry — do not route around it.
2. **Find the blast radius before editing shared code.** Every place the thing is used — including i18n files, tests, snapshots, migrations, API schemas, config, feature flags and identifiers built dynamically at runtime.
3. **For anything touching 4+ files, write the plan first**, with an explicit file allowlist and an OUT OF SCOPE list, and get it approved. If you could describe the diff in one sentence, skip the plan.
4. **Review the diff against the plan before saying you're done.** Then run the verification commands and report the actual output.

## Surgical changes

Minimum code that solves the problem. Nothing speculative.

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused; leave pre-existing dead code alone.
- Before writing a helper, grep for an existing one. Reinventing a function that already exists is the most common failure in agent-authored code.
- Prefer editing in place over adding a parallel path. `doThingV2` next to `doThing` is almost always wrong.

**The test: every changed line must trace directly to what was asked.**

## Scope

The active task's file allowlist is `.brain/plans/ACTIVE.scope`. If implementation reveals a file you need that isn't listed: stop, say so, get it added. Do not edit it silently.

## Enforcement — do not circumvent

Commits run through `.githooks/pre-commit`, and CI re-runs the same checks as a required status check.

**Never use `--no-verify`, `-n`, `git -c core.hooksPath=…`, or `SKIP=…` to get a commit through.** If a hook blocks you, the correct response is to fix the cause or tell the user why the gate is wrong — never to bypass it. A commit that only lands because verification was skipped is not a completed task.

## Commands

```bash
# install
<...>
# dev
<...>
# test
<...>
# build
<...>
# lint / typecheck
<...>
```

## Gotchas

<Only real landmines. Things that have actually broken. Not descriptions of what
directories contain — that is INDEX's job, and INDEX loads on demand.>

- <gotcha>
- <gotcha>

## Never

- <hard prohibition specific to this repo>
- Never edit `.env*`.
- Never mark a `.brain/features.json` entry `passes: true` without running its `verify` command and seeing it pass.
