#!/usr/bin/env python3
"""Verify-before-ship gate for the Family OS harness (P9).

Blocks a card from counting as "done" unless `flutter analyze` and
`flutter test` actually pass in app/ AFTER the card was appended to
CONVERSION_LOG.md. Evidence is recorded per card in .verify/<CARD_ID>.json
so the loop state ("done") can be checked against a real artifact.

Detection:
  - Newest ship = last CONVERSION_LOG.md line matching the card format
    `YYYY-MM-DD | <task-id> | <summary> | <evidence>`.
  - A card counts as VERIFIED only when evidence exists with status "passed"
    AND the evidence was recorded no earlier than the ship date AND
    CONVERSION_LOG.md has not been modified since the verification ran.

Fail-safe: missing flutter/dart, crashes, or timeouts all count as NOT
verified — never a false "all clear".

CLI:
  python verify_ship.py verify [PROJECT_ROOT] [--skip-test]   # run + record
  python verify_ship.py check  [PROJECT_ROOT]                 # predicate only
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

APP_DIR = "app"
EVIDENCE_DIR = ".verify"
LOG_PATH = Path("CONVERSION_LOG.md")
STATE_PATH = Path("harness") / "LOOP_STATE.md"

# `YYYY-MM-DD | <id> | summary | evidence` — summary/evidence may be empty.
_CARD_RX = re.compile(r"^(\d{4}-\d{2}-\d{2})\s*\|\s*([^|]+?)\s*\|", re.MULTILINE)
_DATE_RX = re.compile(r"^\d{4}-\d{2}-\d{2}$")

_ANALYZE_TIMEOUT = int(os.environ.get("FOS_VERIFY_TIMEOUT_ANALYZE", "240"))
_TEST_TIMEOUT = int(os.environ.get("FOS_VERIFY_TIMEOUT_TEST", "480"))


class VerifyError(Exception):
    pass


# ------------------------------------------------------------------ detection

def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        raise VerifyError(f"cannot read {path}: {exc}") from exc


def newest_shipped_card(root: Path) -> dict | None:
    """Last card line of CONVERSION_LOG.md (the file is append-only)."""
    text = _read_text(root / LOG_PATH)
    matches = _CARD_RX.findall(text)
    if not matches:
        return None
    date, card_id = matches[-1]
    # Summary = the remainder of that final line, minus the trailing evidence cell.
    last_line = ""
    for line in text.splitlines():
        if line.strip().startswith(date) and "|" in line:
            last_line = line.strip()
    summary = ""
    if last_line:
        parts = [p.strip() for p in last_line.split("|")]
        if len(parts) >= 3:
            summary = parts[2]
    return {"date": date, "card_id": card_id, "summary": summary}


def evidence_path(root: Path, card_id: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9._-]+", "_", card_id)
    return root / EVIDENCE_DIR / (safe + ".json")


def load_evidence(root: Path, card_id: str) -> dict | None:
    p = evidence_path(root, card_id)
    if not p.is_file():
        return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


# ----------------------------------------------------------------- predicate

def verification_status(root: Path) -> dict:
    """Is the newest shipped card verified? Pure predicate — runs nothing."""
    card = newest_shipped_card(root)
    if card is None:
        return {"pending": False, "card_id": None,
                "reason": "no shipped card found in CONVERSION_LOG.md"}
    card_id = card["card_id"]

    ev = load_evidence(root, card_id)
    if ev is None:
        return {
            "pending": True,
            "card_id": card_id,
            "summary": card["summary"],
            "reason": "no verification evidence — run: python .cursor/hooks/verify_ship.py verify",
        }

    problems: list[str] = []
    if ev.get("status") != "passed":
        problems.append("last verification did not pass (status=%s)" % ev.get("status"))
    if ev.get("ship_date") != card["date"]:
        problems.append("evidence belongs to a different ship date")
    try:
        log_mtime = (root / LOG_PATH).stat().st_mtime
        if log_mtime > float(ev.get("log_mtime_at_verify", 0)) + 1.0:
            problems.append("CONVERSION_LOG.md changed after verification — re-run verify")
    except OSError:
        problems.append("cannot stat CONVERSION_LOG.md")
    if _stale(card["date"], ev.get("recorded_at", "")):
        problems.append("evidence predates the ship date")

    if problems:
        return {"pending": True, "card_id": card_id, "summary": card["summary"],
                "reason": "; ".join(problems)}
    return {"pending": False, "card_id": card_id, "summary": card["summary"],
            "reason": "verified (evidence %s)" % evidence_path(root, card_id).name}


def _stale(ship_date: str, recorded_iso: str) -> bool:
    """True when evidence was recorded before the ship date (clock-safe: date granularity)."""
    try:
        rec = datetime.fromisoformat(recorded_iso).date().isoformat()
        return rec < ship_date
    except ValueError:
        return True


# ------------------------------------------------------------------- runners

def _run(cmd: list[str], cwd: Path, timeout: int) -> dict:
    # Windows CreateProcess cannot execute .bat/.cmd directly; route via cmd.
    if os.name == "nt" and cmd and cmd[0].lower().endswith((".bat", ".cmd")):
        cmd = ["cmd.exe", "/c", *cmd]
    try:
        proc = subprocess.run(
            cmd, cwd=cwd, timeout=timeout,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            encoding="utf-8", errors="replace",
        )
        return {"ok": proc.returncode == 0, "code": proc.returncode,
                "output": proc.stdout or "", "error": None}
    except FileNotFoundError:
        return {"ok": False, "code": None, "output": "", "error": f"not found: {cmd[0]}"}
    except subprocess.TimeoutExpired:
        return {"ok": False, "code": None, "output": "", "error": f"timeout after {timeout}s: {cmd[0]}"}


def _tail(text: str, lines: int = 25) -> str:
    stripped = "\n".join(text.splitlines()[-lines:]).strip()
    return stripped[-4000:] if stripped else ""


def _test_summary(output: str) -> str:
    m = re.search(r"(\d+)\s*[-–]\s*(\d+)\s*:\s*Some tests failed", output)
    if m:
        return f"FAILED ({m.group(1)} passed / {m.group(2)} failed)"
    m = re.search(r"All tests passed!", output)
    if m:
        return "passed"
    m = re.search(r"(\d+)\s*[-–]\s*(\d+)\s*:", output)
    if m:
        return f"passed ({m.group(1)} passed / {m.group(2)} skipped?)" if "failed" not in output.lower() else "check output"
    return "no summary line found"


def _resolve_tool(name: str, root: Path) -> list[str] | None:
    """Resolve a tool to a spawnable command; None when unavailable.

    Windows: `where` prefers explicit .bat/.cmd/.exe — the extensionless shim
    (a bash script) resolves too but CreateProcess cannot execute it.
    """
    if os.name != "nt":
        probe = _run(["which", name], root, 15)
        return [name] if probe["ok"] else None
    for ext in (".bat", ".cmd", ".exe", ""):
        probe = _run(["where", name + ext], root, 15)
        if probe["ok"] and probe["output"].strip():
            first = probe["output"].strip().splitlines()[0].strip()
            if first:
                return [first]
    return None


def find_flutter(root: Path) -> list[str] | None:
    """Command prefix to invoke flutter; None when unavailable."""
    env = os.environ.get("FOS_FLUTTER")
    if env:
        return [env]
    resolved = _resolve_tool("flutter", root)
    if resolved:
        return resolved
    # Owner-PC known location (QUESTIONS Q-PREFLIGHT-001).
    for fixed in (r"C:\src\flutter\bin\flutter.bat", "/c/src/flutter/bin/flutter"):
        if Path(fixed).exists():
            return [fixed]
    return None


def run_verification(root: Path, skip_test: bool = False) -> dict:
    """Run analyze (+ test), record evidence, return the record."""
    card = newest_shipped_card(root)
    if card is None:
        raise VerifyError("no shipped card found in CONVERSION_LOG.md — nothing to verify")

    app_dir = root / APP_DIR
    if not (app_dir / "pubspec.yaml").is_file():
        raise VerifyError(f"{APP_DIR}/pubspec.yaml not found — nothing to analyze")

    flutter = find_flutter(root)
    record: dict = {
        "card_id": card["card_id"],
        "summary": card["summary"],
        "ship_date": card["date"],
        "status": "failed",
        "analyze": None,
        "test": None,
        "flutter": flutter,
        "recorded_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }

    if flutter is None:
        dart = None
        for dc in _resolve_tool("dart", root) or []:
            dart = _run([dc, "analyze"], app_dir, _ANALYZE_TIMEOUT)
            break
        if dart is not None and dart["error"] is None:
            record["analyze"] = {"ok": dart["ok"], "tail": _tail(dart["output"])}
            if not dart["ok"]:
                record["status"] = "failed"
                _write_evidence(root, card["card_id"], record)
                return record
            record["status"] = "passed-analyze-only" if not skip_test else "passed-analyze-only"
            record["test"] = {"ok": None, "summary": "skipped — flutter not found", "tail": ""}
            _write_evidence(root, card["card_id"], record)
            return record
        record["status"] = "failed"
        record["analyze"] = {"ok": False, "tail": "flutter and dart both unavailable"}
        _write_evidence(root, card["card_id"], record)
        return record

    t0 = time.monotonic()
    analyze = _run([*flutter, "analyze"], app_dir, _ANALYZE_TIMEOUT)
    record["analyze"] = {
        "ok": analyze["ok"],
        "seconds": round(time.monotonic() - t0, 1),
        "tail": _tail(analyze["output"]),
        "error": analyze["error"],
    }

    if not skip_test:
        t0 = time.monotonic()
        test = _run([*flutter, "test"], app_dir, _TEST_TIMEOUT)
        record["test"] = {
            "ok": test["ok"],
            "seconds": round(time.monotonic() - t0, 1),
            "summary": _test_summary(test["output"]),
            "tail": _tail(test["output"]),
            "error": test["error"],
        }

    analyze_ok = bool(record["analyze"] and record["analyze"]["ok"])
    test_ok = True if skip_test else bool(record["test"] and record["test"]["ok"])
    record["status"] = "passed" if (analyze_ok and test_ok) else "failed"

    try:
        record["log_mtime_at_verify"] = (root / LOG_PATH).stat().st_mtime
    except OSError:
        record["log_mtime_at_verify"] = 0

    _write_evidence(root, card["card_id"], record)
    return record


def _write_evidence(root: Path, card_id: str, record: dict) -> None:
    p = evidence_path(root, card_id)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


# ----------------------------------------------------------------------- CLI

def _print_human(record: dict) -> None:
    print(f"card: {record['card_id']} — {record['summary'][:80]}")
    a = record.get("analyze") or {}
    t = record.get("test") or {}
    print(f"analyze: {'OK' if a.get('ok') else 'FAIL'}"
          + (f" ({a['seconds']}s)" if "seconds" in a else ""))
    if t:
        print(f"test:    {'OK' if t.get('ok') else 'FAIL'}"
              + (f" ({t['summary']}, {t['seconds']}s)" if t.get("summary") else ""))
    print(f"status:  {record['status']}")
    if record["status"] != "passed":
        tail = (t or {}).get("tail") or a.get("tail") or ""
        if tail:
            print("--- output tail ---")
            print(tail)


def main(argv: list[str]) -> int:
    args = [a for a in argv if a != "--skip-test"]
    skip_test = "--skip-test" in argv
    root = Path(args[1]).resolve() if len(args) > 1 else Path.cwd()

    if not args or args[0] not in ("verify", "check"):
        print("usage: verify_ship.py verify|check [PROJECT_ROOT] [--skip-test]", file=sys.stderr)
        return 2

    if args[0] == "verify":
        try:
            record = run_verification(root, skip_test=skip_test)
        except VerifyError as exc:
            print(f"VERIFY ERROR: {exc}", file=sys.stderr)
            return 3
        _print_human(record)
        return 0 if record["status"] == "passed" else 1

    # check — predicate only (used by the stop-hook backstop)
    state = verification_status(root)
    loop_status = ""
    sp = root / STATE_PATH
    if sp.is_file():
        m = re.search(r"^\s*status\s*:\s*([A-Za-z]+)", sp.read_text(encoding="utf-8", errors="replace"), re.M)
        loop_status = m.group(1).upper() if m else ""
    state["loop_status"] = loop_status
    print(json.dumps(state, ensure_ascii=False))
    return 0 if not state["pending"] else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
