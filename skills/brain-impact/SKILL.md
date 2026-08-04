---
name: brain-impact
description: Find the full blast radius before changing anything — every place a symbol, string, route, column, config key or feature is used, including non-code references that search-and-replace misses. Use before every edit that touches shared code, renames anything, changes a signature, or modifies a string that may appear in more than one place.
---

# Blast radius

The failure this prevents: change a thing in one place, three other places break silently, and nobody finds out until production.

Run this **before** editing, not after. Its output feeds `brain-plan`.

## 1. Name the target precisely

What exactly is changing? One of:
- a symbol (function, class, component, type)
- a literal string (UI copy, error message)
- an identifier that crosses layers (enum value, status string, event name, feature flag, route path, DB column, API field, i18n key, CSS class, env var)
- a signature or return shape
- a file that may be imported by path

The third category is the dangerous one. Compiler-precision tools do **not** catch identifiers that cross a serialization boundary.

## 2. Structural references — use the best available tool

In this order, use the first that is available:

**a. LSP (best).** If a language plugin is installed, use find-references and call-hierarchy. Compiler precision, no false positives, resolves re-exports and aliases.

**b. Serena MCP**, if configured — `find_referencing_symbols`.

**c. `ast-grep`** for structural patterns:
```bash
ast-grep run -p '<pattern>' --json
```

**d. `ripgrep`** as the floor:
```bash
rg -n --word-regexp "<symbol>" -g '!**/{node_modules,dist,build,.venv,vendor}/**'
```

## 3. Non-structural references — this is the part that gets missed

Run these regardless of what step 2 found. Search the **literal value**, not just the symbol name:

```bash
rg -n --fixed-strings "<literal value>" \
  -g '!**/{node_modules,dist,build,.venv,vendor}/**' \
  -g '!**/*.lock'
```

Then explicitly check each of these surfaces, and say in your output which you checked:

- **i18n / locale files** — `**/locales/**`, `**/i18n/**`, `*.po`, `*.arb`
- **tests, fixtures, snapshots** — a changed string breaks snapshots
- **DB migrations & schema** — column/enum names
- **API contracts** — OpenAPI/GraphQL schemas, protobufs, typed clients
- **config & env** — `.env*`, `*.yml`, `*.toml`, CI configs, IaC
- **feature flags & analytics events** — often string-keyed and invisible to the compiler
- **docs, README, comments**
- **dynamic construction** — string concatenation, template literals, reflection, `getattr`, dependency injection registries, dynamic imports. Grep for a distinctive *prefix* of the identifier, not the whole thing, or you will miss `"payment_" + status`.
- **`.brain/INDEX.md`** — the module's `Used by` and `Shared identifiers` fields

For JS/TS, if available: `npx depcruise --reachable '<file>' src` for module-level reach; `npx knip` to check whether the thing is dead and can simply be deleted.

## 4. Classify every hit

Discard nothing silently. Produce a table:

| # | File:line | Kind | Must change? | Why |
|---|---|---|---|---|
| 1 | `src/payments/refund.ts:42` | definition | yes | the change itself |
| 2 | `admin/RefundPanel.tsx:88` | caller | yes | passes the old signature |
| 3 | `i18n/en.json:210` | UI string | yes | user-visible copy |
| 4 | `i18n/de.json:210` | UI string | **flag** | translation will drift — ask user |
| 5 | `tests/refund.test.ts:15` | test | yes | asserts the old value |
| 6 | `docs/policy.md:30` | doc | no | descriptive prose, not a reference |

## 5. Verdict

State one of:

- **Contained** — 1–3 files, all mechanical. Proceed directly, no plan needed.
- **Wide** — 4+ files, or crosses a layer boundary. Run `brain-plan` first and get the file allowlist approved.
- **Risky** — dynamic references, a public API, a DB column, or anything where the search cannot prove completeness. **Stop and tell the user exactly what you cannot prove.** Do not proceed on the assumption that grep found everything.

Be explicit about the limits: dynamic dispatch, reflection, string-built identifiers, and DI containers defeat every static tool that exists. Say so when they are present rather than reporting false confidence.

## 6. Feed it forward

Append the confirmed file list to `.brain/plans/ACTIVE.scope` (one path or glob per line). The git pre-commit gate reads that file. If a file is not in the scope list, the commit is blocked — which is the point.

## 7. Verify after the edit

Re-run the same searches. Zero remaining references to the old form, or an explicit justification for each survivor. Then run the build and the tests. A blast-radius analysis that ends without a green build has not finished.
