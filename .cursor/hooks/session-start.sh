#!/usr/bin/env bash
# sessionStart — inject LOOP_STATE + QUESTIONS + next card into the session.
#
# All parsing lives in harness_questions_state.py, shared with on-stop.sh, so
# both hooks use the same open-question detection (single source of truth).
# The old inline grep/python version mis-detected placeholders (bad grep -E
# alternation) and double-counted via `grep -c ... || echo 0` under pipefail.
#
# Fail-safe: if python or the parser is unavailable, emit a neutral context
# that tells the agent to verify state manually — never a wrong "all clear".
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HOOK_DIR/../.." && pwd)"
PARSER="$HOOK_DIR/harness_questions_state.py"

# shellcheck source=_python.sh
. "$HOOK_DIR/_python.sh"

OUT=""
if hb_run_python "$PARSER" context "$ROOT" >/tmp/fos_ctx.$$ 2>/dev/null; then
  OUT="$(cat /tmp/fos_ctx.$$)"
fi
rm -f /tmp/fos_ctx.$$ 2>/dev/null || true

if [[ "$OUT" == '{'* ]]; then
  printf '%s\n' "$OUT"
  exit 0
fi

# Fallback: no python / parser failure → honest, neutral context (valid JSON).
printf '%s\n' '{"additional_context":"FAMILY OS HARNESS — context unavailable (python or parser missing). Before any task: read harness/LOOP_STATE.md and QUESTIONS.md manually. Loop state could NOT be verified. Hard stop = unanswered QUESTIONS only."}'
