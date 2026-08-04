@AGENTS.md

<!--
  Everything shared with other agents lives in AGENTS.md. That import is the whole
  point: one source of truth, zero duplication. Claude Code does not read AGENTS.md
  natively, which is why this line exists. Keep this file short.
-->

## Claude Code specifics

- `brain-locate` before searching for code. The index is hop one.
- `brain-impact` before editing anything shared.
- `brain-learn` the moment the brain is wrong — immediately, not at end of task.
- Delegate wide exploration to the `scout` subagent; high-stakes diff review to `auditor`.
- `brain-refresh` at the end of any task that changed structure.

## Language intelligence

This repo is bash + markdown + a little Python, so LSP adds little here. `pyright-lsp`
is the relevant one for `templates/check-features.py`. `ast-grep` is **not installed**;
`brain-impact` falls back to ripgrep and is less precise as a result.
