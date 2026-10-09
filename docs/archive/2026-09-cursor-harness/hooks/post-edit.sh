#!/bin/bash
# afterFileEdit — tripwires + dart format. Observe-only. bash+grep (+ dart format if present).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

input=$(cat)
flat=$(printf '%s' "$input" | tr '\n' ' ')
file_path=$(printf '%s' "$flat" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
# Normalize Windows paths
file_path=$(printf '%s' "$file_path" | sed 's|\\\\|/|g')

ALERTS="$ROOT/HOOK_ALERTS.md"
WATERMARK="$ROOT/.cursor/hooks/.alerts_watermark"
mkdir -p "$ROOT/.cursor/hooks"

alert() {
  rule="$1"
  detail="$2"
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date)
  # Sanitize pipes in detail for table row
  safe_path=$(printf '%s' "$file_path" | tr '|' '/')
  safe_detail=$(printf '%s' "$detail" | tr '|' '/' | tr '\n' ' ' | cut -c1-200)
  printf '| %s | %s | %s | %s |\n' "$ts" "$safe_path" "$rule" "$safe_detail" >> "$ALERTS"
}

[ -z "$file_path" ] && printf '{}\n' && exit 0

# Relative path helpers
rel="$file_path"
case "$file_path" in
  "$ROOT"/*) rel="${file_path#"$ROOT"/}" ;;
esac

# --- Auto-format (Rule 18 half) ---
if printf '%s' "$rel" | grep -qE '(^|/)lib/.*\.dart$'; then
  if command -v dart >/dev/null 2>&1 && [ -f "$file_path" ]; then
    dart format "$file_path" >/dev/null 2>&1 || true
  fi
fi

# Build text to scan: prefer new_string snippets from edits, else file contents
scan=""
if printf '%s' "$input" | grep -q 'new_string'; then
  scan=$(printf '%s' "$input" | tr '\n' ' ')
elif [ -f "$file_path" ]; then
  scan=$(head -c 200000 "$file_path" 2>/dev/null || true)
fi

# --- Protected-file alarm (Rule 21 backstop) ---
if printf '%s' "$rel" | grep -qE '(^|/)(core/policy/|lib/core/design/tokens\.dart|\.cursor/rules/|handoff/)'; then
  alert "Rule21" "PROTECTED PATH edited via Write tool (shell gate cannot block this). Review immediately."
  diff_out="$ROOT/.cursor/hooks/protected-edit-$(date +%s).diff"
  git diff -- "$file_path" > "$diff_out" 2>/dev/null || true
  alert "Rule21" "git diff saved to ${diff_out#"$ROOT"/}"
fi

# --- Currency tripwire (Rule 4) ---
if printf '%s' "$scan" | grep -qiE 'points|coins|\bxp\b|نقطة|نقاط'; then
  # Soft context: reward/balance/wallet nearby OR always flag in lib/
  if printf '%s' "$rel" | grep -qE '(^|/)lib/' || printf '%s' "$scan" | grep -qiE 'reward|balance|wallet|earn|currency'; then
    alert "Rule4" "Currency tripwire: points/coins/xp/نقاط found — only minutes allowed"
  fi
fi

# --- Hardcoded-string tripwire (Rule 12) ---
# Text('…') or Text("…") containing Arabic letters
if printf '%s' "$rel" | grep -qE '(^|/)lib/' && ! printf '%s' "$rel" | grep -qE '\.arb$|/l10n/|/gen/'; then
  if printf '%s' "$scan" | grep -qE "Text[[:space:]]*\([[:space:]]*['\"][^'\"]*[؀-ۿ][^'\"]*['\"]"; then
    alert "Rule12" "Hardcoded Arabic Text(...) literal outside ARB/i18n"
  fi
fi

# --- Child-name tripwire (Rules 13, 23) ---
if ! printf '%s' "$rel" | grep -qE '(^|/)mock/|\.arb$'; then
  if printf '%s' "$scan" | grep -qE 'Khaled|Noura|Saad|خالد|نورة|سعد'; then
    alert "Rule13/23" "Child name literal outside mock/ and ARB"
  fi
fi

# --- Raw-color tripwire (Rule 14) ---
if printf '%s' "$rel" | grep -qE '(^|/)(lib/)?features/'; then
  if printf '%s' "$scan" | grep -qE 'Color[[:space:]]*\([[:space:]]*0x'; then
    alert "Rule14" "Raw Color(0x...) inside features/ — use tokens.dart"
  fi
fi

printf '{}\n'
exit 0
