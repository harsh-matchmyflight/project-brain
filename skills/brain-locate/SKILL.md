---
name: brain-locate
description: Resolve "where do I change X" through the project index instead of searching the codebase. Use at the start of any request that names a UI element, feature, string, endpoint, or behaviour to modify — "change the button on the settings page", "where is the login flow", "update this text". Fires before any code is read.
---

# Locate through the index

The rule: **the index is the first hop, always.** Reading code to find code is the expensive mistake this whole system exists to prevent.

## Procedure

**1. Read `.brain/INDEX.md`.**
If it does not exist, say so and offer to run `brain-onboard`. Do not silently fall back to crawling the repo — that is the behaviour we are replacing.

**2. Resolve the user's words to a module.**
Start with the "Where do I change..." table. If the user's phrasing is not in it, match against module `Owns` lines and `Shared identifiers`. Use `.brain/GLOSSARY.md` for shorthand and internal names before asking the user what they mean.

**3. Name the candidate file(s) out loud, then verify — cheaply.**
One targeted confirmation, not a sweep:

```bash
rg -n --fixed-strings "<the literal string or symbol>" -g '!**/{node_modules,dist,build,.venv,vendor}/**'
```

For a user-facing string, search the literal text first — it is the highest-signal query available and usually lands in one hop.

**4. Open only the confirmed file, only the relevant region.**
Use `Read` with `offset`/`limit` around the match. Do not read the whole file unless it is small or you genuinely need the whole thing.

**5. Hand off to `brain-impact` before editing.**
Locating tells you where the thing *is*. It does not tell you what else touches it. Never go straight from locate to edit.

## Escalation ladder (only when the index misses)

1. Literal-string ripgrep (above).
2. LSP symbol search / find-references, if a language plugin is installed.
3. `ast-grep outline <suspected dir>` for structural surface.
4. Delegate a **scout** subagent with a narrow brief. Scout burns its own context, not yours.
5. Only then, broad search.

## After a miss — repair the index

If the index did not have the answer, that is a defect in the brain. Before finishing the task, add the resolved mapping to the "Where do I change..." table and to the module's entry. This is how the brain gets sharper instead of staler. Do not skip it because the task succeeded anyway.

## Anti-patterns

- Repo-wide `grep` as the opening move.
- Reading a directory "to get oriented" when INDEX already describes it.
- Re-deriving something INDEX already states, because you did not trust it. If you distrust an entry, verify that one entry and correct it — do not abandon the index.
- Asking the user "which file is that in?" before checking INDEX and GLOSSARY.
