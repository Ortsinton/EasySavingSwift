#!/bin/bash
# SessionStart hook: injects the latest docs/TASK_LOG.md entry and the ADR
# index into Claude's context so every session starts with project state
# without being asked. CLAUDE.md is already auto-loaded by Claude Code.
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

tasklog="docs/TASK_LOG.md"
adr="docs/ADR.md"
ctx=""

if [[ -f "$tasklog" ]]; then
  last_header=$(grep -n '^## ' "$tasklog" | tail -1 | cut -d: -f1)
  ctx+="# Latest entry in docs/TASK_LOG.md"$'\n\n'
  ctx+=$(tail -n +"$last_header" "$tasklog")$'\n\n'
fi

if [[ -f "$adr" ]]; then
  ctx+="# ADR index (docs/ADR.md)"$'\n'
  ctx+="Read the full ADR section in docs/ADR.md whenever a task references one of these:"$'\n\n'
  ctx+=$(grep '^## ' "$adr")$'\n'
fi

jq -n --arg ctx "$ctx" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
