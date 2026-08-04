#!/usr/bin/env bash
# PostToolUse hook on Edit/Write. Records that the brain may need refreshing.
# Advisory only, and deliberately silent: it must never interrupt the flow.
set -uo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -d "$ROOT/.brain" ] || exit 0

PAYLOAD="$(cat 2>/dev/null || true)"

# Best-effort extraction of file_path from the hook payload without requiring jq.
FILE="$(printf '%s' "$PAYLOAD" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')"
[ -n "${FILE:-}" ] || exit 0

case "$FILE" in
  */.brain/*|*/node_modules/*|*/dist/*|*/build/*|*/.venv/*|*/vendor/*) exit 0 ;;
esac

STALE="$ROOT/.brain/.stale"
grep -qxF "$FILE" "$STALE" 2>/dev/null || echo "$FILE" >> "$STALE"

exit 0
