#!/usr/bin/env bash
# stop — chain next tick if RUNNING; block if unanswered QUESTIONS; fail safe.
#
# All parsing lives in harness_questions_state.py, shared with session-start.sh
# (single source of truth for open-question detection). The hook JSON payload
# from stdin is forwarded to the parser's `stop` mode, which reproduces the
# original contract: chained events emit {}, BLOCKED/open questions emit a
# do-not-start message, RUNNING chains the next tick.
#
# Fail-safe: if python or the parser is unavailable, emit a message that tells
# the agent to verify QUESTIONS.md manually — never a wrong "continue".
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HOOK_DIR/../.." && pwd)"
PARSER="$HOOK_DIR/harness_questions_state.py"

# shellcheck source=_python.sh
. "$HOOK_DIR/_python.sh"

PAYLOAD=""
if [[ ! -t 0 ]]; then
  PAYLOAD="$(cat)"
fi

OUT=""
if hb_run_python "$PARSER" stop "$ROOT" >/tmp/fos_stop.$$ 2>/dev/null <<<"$PAYLOAD"; then
  OUT="$(cat /tmp/fos_stop.$$)"
fi
rm -f /tmp/fos_stop.$$ 2>/dev/null || true

if [[ "$OUT" == '{'* ]]; then
  printf '%s\n' "$OUT"
  exit 0
fi

# Fallback: no python / parser failure → honest, neutral message (valid JSON).
printf '%s\n' '{"followup_message":"HARNESS: could not verify loop state (python or parser unavailable). Before starting another card, manually confirm harness/LOOP_STATE.md is RUNNING and QUESTIONS.md has no unanswered Answer lines. Hard stop = unanswered QUESTIONS only."}'
