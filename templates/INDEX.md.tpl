# INDEX — <project>

> Read this before opening any source file.
> If an entry is wrong, fix the entry — do not route around it.
>
> Last verified: <YYYY-MM-DD> against commit <sha>

## Where do I change...

| I want to change | Go to | Also check |
|---|---|---|
| <user-facing thing, in the words a person would actually use> | `path/to/file.ext` | `i18n/*.json`, snapshot tests |
| | | |

<!-- This table is the highest-value part of the file. It turns "change the text
     on that button" into a one-hop lookup. Populate it from the real
     user-facing surface: screens, buttons, emails, errors, endpoints. -->

## Modules

### <module-name>
- **Path:** `src/<module>/`
- **Owns:** <the responsibility, one line>
- **Entry:** `src/<module>/index.ext`
- **Public surface:**
  - `fn(args) -> ret` — `path:line`
- **Depends on:** <in-repo modules> · <external packages>
- **Used by:** `path:line`, `path:line`
- **Shared identifiers:** <enums, status strings, event names, flags, routes, DB columns, i18n keys that cross a boundary>
- **Gotchas:** <what has actually broken here>
- **Tests:** `path` — run with `<command>`

<!-- "Used by" and "Shared identifiers" are the fields that prevent silent
     breakage. If you cannot verify an edge, write it as `(unverified)` rather
     than omitting or guessing. -->

## Cross-cutting

| Concern | Lives in | Touched by |
|---|---|---|
| auth | `src/auth/` | every route |
| logging | `lib/log.ts` | everywhere |
| feature flags | `config/flags.*` | <list> |

## Dynamic references (static search will not find these)

<Identifiers built at runtime by concatenation, reflection, DI registries, or
dynamic imports. List them explicitly — they are the ones that break silently
and no tool will catch them.>

- `"payment_" + status` in `src/payments/events.ts:44` — constructs event names
- <...>

## Not mapped

<Areas deliberately not indexed, and why. Honesty here is worth more than
coverage: an unmapped area you know about is safe; one you don't is not.>
