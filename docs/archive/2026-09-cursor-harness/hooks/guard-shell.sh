#!/bin/bash
# beforeShellExecution — HARD GATE (deny / ask / allow). bash+grep only.
# Enforces: Rule 21 (protected paths), repo safety, Rule 22 (git discipline).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 0

input=$(cat)
# Extract "command" string value (first occurrence). No jq — bash+grep only.
cmd=$(printf '%s' "$input" | tr '\n' ' ' | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
# Unescape common JSON sequences for matching
cmd=$(printf '%s' "$cmd" | sed 's/\\n/ /g; s/\\t/ /g; s/\\"/"/g; s/\\\\/\\/g')

deny() {
  printf '{"permission":"deny","user_message":"%s","agent_message":"%s"}\n' "$1" "$1"
  exit 0
}
ask() {
  printf '{"permission":"ask","user_message":"%s","agent_message":"%s"}\n' "$1" "$1"
  exit 0
}
allow() {
  printf '{"permission":"allow"}\n'
  exit 0
}

[ -z "$cmd" ] && allow

# --- Danger guard ---
# curl|sh / curl|bash
if printf '%s' "$cmd" | grep -qE 'curl[^|;]*\|[[:space:]]*(sh|bash)|wget[^|;]*\|[[:space:]]*(sh|bash)'; then
  deny "Blocked: curl|sh style pipe is forbidden"
fi

# force-push to main/master
if printf '%s' "$cmd" | grep -qE 'git[[:space:]]+push'; then
  if printf '%s' "$cmd" | grep -qE '\-\-force|\-f([[:space:]]|$)|force\-with\-lease'; then
    if printf '%s' "$cmd" | grep -qE '(^|[[:space:]/])(main|master)([[:space:]]|$)'; then
      deny "Blocked: force-push to main/master is forbidden"
    fi
  fi
fi

# rm -rf outside build dirs
if printf '%s' "$cmd" | grep -qE 'rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*)'; then
  rest=$(printf '%s' "$cmd" | sed -E 's/.*rm[[:space:]]+-?[a-zA-Z-]*[[:space:]]*//')
  unsafe=$(printf '%s\n' $rest | grep -vE '^-' | grep -vE '^(build|\.dart_tool|node_modules|coverage|dist)(/.*)?$' | grep -vE '^$' || true)
  if [ -n "$unsafe" ]; then
    deny "Blocked: rm -rf outside build/cache dirs is forbidden"
  fi
fi

# --- Protected-path guard (Rule 21) ---
# Write-ish ops touching protected paths → deny
is_write=0
if printf '%s' "$cmd" | grep -qE '(^|[[:space:]])(rm|mv|cp|tee|truncate|sed|perl|ruby|python|node|install)([[:space:]]|$)|>>?|tee[[:space:]]|sed[[:space:]]+-i'; then
  is_write=1
fi
# redirect append/overwrite
if printf '%s' "$cmd" | grep -qE '>|>>'; then
  is_write=1
fi

if [ "$is_write" -eq 1 ]; then
  if printf '%s' "$cmd" | grep -qE 'core/policy/|lib/core/design/tokens\.dart|(^|[^a-zA-Z])tokens\.dart|\.cursor/rules/|\.cursor/hooks|\.cursor/hooks\.json|handoff/'; then
    deny "Blocked Rule 21: shell must not write core/policy, tokens.dart, .cursor/, or handoff/ (owner decision required)"
  fi
fi

# --- Git discipline (Rule 22) ---
# git push → ask (owner sees it)
if printf '%s' "$cmd" | grep -qE '(^|[[:space:];&|])git[[:space:]]+push([[:space:]]|$)'; then
  ask "Confirm git push (owner gate). Rule 22 / push discipline."
fi

# git commit touching >1 feature dir → deny
if printf '%s' "$cmd" | grep -qE '(^|[[:space:];&|])git[[:space:]]+commit([[:space:]]|$)'; then
  staged=$(git diff --cached --name-only 2>/dev/null || true)
  if [ -n "$staged" ]; then
    feat_count=$(printf '%s\n' "$staged" | grep -E '(^|/)(lib/)?features/[^/]+/' | sed -E 's|.*features/([^/]+)/.*|\1|' | sort -u | grep -c . || true)
    if [ "${feat_count:-0}" -gt 1 ]; then
      deny "Blocked Rule 22: commit touches more than one feature directory"
    fi
  fi
fi

allow
