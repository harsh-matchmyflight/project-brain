#!/usr/bin/env bash
# project-brain — install the enforcement layer into the current repo.
#
# Installs hooks into a COMMITTED .githooks/ directory and points git at it via
# core.hooksPath. This matters: hooks in .git/hooks are not version-controlled
# and never survive a fresh clone, which is the most common reason gates silently
# do nothing.
#
# Usage:  bash bin/install-gate.sh [--with-ci] [--claude-settings]
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$HERE")"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$ROOT" ]; then
  echo "error: not inside a git repository. Run 'git init' first — the enforcement layer needs git." >&2
  exit 1
fi

WITH_CI=0
CLAUDE_SETTINGS=0
for arg in "$@"; do
  case "$arg" in
    --with-ci) WITH_CI=1 ;;
    --claude-settings) CLAUDE_SETTINGS=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 1 ;;
  esac
done

mkdir -p "$ROOT/.githooks" "$ROOT/.brain/plans"

# ---------------------------------------------------------------- git hooks
install -m 0755 "$PLUGIN_ROOT/templates/pre-commit" "$ROOT/.githooks/pre-commit"

# pre-commit does NOT fire on merge commits; git routes those to pre-merge-commit.
# Without this, an agent can land unverified content by merging.
cp "$ROOT/.githooks/pre-commit" "$ROOT/.githooks/pre-merge-commit"
chmod 0755 "$ROOT/.githooks/pre-merge-commit"

git -C "$ROOT" config core.hooksPath .githooks
echo "installed: .githooks/{pre-commit,pre-merge-commit}  (core.hooksPath=.githooks)"

# --------------------------------------------------------------- .gitignore
GI="$ROOT/.gitignore"
touch "$GI"
grep -qxF '.brain/.stale' "$GI" || printf '\n# project-brain scratch\n.brain/.stale\n' >> "$GI"

# ------------------------------------------------------------------ CI gate
if [ "$WITH_CI" -eq 1 ]; then
  mkdir -p "$ROOT/.github/workflows" "$ROOT/.github/scripts"
  cp "$PLUGIN_ROOT/templates/brain-verify.yml" "$ROOT/.github/workflows/brain-verify.yml"
  install -m 0755 "$PLUGIN_ROOT/templates/check-features.py" "$ROOT/.github/scripts/check-features.py"
  echo "installed: .github/workflows/brain-verify.yml + .github/scripts/check-features.py"
  echo "  ACTION REQUIRED: make 'verify' a required status check in branch protection."
  echo "  ('verify' is the JOB name — 'brain-verify' is the workflow and will not appear there.)"
  echo "  Local hooks are bypassable; the required check is the gate that actually holds."
fi

# ------------------------------- project-level hook fallback for Claude Code
# ${CLAUDE_PLUGIN_ROOT} is documented but has known cases where it is not
# injected into hook subprocesses. This writes absolute paths as a fallback.
if [ "$CLAUDE_SETTINGS" -eq 1 ]; then
  mkdir -p "$ROOT/.claude"
  SETTINGS="$ROOT/.claude/settings.json"
  if [ -f "$SETTINGS" ]; then
    echo "skipped: $SETTINGS already exists — merge these hooks by hand:"
    SETTINGS="/dev/stdout"
  fi
  cat > "$SETTINGS" <<JSON
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$PLUGIN_ROOT/hooks/session-start.sh\" 2>/dev/null || true", "timeout": 10 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "bash \"$PLUGIN_ROOT/hooks/mark-stale.sh\" 2>/dev/null || true", "timeout": 5 }
        ]
      }
    ]
  }
}
JSON
fi

echo
echo "Enforcement layers now active, weakest to strongest:"
echo "  1. AGENTS.md / CLAUDE.md rules ........ advisory"
echo "  2. .githooks/pre-commit ............... blocks local commits (bypassable: --no-verify)"
echo "  3. CI required status check ........... the real gate (use --with-ci)"
echo
echo "Next: run 'onboard this project' in your agent to build .brain/."
