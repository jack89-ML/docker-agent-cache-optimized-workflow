#!/usr/bin/env bash
# ============================================================================
# test_scaffold.sh — smoke test for scaffold_agent.sh
# Checks: syntax (bash -n), usage error on missing args, template presence,
# and the env-file-not-found guard. Does NOT create containers.
# ============================================================================
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
FAIL=0

echo "— syntax check (bash -n)"
bash -n scripts/scaffold_agent.sh || FAIL=1
bash -n scripts/usage_report.sh || FAIL=1

echo "— usage error on missing args"
if bash scripts/scaffold_agent.sh 2>/dev/null; then
  echo "  FAIL: expected usage error"; FAIL=1
else
  echo "  ✓ usage error raised"
fi

echo "— env-file-not-found guard"
TMPD=$(mktemp -d)
if bash scripts/scaffold_agent.sh demo nousresearch/hermes-agent "$TMPD" /nonexistent.env 2>/dev/null; then
  echo "  FAIL: expected env-file error"; FAIL=1
else
  echo "  ✓ env-file guard raised"
fi
rm -rf "$TMPD"

echo "— templates present"
for t in CONTEXT MASTER_PLAN TASK_LIST AGENT_PROMPT; do
  [ -f "templates/${t}_TEMPLATE.md" ] || { echo "  FAIL: missing ${t}_TEMPLATE.md"; FAIL=1; }
done
[ -f templates/AGENT_PROMPT_TEMPLATE.md ] && echo "  ✓ 4 templates present"

echo "— no local paths / secrets in published files"
if grep -rnE "/mnt/|/home/hermes|vault|osint|jperacchio|192\.168|10\.202|sk-[A-Za-z0-9]{16,}" \
     --include="*.md" --include="*.sh" . 2>/dev/null \
     | grep -v "\.git/" | grep -v "test_scaffold.sh"; then
  echo "  FAIL: sensitive reference found"; FAIL=1
else
  echo "  ✓ clean"
fi

if [ "$FAIL" -eq 0 ]; then
  echo "ALL TESTS PASSED"
else
  echo "TESTS FAILED"
  exit 1
fi
