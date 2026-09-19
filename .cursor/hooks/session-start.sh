#!/bin/bash
# sessionStart — inject constitution context. bash+grep only.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GAP="$ROOT/GAP_LOG.md"

# Count open gaps: data rows whose Status is not closed/done/resolved
open=0
if [ -f "$GAP" ]; then
  open=$(grep -E '^\|[[:space:]]*[A-Za-z0-9_-]+[[:space:]]*\|' "$GAP" \
    | grep -v 'Screen ID' \
    | grep -vE '^\|[[:space:]]*-+' \
    | grep -viE '\|[[:space:]]*(closed|done|resolved)[[:space:]]*\|[[:space:]]*$' \
    | grep -c . || true)
fi
open=${open:-0}

# Reset alerts watermark baseline for the session (optional soft reset — keep absolute count)
WATERMARK="$ROOT/.cursor/hooks/.alerts_watermark"
mkdir -p "$ROOT/.cursor/hooks"
if [ -f "$ROOT/HOOK_ALERTS.md" ]; then
  cur=$(grep -cE '^\| [0-9]{4}-' "$ROOT/HOOK_ALERTS.md" 2>/dev/null || true)
  printf '%s\n' "${cur:-0}" > "$WATERMARK"
else
  printf '0\n' > "$WATERMARK"
fi

ctx="Constitution v26 in force. Check QUESTIONS.md for owner answers. GAP_LOG.md has ${open} open gaps."
safe=$(printf '%s' "$ctx" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"additional_context":"%s"}\n' "$safe"
exit 0
