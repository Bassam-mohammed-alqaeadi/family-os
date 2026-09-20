#!/bin/bash
# beforeSubmitPrompt — audit trail. Observe-only. bash+grep only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AUDIT_DIR="$ROOT/.cursor/audit"
mkdir -p "$AUDIT_DIR"
LOG="$AUDIT_DIR/prompts.log"

input=$(cat)
flat=$(printf '%s' "$input" | tr '\n' ' ')
prompt=$(printf '%s' "$flat" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
# If prompt had escaped content truncated by sed, fall back to raw slice
if [ -z "$prompt" ]; then
  prompt=$(printf '%s' "$flat" | cut -c1-200)
fi

# First 200 chars
snippet=$(printf '%s' "$prompt" | sed 's/\\"/"/g; s/\\n/ /g' | cut -c1-200)
ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)
printf '%s %s\n' "$ts" "$snippet" >> "$LOG"

printf '{"continue":true}\n'
exit 0
