# shellcheck shell=bash
# Shared helper for Family OS Cursor hooks: resolve a working python
# interpreter. Windows often ships only the `py` launcher (and Store stubs
# that exit nonzero), POSIX boxes usually have python3. Sourced by
# session-start.sh and on-stop.sh so the resolution logic lives in one place.
hb_run_python() {
  local cand
  for cand in python3 python py; do
    if command -v "$cand" >/dev/null 2>&1; then
      # Verify the interpreter actually runs (rejects Windows Store stubs).
      if [[ "$cand" == "py" ]]; then
        if py -3 -c 'import sys' >/dev/null 2>&1; then
          py -3 "$@"
          return 0
        fi
      elif "$cand" -c 'import sys' >/dev/null 2>&1; then
        "$cand" "$@"
        return 0
      fi
    fi
  done
  return 127
}
