---
name: brain-plan
description: Produce a scope-locked implementation plan with an explicit file allowlist, an OUT OF SCOPE section, and a verification step — before writing any code. Use for any change touching more than three files, any change to shared or public code, or when brain-impact returned a Wide or Risky verdict. Skip for one-line fixes.
---

# Scope-locked plan

## When NOT to use this

If you could describe the diff in one sentence, skip the plan and just do it. Planning overhead on trivial changes is a real cost, not a virtue. This skill is for changes where getting the scope wrong is expensive.

## Inputs

- The user's request
- `.brain/INDEX.md` — the modules involved
- The `brain-impact` table — the blast radius
- `.claude/rules/*` matching the touched paths

## Output: `.brain/plans/<slug>.md`

```markdown
# Plan: <slug>
Created: <ISO date> · Base commit: <sha>

## Goal
<One sentence. What is true after this that is not true now.>

## Approach
<3–8 lines. The chosen approach and, briefly, what was rejected and why.>

## Files in scope
| File | Change | Est. lines |
|---|---|---|
| `src/payments/refund.ts` | add `reason` param, default null | ~8 |
| `admin/RefundPanel.tsx` | pass reason from the form | ~6 |
| `i18n/en.json` | new label key | ~1 |
| `tests/refund.test.ts` | cover the new param | ~15 |

**No file outside this table may be modified.** If implementation reveals a needed file, stop, add it here, and say so — do not edit it silently.

## OUT OF SCOPE
- Refactoring `payments/state.ts` even though it is messy
- Adding refund reasons to the mobile client
- Upgrading the Stripe SDK
- Renaming anything

## Blast radius accepted
<From brain-impact. Every downstream reference, and how each is handled.>

## Risks
| Risk | Mitigation |
|---|---|
| `de.json` translation drifts | flag to user, ship English fallback |

## Verification
1. `npm test -- refund`
2. `npm run build`
3. Manual: issue a refund with a reason in the admin panel, confirm it persists
4. `rg -n 'refund\(' src/` returns zero old-signature callers

## Rollback
<How to undo. Usually: revert the commit. State it if it is not.>
```

Then write the file allowlist to `.brain/plans/ACTIVE.scope`, one path or glob per line, plus a first line `# plan: <slug>`. The pre-commit gate reads this file — it is the mechanism, not a formality.

## Non-negotiable rules to carry into implementation

Restate these in the plan so they travel with it:

```
## Simplicity first
Minimum code that solves the problem. Nothing speculative.
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

## Surgical changes
Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: every changed line must trace directly to the goal above.
```

Two more, specific to the failure modes measured across AI-authored code (duplicated blocks up 81%, refactoring down from 21% to 3.8% of changes, function reuse down 35% since 2023):

- **Before writing a helper, grep for an existing one.** The dominant AI failure is reinventing a function that already exists three directories over. Search first; the index's public-surface fields exist for this.
- **Prefer editing in place over adding a parallel path.** A new `handleRefundV2` next to `handleRefund` is almost always the wrong answer.

## Approval

Show the user the **Files in scope** table and the **OUT OF SCOPE** list before implementing. That is the moment to catch a misunderstanding — after implementation it costs ten times more. Ask once, concisely; don't turn it into a questionnaire.

## During implementation

- Work the table top to bottom.
- If you need a file that is not listed: **stop**, report, get it added. This is the single rule that keeps scope from creeping.
- Update `passes` in `.brain/features.json` only after actually running the `verify` command and seeing it pass.
- When done, run `brain-review` before declaring completion.
