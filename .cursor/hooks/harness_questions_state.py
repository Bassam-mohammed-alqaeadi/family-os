#!/usr/bin/env python3
"""Single source of truth for Family OS harness loop state.

Parses harness/LOOP_STATE.md and QUESTIONS.md so both Cursor hooks
(session-start.sh, on-stop.sh) agree on:
  - loop status (RUNNING / BLOCKED / STOPPED)
  - whether any question has an unanswered / placeholder Answer

An Answer counts as OPEN (placeholder) when it is:
  - missing entirely (no **Answer:** line under the question), or
  - empty, or
  - an underscore placeholder: "_<Bassam>_", "_(Bassam)_", "_Bassam_", "___", or
  - a non-answer: TBD / TBA / TODO / pending / N/A / none / x / ? / "..." / "…"

Anything else is a real answer. This matches harness/09_RESUME_PROTOCOL.md:
"fill **Answer:** with a real decision and a date (not '_<Bassam>_' placeholders)".

The Answer must be on the same line as the label (QUESTIONS.md convention).

CLI (used by the hooks; also handy for debugging):
  python harness_questions_state.py state   [PROJECT_ROOT]   # JSON state
  python harness_questions_state.py context [PROJECT_ROOT]   # sessionStart payload
  python harness_questions_state.py stop    [PROJECT_ROOT] < payload.json
                                                             # stop-hook payload
"""

from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------- placeholders

# Non-answer words/symbols. Checked against the lowercased text, and again
# after stripping trailing dots (so "..." and "TBD." both count as open).
_NON_ANSWERS = {
    "tbd", "tba", "todo", "pending", "n/a", "na", "none", "nil",
    "x", "xx", "xxx", "?", "??", "???", "...", "....", "…",
}


def is_open_answer(text: str | None) -> bool:
    """True when the Answer text is a placeholder / not a real decision."""
    if text is None:
        return True
    t = text.strip()
    if not t:
        return True
    low = t.lower()
    if low in _NON_ANSWERS or low.rstrip(".") in _NON_ANSWERS:
        return True
    # Punctuation-only answers of any length: "?", "??", ".", "....", "…?", "-", "—"
    if re.fullmatch(r"[?._…\-*—–]+", t):
        return True
    # Underscore placeholder: strip underscores, whitespace and wrapper
    # punctuation; whatever remains must be empty or just the owner name.
    stripped = re.sub(r"[\s_<>()\[\]]+", "", t)
    if not stripped or stripped.lower() == "bassam":
        return True
    return False


# ------------------------------------------------------------------- parsing

# Matches "**Answer:** text", "Answer: text", "**Answer:**" (bold label), "Answer:".
_ANSWER_RX = re.compile(
    r"^\s*\*{0,2}\s*answer\s*\*{0,2}\s*:\s*\*{0,2}\s*(.*)$",
    re.MULTILINE | re.IGNORECASE,
)

# LOOP_STATE.md fenced block: "status: RUNNING" / "current_card: SET-005" / "blocked_by: (none)"
_STATUS_RX = re.compile(r"^\s*status\s*:\s*([A-Za-z]+)\s*$", re.MULTILINE)
_CURRENT_CARD_RX = re.compile(r"^\s*current_card\s*:\s*(.+?)\s*$", re.MULTILINE)
_BLOCKED_BY_RX = re.compile(r"^\s*blocked_by\s*:\s*(.+?)\s*$", re.MULTILINE)

_KNOWN_STATUSES = {"RUNNING", "BLOCKED", "STOPPED"}


def parse_questions(text: str) -> list[dict]:
    """Parse QUESTIONS.md into dicts: {id, answer, open}.

    Question blocks start at '### ' headings (QUESTIONS.md convention).
    A question is OPEN when it has no **Answer:** line, or its last
    **Answer:** line is a placeholder.
    """
    questions: list[dict] = []
    blocks = re.split(r"(?m)^###\s+", text)[1:]  # preamble before first '### ' is not a question
    for block in blocks:
        lines = block.splitlines()
        header = lines[0].strip() if lines else "(untitled)"
        matches = _ANSWER_RX.findall(block)
        if not matches:
            questions.append({"id": header, "answer": None, "open": True})
            continue
        answer = matches[-1].strip()  # most recent Answer wins (append-only convention)
        questions.append({"id": header, "answer": answer or None, "open": is_open_answer(answer)})
    return questions


def open_question_count(text: str) -> int:
    """Number of questions in QUESTIONS.md awaiting a real owner Answer."""
    return sum(1 for q in parse_questions(text) if q["open"])


def open_question_ids(text: str, limit: int = 5) -> list[str]:
    """Ids (question headers) of open questions, truncated to `limit`."""
    return [q["id"] for q in parse_questions(text) if q["open"]][:limit]


def loop_status(text: str) -> str:
    """Uppercased status from LOOP_STATE.md; default RUNNING."""
    m = _STATUS_RX.search(text)
    if not m:
        return "RUNNING"
    status = m.group(1).upper()
    return status if status in _KNOWN_STATUSES else "RUNNING"


def current_card(text: str) -> str:
    m = _CURRENT_CARD_RX.search(text)
    return m.group(1).strip() if m else "unknown"


def blocked_by(text: str) -> str:
    m = _BLOCKED_BY_RX.search(text)
    return m.group(1).strip() if m else "(none)"


# ------------------------------------------------------------ combined lookup

def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    except OSError:
        return ""


def next_backlog_line(backlog_text: str) -> str:
    """First BACKLOG.md table row carrying the NEXT marker, else a ready row.

    Only table rows (starting with '|') count, so the prose explanation of the
    NEXT marker near the top of the file is never mistaken for the card row.
    """
    for line in backlog_text.splitlines():
        s = line.strip()
        if s.startswith("|") and "NEXT" in s:
            return s
    for line in backlog_text.splitlines():
        if re.search(r"\|\s*\*?ready\*?\s*\|", line):
            return line.strip()
    return "See harness/BACKLOG.md"


def harness_state(root: Path) -> dict:
    """Read LOOP_STATE.md + QUESTIONS.md (+ BACKLOG/GAP hints) under `root`."""
    state_text = _read(root / "harness" / "LOOP_STATE.md")
    questions_text = _read(root / "QUESTIONS.md")
    backlog_text = _read(root / "harness" / "BACKLOG.md")
    gap_text = _read(root / "GAP_LOG.md")
    return {
        "status": loop_status(state_text) if state_text else "UNKNOWN",
        "current_card": current_card(state_text) if state_text else "unknown",
        "blocked_by": blocked_by(state_text) if state_text else "unknown",
        "open_questions": open_question_ids(questions_text),
        "open_count": open_question_count(questions_text),
        "open_gaps": gap_text.count("CONVERSION-BACKLOG"),
        "next_hint": next_backlog_line(backlog_text),
        "has_state_file": bool(state_text),
        "has_questions_file": bool(questions_text),
    }


# ------------------------------------------------------------ ship gate (P9)


def _load_verify_ship():
    """Load the verify-before-ship verifier from this directory (optional)."""
    vpath = Path(__file__).resolve().parent / "verify_ship.py"
    try:
        spec = importlib.util.spec_from_file_location("verify_ship", vpath)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        return mod
    except Exception:
        return None


def verify_pending(root: Path) -> dict:
    """Predicate: is the newest shipped card lacking passing verification?

    Fail-safe: if the verifier itself is unavailable, report pending so the
    gate degrades to "verify manually" rather than silently passing.
    """
    mod = _load_verify_ship()
    if mod is None:
        return {"pending": True, "card_id": "?", "reason": "verifier unavailable — verify manually"}
    try:
        return mod.verification_status(root)
    except Exception as exc:  # never let the gate crash the hook
        return {"pending": True, "card_id": "?", "reason": f"verifier error: {exc}"}


# ------------------------------------------------------------- hook payloads

def build_context(root: Path) -> dict:
    """Payload for the sessionStart hook (Cursor: additional_context)."""
    s = harness_state(root)
    warnings: list[str] = []
    if not s["has_state_file"] or s["status"] == "UNKNOWN":
        warnings.append("⚠ LOOP_STATE.md missing/unreadable — verify harness state manually.")
    if not s["has_questions_file"]:
        warnings.append("⚠ QUESTIONS.md missing — create it before asking the owner anything.")
    elif s["open_count"] > 0:
        warnings.append(
            "⚠ BLOCKED: " + str(s["open_count"]) + " unanswered question(s) — "
            "answer QUESTIONS.md first; do NO product work."
        )
    lines = [
        "FAMILY OS HARNESS — CONTINUOUS LOOP",
        "LOOP_STATE: " + s["status"] + " | card: " + s["current_card"] + " | blocked_by: " + s["blocked_by"],
        "Next: " + s["next_hint"],
        "Open questions: " + str(s["open_count"])
        + (" [" + " | ".join(s["open_questions"]) + "]" if s["open_questions"] else " [(none)]"),
        "Open GAP_LOG CONVERSION-BACKLOG rows: " + str(s["open_gaps"]),
    ]
    gate = verify_pending(root)
    if gate["pending"]:
        lines.append("⚠ Ship gate: card " + str(gate.get("card_id")) + " NOT verified ("
                     + gate["reason"] + ") — before shipping the NEXT card, run: "
                     "python .cursor/hooks/verify_ship.py verify")
    else:
        lines.append("Ship gate: previous card verified ✓")
    lines.extend([
        *warnings,
        "Hard stop = unanswered QUESTIONS only. After Ship → continue next card.",
        "Tick: harness/04_LOOP_PROMPT.md | Resume: harness/09_RESUME_PROTOCOL.md",
    ])
    return {"additional_context": "\n".join(lines)}


def build_stop_followup(root: Path, hook_input: dict) -> dict:
    """Payload for the stop hook (Cursor: followup_message).

    Replicates the original contract:
      - chained events (loop_count != 0) emit {} (no re-prompt),
      - BLOCKED / open questions → do-not-start-next-card message,
      - STOPPED → resume hint,
      - RUNNING → chain the next tick.
    Fail-safe additions: a missing QUESTIONS.md or unreadable LOOP_STATE.md
    yields a verify-manually message — never a wrong "continue".
    """
    loop = hook_input.get("loop_count") or hook_input.get("loopCount") or 0
    if loop:
        return {}

    s = harness_state(root)

    if not s["has_questions_file"]:
        return {"followup_message": (
            "HARNESS: QUESTIONS.md is missing — cannot verify that no owner questions are open. "
            "Before starting another card, confirm manually. Hard stop = unanswered QUESTIONS only."
        )}
    if s["status"] == "BLOCKED" or s["open_count"] > 0:
        ids = " | ".join(s["open_questions"]) if s["open_questions"] else "(see QUESTIONS.md)"
        return {"followup_message": (
            "HARNESS BLOCKED — unanswered QUESTIONS.md (" + ids + "). "
            "Do not start the next card. Bassam: answer under the question, then say "
            "'resume harness' (see harness/09_RESUME_PROTOCOL.md)."
        )}

    # Ship-gate backstop (P9): the newest CONVERSION_LOG card must have passing
    # flutter analyze + test evidence before the loop chains the next tick.
    # This does not block the loop permanently — it blocks CHAINING until
    # verify runs, which is exactly "no ship without verification".
    gate = verify_pending(root)
    if gate["pending"]:
        return {"followup_message": (
            "HARNESS SHIP GATE: card " + str(gate.get("card_id"))
            + " is not verified — " + gate["reason"] + ". "
            "Run `python .cursor/hooks/verify_ship.py verify` (flutter analyze + test in app/). "
            "If it fails, fix and re-run; do not start the next card until it passes."
        )}

    if s["status"] == "STOPPED":
        return {"followup_message": (
            "HARNESS STOPPED. Say 'resume harness' or run harness/04_LOOP_PROMPT.md to continue."
        )}
    if s["status"] == "UNKNOWN":
        return {"followup_message": (
            "HARNESS: could not verify LOOP_STATE.md (missing/unreadable). Before starting "
            "another card, manually confirm QUESTIONS.md has no unanswered **Answer:** lines. "
            "Hard stop = unanswered QUESTIONS only."
        )}
    return {"followup_message": (
        "HARNESS CONTINUOUS LOOP: LOOP_STATE is RUNNING. "
        "If you just Shipped a card, immediately run the next tick — "
        "paste and execute harness/04_LOOP_PROMPT.md for the NEXT ready card. "
        "Do not wait for Bassam unless you must write QUESTIONS.md. "
        "If leaving the session, arm /loop 20m with that same prompt."
    )}


# ---------------------------------------------------------------------- CLI

def _project_root(argv: list[str]) -> Path:
    """argv is sys.argv[1:]: [mode, PROJECT_ROOT?]. Root defaults to cwd."""
    if len(argv) > 1:
        return Path(argv[1]).resolve()
    return Path.cwd()


def main(argv: list[str]) -> int:
    if not argv:
        print("usage: harness_questions_state.py state|context|stop [PROJECT_ROOT]", file=sys.stderr)
        return 2
    mode = argv[0]
    root = _project_root(argv)
    if mode == "state":
        print(json.dumps(harness_state(root), ensure_ascii=False, indent=2))
    elif mode == "context":
        print(json.dumps(build_context(root), ensure_ascii=False))
    elif mode == "stop":
        raw = ""
        if not sys.stdin.isatty():
            raw = sys.stdin.read()
        try:
            hook_input = json.loads(raw) if raw.strip() else {}
        except json.JSONDecodeError:
            hook_input = {}
        print(json.dumps(build_stop_followup(root, hook_input), ensure_ascii=False))
    else:
        print("unknown mode: " + mode, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
