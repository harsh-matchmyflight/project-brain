# GLOSSARY

| Term | Means |
|---|---|
| **the brain** | the committed `.brain/` directory — index, architecture, PRD, decisions, glossary, lessons, features |
| **hop 1** | `.brain/INDEX.md`. The mandatory first read for any "where is X" request |
| **blast radius** | every place a symbol/string/route/column is used, including non-code surfaces |
| **the gate** | the enforcement stack; unqualified it usually means `.githooks/pre-commit` |
| **the control** | specifically the CI required status check — the only non-bypassable layer |
| **ACTIVE.scope** | `.brain/plans/ACTIVE.scope`, the file allowlist the gate reads |
| **debris** | conflict markers, `debugger;`, `binding.pry` in a diff |
| **tripwire** | a warn-only threshold (file count 25, diff lines 600) |
| **landmine** | a non-obvious coupling that has broken something, or will |
| **scout** | read-only explorer subagent; returns findings, never file contents |
| **auditor** | independent diff reviewer subagent that cannot be argued down |
| **`[assumed]`** | PRD marker for inference, awaiting user confirmation |
| **`(unverified)`** | INDEX marker for an edge that could not be confirmed |
| **Contained / Wide / Risky** | `brain-impact` verdicts; Wide or Risky requires a plan |
| **ship / fix first / rethink** | `brain-review` and `auditor` verdicts |
| **drain** | `brain-refresh` promoting LESSONS entries into permanent artifacts |
| **surgical change** | minimum diff that achieves the ask; no drive-by edits |
| **`brain-verify`** | the CI *workflow* name. The *status check* is `verify` — see DECISIONS |
