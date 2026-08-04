# ARCHITECTURE

## System map

```mermaid
graph TD
  USER[User request] --> LOC[brain-locate]
  LOC -->|hop 1| IDX[(.brain/INDEX.md)]
  LOC --> IMP[brain-impact]
  IMP --> LSP[LSP find-references]
  IMP --> RG[ast-grep / ripgrep]
  IMP -->|Wide or Risky| PLAN[brain-plan]
  IMP -->|Contained| CODE[implement]
  PLAN --> SCOPE[(.brain/plans/ACTIVE.scope)]
  PLAN --> CODE
  CODE --> REV[brain-review]
  REV -.high stakes.-> AUD[auditor subagent]
  REV --> GATE{{.githooks/pre-commit}}
  SCOPE --> GATE
  GATE --> CI{{CI: job 'verify'}}
  CI --> MAIN[(main branch)]
  CODE -->|on a miss| LEARN[brain-learn]
  LEARN --> LESS[(.brain/LESSONS.md)]
  LESS --> REF[brain-refresh]
  REF --> IDX
```

## Onboarding sequence

```mermaid
sequenceDiagram
  participant U as User
  participant O as brain-onboard
  participant S as scout subagents
  participant G as install-gate.sh
  U->>O: "onboard this project"
  O->>O: skeleton sweep (git ls-files, no reads)
  O->>S: fan out, one per area (max ~5)
  S-->>O: findings only, never file contents
  O->>O: write .brain/, AGENTS.md, CLAUDE.md, .claude/rules/
  O->>G: --with-ci --claude-settings
  G-->>O: .githooks/, core.hooksPath, .github/
  O->>U: summary + [assumed] lines to confirm
```

## Enforcement layers

```mermaid
graph LR
  A[AGENTS.md rules<br/>advisory] --> B[PreToolUse hook<br/>bypassable via Bash]
  B --> C[pre-commit<br/>bypassable: --no-verify, -n,<br/>core.hooksPath=, SKIP=]
  C --> D[CI required check<br/>THE CONTROL]
  style D fill:#2d6,stroke:#161,color:#000
  style A fill:#fdd,stroke:#900,color:#000
```

Strength increases left to right. Layers A–C are all bypassable by an agent that chooses
to; only D survives, and only once marked **required** in branch protection.

## Data model — what lives where

```mermaid
erDiagram
  INDEX ||--o{ MODULE : describes
  MODULE ||--o{ SHARED_ID : "declares"
  PLAN ||--|| ACTIVE_SCOPE : "writes"
  ACTIVE_SCOPE ||--o{ STAGED_FILE : "gates"
  LESSONS ||--o{ LESSON : "accumulates"
  LESSON }o--|| INDEX : "promoted into"
  FEATURES ||--o{ FEATURE : "tracks"
```

`.brain/` is committed on purpose — the diffs get reviewed like code, which is the stated
mitigation for memory poisoning (OWASP ASI06).

## Runtime shape

No server, no daemon, no build. Three execution contexts:

| Context | Trigger | Runs |
|---|---|---|
| Claude Code session | `SessionStart` | `hooks/session-start.sh` — prints a pointer + freshness warning |
| Claude Code edit | `PostToolUse` on Edit/Write | `hooks/mark-stale.sh` — appends to `.brain/.stale` |
| git | `pre-commit`, `pre-merge-commit` | scope + debris checks |
| GitHub Actions | push / PR to `main` | job `verify` |

## External dependencies

`git`, `python3`, `bash`. Optional: `rg`, `ast-grep`, `ctags`, `jq`, the `claude` CLI, an
LSP plugin. **Undeclared:** `pyyaml`, required by `selftest.sh`'s YAML check.

## Failure modes

| Failure | How it shows | Recovery |
|---|---|---|
| INDEX goes stale | session-start warns "N commits behind" | `brain-refresh` |
| Gate absent after clone | commits pass that should not | re-run `install-gate.sh`; `core.hooksPath` is per-clone |
| Scope unenforced | gate prints "Scope not enforced" | expected without an ACTIVE.scope — the default state |
| CI never required | red checks merge anyway | mark job `verify` required in branch protection |
| Template/installed drift | live gate runs old logic | no detection exists — compare by hand |
| Dynamic identifiers | impact analysis under-reports | INDEX "Dynamic references" makes the gap visible, not closed |
