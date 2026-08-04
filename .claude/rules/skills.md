---
globs: "skills/**, agents/**"
---
- Frontmatter `name` MUST equal the directory name, or `bin/selftest.sh` fails.
  No consecutive hyphens (Agent Skills spec).
- `description` is loaded at session start for EVERY session — it is always-on context
  (~90 tokens per skill). Editing it changes startup cost. Keep it trigger-focused.
- Agent frontmatter `tools:` is a COMMA-SEPARATED STRING with capitalised names
  (`Read, Grep, Glob, Bash`), never a YAML list.
- Use `globs:` in `.claude/rules/`, never `paths:` — the latter does not parse and the
  rule silently never loads. `brain-refresh` step 5 says `paths:`; it is wrong.
- `skills/brain-review/SKILL.md` and `agents/auditor.md` carry near-duplicate checklists.
  Changing one does not change the other.
