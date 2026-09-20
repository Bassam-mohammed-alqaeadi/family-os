#!/bin/bash
# beforeMCPExecution — MCP GATE (deny / allow). bash+grep only.
# Enforces: M-1 (GitHub scope = family-os only), M-3 (secret hygiene).
set -euo pipefail

input=$(cat)

deny() {
  printf '{"permission":"deny","user_message":"%s","agent_message":"%s"}\n' "$1" "$1"
  exit 0
}
allow() {
  printf '{"permission":"allow"}\n'
  exit 0
}

# Flatten for grepping
flat=$(printf '%s' "$input" | tr '\n' ' ')

server=$(printf '%s' "$flat" | sed -n 's/.*"mcp_server_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
tool=$(printf '%s' "$flat" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
# tool_input may be a JSON string value
tool_input=$(printf '%s' "$flat" | sed -n 's/.*"tool_input"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
# Also scan raw payload (tool_input might be nested object)
payload="$flat"

# --- M-3 Secret hygiene ---
if printf '%s' "$payload" | grep -qE 'github_pat_[A-Za-z0-9_]+|Bearer[[:space:]]+[A-Za-z0-9._\-]+|sk-[A-Za-z0-9]{20,}|api[_-]?key[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_\-]{16,}'; then
  deny "Blocked M-3: MCP payload appears to contain a secret (PAT/Bearer/API key)"
fi

# --- M-1 GitHub MCP scope ---
# Only when server looks like GitHub
if printf '%s' "$server $tool $payload" | grep -qiE 'github|gh_'; then
  # Allow only if family-os is referenced, or no foreign owner/repo is clear.
  # Deny when an owner/repo other than *family-os* is targeted.
  if printf '%s' "$payload" | grep -qiE 'owner[[:space:]]*[:=][[:space:]]*["'\'']?[A-Za-z0-9_.-]+|repos/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+|"repo"[[:space:]]*:[[:space:]]*"[^"]+"'; then
    if ! printf '%s' "$payload" | grep -qiE 'family-os|Bassam-mohammed-alqaeadi/family-os'; then
      # Has a repo-ish target but not family-os → deny
      if printf '%s' "$payload" | grep -qiE 'repos/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+'; then
        if ! printf '%s' "$payload" | grep -qiE 'repos/[^/"'\'']+/family-os'; then
          deny "Blocked M-1: GitHub MCP may only target the family-os repository"
        fi
      fi
      # Explicit owner+name without family-os
      if printf '%s' "$payload" | grep -qiE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' \
        && printf '%s' "$payload" | grep -qiE '"owner"[[:space:]]*:'; then
        if ! printf '%s' "$payload" | grep -qiE 'family-os'; then
          deny "Blocked M-1: GitHub MCP may only target the family-os repository"
        fi
      fi
    fi
  fi
  # Hard deny known foreign repo literals
  if printf '%s' "$payload" | grep -qiE 'repos/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+'; then
    if ! printf '%s' "$payload" | grep -qiE 'family-os'; then
      deny "Blocked M-1: GitHub MCP may only target the family-os repository"
    fi
  fi
fi

allow
