#!/usr/bin/env bash
# SessionStart hook. stdout is injected into Claude's context, so keep it tiny.
# Budget: ~150 tokens. This is a pointer, not a payload.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
BRAIN="$ROOT/.brain"

# Test INDEX.md, not the directory: install-gate.sh creates .brain/plans/ before
# onboarding ever runs, so a -d test passes on every freshly gated repo and points
# the agent at an INDEX that does not exist yet.
if [ ! -f "$BRAIN/INDEX.md" ]; then
  echo "[brain] No .brain/INDEX.md in this repo. If the user asks for structural work, offer to run brain-onboard first."
  exit 0
fi

echo "[brain] Project brain is present at .brain/"
echo "[brain] Before locating code: read .brain/INDEX.md. Before editing shared code: run brain-impact."

# Report index freshness without loading the index itself.
VERIFIED_SHA="$(grep -m1 -o 'against commit [0-9a-f]\{7,40\}' "$BRAIN/INDEX.md" 2>/dev/null | awk '{print $3}')"
if [ -n "${VERIFIED_SHA:-}" ]; then
  BEHIND="$(git -C "$ROOT" rev-list --count "$VERIFIED_SHA"..HEAD 2>/dev/null || echo "")"
  if [ -n "$BEHIND" ] && [ "$BEHIND" -gt 25 ] 2>/dev/null; then
    echo "[brain] INDEX is $BEHIND commits behind HEAD — treat it as possibly stale; run brain-refresh."
  fi
fi

if [ -f "$BRAIN/.stale" ]; then
  echo "[brain] Files were edited since the last refresh (see .brain/.stale). Run brain-refresh when the task is done."
fi

if [ -s "$BRAIN/plans/ACTIVE.scope" ]; then
  PLAN="$(head -1 "$BRAIN/plans/ACTIVE.scope" | sed 's/^# plan: //')"
  echo "[brain] Active plan: $PLAN — commits are gated to its file allowlist."
fi

exit 0
