#!/bin/bash
# stop — closer. Surfaces new HOOK_ALERTS + CONVERSION_LOG reminder.
# Uses followup_message only once per natural completion (loop_count==0) to avoid loops.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

ALERTS="$ROOT/HOOK_ALERTS.md"
WATERMARK="$ROOT/.cursor/hooks/.alerts_watermark"
mkdir -p "$ROOT/.cursor/hooks"

input=$(cat)
flat=$(printf '%s' "$input" | tr '\n' ' ')
loop_count=$(printf '%s' "$flat" | sed -n 's/.*"loop_count"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' | head -1)
loop_count=${loop_count:-0}

# Current alert data-row count (exclude header)
cur=0
if [ -f "$ALERTS" ]; then
  cur=$(grep -cE '^\| [0-9]{4}-' "$ALERTS" 2>/dev/null || true)
fi
cur=${cur:-0}

prev=0
if [ -f "$WATERMARK" ]; then
  prev=$(cat "$WATERMARK" 2>/dev/null || echo 0)
fi
prev=${prev:-0}

new_count=$((cur - prev))
if [ "$new_count" -lt 0 ]; then
  new_count=0
fi

msg=""

if [ "$new_count" -gt 0 ]; then
  # Print new lines to stderr (Hooks output channel / logs)
  if [ -f "$ALERTS" ]; then
    echo "=== HOOK_ALERTS (new this turn: $new_count) ===" >&2
    grep -E '^\| [0-9]{4}-' "$ALERTS" | tail -n "$new_count" >&2 || true
  fi
  msg="HOOK ALERTS: $new_count new violation line(s) appended to HOOK_ALERTS.md — review before continuing."
fi

# CONVERSION_LOG reminder if lib/ dirty but log not updated
lib_dirty=0
log_dirty=0
if git status --porcelain 2>/dev/null | grep -qE '(^..|^\?\?) .*lib/'; then
  lib_dirty=1
fi
if git status --porcelain 2>/dev/null | grep -qE 'CONVERSION_LOG\.md'; then
  log_dirty=1
fi
if [ "$lib_dirty" -eq 1 ] && [ "$log_dirty" -eq 0 ]; then
  remind="Reminder Rule 20: lib/ changed but CONVERSION_LOG.md has no pending update — append the screen line before you finish."
  if [ -n "$msg" ]; then
    msg="$msg $remind"
  else
    msg="$remind"
  fi
fi

# Update watermark after we have reported
printf '%s\n' "$cur" > "$WATERMARK"

# Only auto-follow up on first stop of a completion cycle
if [ -n "$msg" ] && [ "$loop_count" -eq 0 ]; then
  # Escape for JSON string
  safe=$(printf '%s' "$msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '{"followup_message":"%s"}\n' "$safe"
  exit 0
fi

printf '{}\n'
exit 0
