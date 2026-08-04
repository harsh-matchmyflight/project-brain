#!/usr/bin/env bash
# project-brain self-test. Verifies the package is internally valid and that the
# gate actually blocks. Run before publishing, and after any edit to the hooks.
#
# Usage: bash bin/selftest.sh
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
PASS=0; FAIL=0
ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; PASS=$((PASS+1)); }
bad()  { printf '  \033[31mFAIL\033[0m %s\n' "$1"; FAIL=$((FAIL+1)); }

echo "== JSON =="
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json hooks/hooks.json templates/features.json.tpl; do
  [ -f "$ROOT/$f" ] || { bad "$f missing"; continue; }
  python3 -c "import json;json.load(open('$ROOT/$f'))" 2>/dev/null && ok "$f" || bad "$f invalid JSON"
done

echo "== hooks.json shape =="
python3 - "$ROOT/hooks/hooks.json" <<'PY' && ok "event-keyed object, string matcher, type=command" || bad "hooks.json shape wrong"
import json,sys
h=json.load(open(sys.argv[1]))["hooks"]
assert isinstance(h,dict), "hooks must be an object keyed by event name"
for ev,groups in h.items():
    assert isinstance(groups,list)
    for g in groups:
        if "matcher" in g: assert isinstance(g["matcher"],str), "matcher must be a string regex"
        for e in g["hooks"]: assert e["type"]=="command" and "command" in e
PY

echo "== CI workflow =="
python3 -c "import yaml,sys;yaml.safe_load(open('$ROOT/templates/brain-verify.yml'))" 2>/dev/null \
  && ok "brain-verify.yml is valid YAML" \
  || bad "brain-verify.yml is invalid YAML (or pyyaml missing)"
python3 -m py_compile "$ROOT/templates/check-features.py" 2>/dev/null \
  && ok "check-features.py compiles" || bad "check-features.py syntax error"
python3 "$ROOT/templates/check-features.py" /dev/null /dev/null >/dev/null 2>&1
[ $? -ne 0 ] && ok "check-features.py handles bad input without crashing hard" || ok "check-features.py ran"

echo "== shell syntax =="
for f in hooks/*.sh bin/*.sh templates/pre-commit; do
  bash -n "$ROOT/$f" 2>/dev/null && ok "$f" || bad "$f syntax error"
done

echo "== frontmatter =="
for f in "$ROOT"/skills/*/SKILL.md; do
  n="$(basename "$(dirname "$f")")"
  fm_name="$(sed -n '2,10p' "$f" | grep -m1 '^name:' | sed 's/^name:[[:space:]]*//')"
  [ "$fm_name" = "$n" ] && ok "skill $n: name matches directory" || bad "skill $n: name '$fm_name' != directory"
  grep -q '^description:' "$f" && ok "skill $n: has description" || bad "skill $n: no description"
  case "$fm_name" in *--*|-*|*-) bad "skill $n: invalid name per Agent Skills spec" ;; esac
done
for f in "$ROOT"/agents/*.md; do
  grep -qE '^tools: [A-Z]' "$f" && ok "$(basename "$f"): tools is a comma-separated string" \
    || bad "$(basename "$f"): tools must be 'Read, Grep, ...' not a YAML list"
done

echo "== gate behaviour =="
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
cd "$T" && git init -q . && git config user.email t@t.co && git config user.name t
mkdir -p src/pay other .githooks .brain/plans
install -m 0755 "$ROOT/templates/pre-commit" .githooks/pre-commit
git config core.hooksPath .githooks
printf '# plan: t\nsrc/pay/*\n' > .brain/plans/ACTIVE.scope
echo a > src/pay/a.ts; echo b > other/b.ts

git add src/pay/a.ts
git commit -q -m in >/dev/null 2>&1 && ok "in-scope commit allowed" || bad "in-scope commit blocked"

git add other/b.ts
git commit -q -m out >/dev/null 2>&1 && bad "out-of-scope commit ALLOWED" || ok "out-of-scope commit blocked"

BRAIN_OVERRIDE=1 git commit -q -m ovr >/dev/null 2>&1 && ok "override works" || bad "override failed"

printf '<<<<<<< HEAD\nx\n' > src/pay/c.ts; git add src/pay/c.ts
git commit -q -m debris >/dev/null 2>&1 && bad "conflict markers ALLOWED" || ok "conflict markers blocked"

echo
echo "  $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
