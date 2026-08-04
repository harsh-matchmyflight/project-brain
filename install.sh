#!/usr/bin/env bash
# project-brain one-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/harsh-matchmyflight/project-brain/main/install.sh | bash
#
# Run it from inside the repo you want to onboard. It is idempotent: safe to
# re-run on a repo that already has the gate, and safe to run once per machine
# for the plugin half. Nothing here is destructive — existing .githooks,
# .claude/settings.json and .gitignore entries are detected, not overwritten.
set -uo pipefail

OWNER_REPO="harsh-matchmyflight/project-brain"
SRC_DIR="${PROJECT_BRAIN_HOME:-$HOME/.local/share/project-brain}"
SKIP_PLUGIN=0
SKIP_GATE=0
for arg in "$@"; do
  case "$arg" in
    --skip-plugin) SKIP_PLUGIN=1 ;;
    --skip-gate)   SKIP_GATE=1 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown flag: $arg" >&2; exit 1 ;;
  esac
done

b() { printf '\033[1m%s\033[0m\n' "$1"; }
ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
no() { printf '  \033[31m✗\033[0m %s\n' "$1"; }
tip() { printf '  \033[33m→\033[0m %s\n' "$1"; }

b "project-brain installer"

# ------------------------------------------------------------- prerequisites
MISSING=0
command -v git     >/dev/null 2>&1 || { no "git not found";     MISSING=1; }
command -v python3 >/dev/null 2>&1 || { no "python3 not found — the CI feature check needs it"; MISSING=1; }
[ "$MISSING" -eq 1 ] && { echo; echo "Install the missing prerequisites and re-run." >&2; exit 1; }

# curl | bash runs non-interactively, so ~/.zshrc is never sourced and a freshly
# installed CLI is invisible on PATH. Look where the official installer puts it.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
HAS_CLAUDE=0
command -v claude >/dev/null 2>&1 && HAS_CLAUDE=1

# ------------------------------------------------------------- fetch sources
# Needed for install-gate.sh and the templates, whether or not the plugin half runs.
if [ -d "$SRC_DIR/.git" ]; then
  git -C "$SRC_DIR" fetch -q origin 2>/dev/null && git -C "$SRC_DIR" reset -q --hard origin/main 2>/dev/null
  ok "updated sources at $SRC_DIR"
elif [ -f "$(dirname "${BASH_SOURCE[0]}")/bin/install-gate.sh" ]; then
  SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ok "using local checkout at $SRC_DIR"
else
  mkdir -p "$(dirname "$SRC_DIR")"
  if git clone -q --depth 1 "https://github.com/$OWNER_REPO.git" "$SRC_DIR" 2>/dev/null; then
    ok "fetched sources to $SRC_DIR"
  else
    no "could not clone https://github.com/$OWNER_REPO.git"; exit 1
  fi
fi

# ------------------------------------------------------------------- plugin
if [ "$SKIP_PLUGIN" -eq 0 ]; then
  if [ "$HAS_CLAUDE" -eq 1 ]; then
    claude plugin marketplace add "$OWNER_REPO" >/dev/null 2>&1 \
      || claude plugin marketplace update project-brain-marketplace >/dev/null 2>&1
    if claude plugin list 2>/dev/null | grep -q "project-brain@"; then
      ok "plugin already installed"
    elif claude plugin install project-brain@project-brain-marketplace >/dev/null 2>&1; then
      ok "plugin installed (7 skills, 2 agents)"
    else
      no "plugin install failed — run: claude plugin install project-brain@project-brain-marketplace"
    fi
  else
    no "claude CLI not found — skipping the plugin half"
    tip "install it:  curl -fsSL https://claude.ai/install.sh | bash"
    tip "then re-run this script, or:  claude plugin marketplace add $OWNER_REPO"
  fi
fi

# --------------------------------------------------------------------- gate
if [ "$SKIP_GATE" -eq 0 ]; then
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    ROOT="$(git rev-parse --show-toplevel)"
    if [ "$ROOT" = "$SRC_DIR" ]; then
      tip "inside project-brain itself — skipping gate install"
    else
      bash "$SRC_DIR/bin/install-gate.sh" --with-ci --claude-settings >/dev/null 2>&1 \
        && ok "gate installed in $(basename "$ROOT") (.githooks + CI workflow)" \
        || no "gate install failed — run bin/install-gate.sh directly to see why"
    fi
  else
    tip "not inside a git repository — skipped the per-project gate"
    tip "cd into your repo and run:  bash $SRC_DIR/bin/install-gate.sh --with-ci --claude-settings"
  fi
fi

# -------------------------------------------------------------- next steps
echo
b "Next"
[ "$HAS_CLAUDE" -eq 1 ] && echo "  1. Restart Claude Code — skills load at session start, not mid-session."
[ "$HAS_CLAUDE" -eq 0 ] && echo "  1. Install the Claude Code CLI, then re-run this script."
echo "  2. Install the LSP plugin for your language — this is what powers impact analysis:"
echo "       /plugin install typescript-lsp@claude-plugins-official"
echo "     (or pyright / gopls / rust-analyzer / clangd / jdtls / csharp / php / swift / kotlin / lua)"
echo "  3. In the agent, say:  onboard this project"
echo "  4. Mark 'brain-verify' a REQUIRED status check in branch protection."
echo "     Local hooks are bypassable (--no-verify, -n, core.hooksPath=). CI is the control."
echo
echo "Onboarding an existing codebase reads it once and writes .brain/. Expect a few"
echo "minutes on a large repo. For a monorepo, onboard per package rather than all at once."
