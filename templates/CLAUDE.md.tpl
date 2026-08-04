@AGENTS.md

<!--
  Everything shared with other agents lives in AGENTS.md. That import is the
  whole point: one source of truth, zero duplication. Claude Code does not read
  AGENTS.md natively, which is why this line exists.

  Below: Claude-Code-only additions. Keep this file short — the imported
  AGENTS.md already counts against the context budget, and a bloated CLAUDE.md
  causes Claude to ignore the rules that matter.

  Note: @-imports are expanded into context at launch, so they do not save
  tokens. Path-scoped domain conventions belong in .claude/rules/*.md with a
  `globs:` frontmatter key — those load only when a matching file is read.
-->

## Claude Code specifics

- Use the `brain-locate` skill before searching for code. The index is hop one.
- Use `brain-impact` before editing anything shared. It uses the LSP tool for find-references when a language plugin is installed.
- Delegate wide exploration to the `scout` subagent so findings come back instead of file dumps.
- Delegate high-stakes diff review to the `auditor` subagent.
- Run `brain-refresh` at the end of any task that changed structure.

## Language intelligence

This repo expects one of the official LSP plugins to be installed:

```
/plugin install <typescript|pyright|gopls|rust-analyzer|clangd|jdtls|csharp|php|swift|kotlin|lua>-lsp@claude-plugins-official
```

Without it, `brain-impact` degrades to `ast-grep`/`ripgrep` and is less precise about references.
