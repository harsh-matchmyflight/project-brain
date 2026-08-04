---
globs: "src/payments/**, **/*payment*, **/*refund*"
---

<!-- Save as .claude/rules/payments.md
     Rules with globs load ONLY when Claude reads a matching file. This is the
     only mechanism in Claude Code that gives more knowledge at lower startup
     cost. Domain conventions belong here, not in CLAUDE.md.

     IMPORTANT — use `globs:` with a comma-separated UNQUOTED-pattern string,
     as above. The documented `paths:` key with YAML list syntax
     (paths: ["src/**"]) is known not to parse. Patterns beginning with `*`
     or `{` must sit inside the quoted string, as shown. -->

# Payments conventions

- Money is integer minor units everywhere. Never float, never `parseFloat` on an amount. Formatting to decimal happens at the view layer only.
- All payment state transitions go through `payments/state.ts`. Never write `payments.status` directly — audit and webhook side effects are attached.
- Stripe webhook handlers must be idempotent. The same `event.id` will arrive more than once; check `processed_events` before acting.
- `PAYMENT_STATUS` values are duplicated in three places by necessity: the TS enum, the DB enum type, and `i18n/*.json` labels. Changing one requires changing all three plus a migration.
- Never log a full card object or a `client_secret`.

<!-- Write rules from what you actually observed in this codebase. Generic best
     practice is noise; project-specific landmines are the entire value. Keep
     each rule file under ~40 lines. -->
