#!/usr/bin/env python3
"""Verify-before-ship gate for the Family OS harness (P9).

Owner policy Q-VERIFY-TIERED (2026-09-22):
  - Every card:  flutter analyze + SCOPED tests (feature + shared seams)
  - Every 3rd ship / end-of-wake / --full: FULL flutter test suite
  - Hard FULL required before: Phase 1.5 gate, merge to main, Stage 3

Evidence is recorded per card in .verify/<CARD_ID>.json.
Tier counter lives in .verify/_tier_state.json.

CLI:
  python verify_ship.py verify [PROJECT_ROOT] [--auto|--scoped|--full] [--skip-test]
  python verify_ship.py check  [PROJECT_ROOT]
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
TIER_STATE = "_tier_state.json"
LOG_PATH = Path("CONVERSION_LOG.md")
STATE_PATH = Path("harness") / "LOOP_STATE.md"

_CARD_RX = re.compile(r"^(\d{4}-\d{2}-\d{2})\s*\|\s*([^|]+?)\s*\|", re.MULTILINE)

_ANALYZE_TIMEOUT = int(os.environ.get("FOS_VERIFY_TIMEOUT_ANALYZE", "240"))
_TEST_TIMEOUT = int(os.environ.get("FOS_VERIFY_TIMEOUT_TEST", "480"))
_SCOPED_TEST_TIMEOUT = int(os.environ.get("FOS_VERIFY_TIMEOUT_SCOPED", "180"))

# Full suite every N ships (scoped ships count toward N; full resets).
_FULL_EVERY = int(os.environ.get("FOS_VERIFY_FULL_EVERY", "3"))

# Always included in scoped runs when present (shared seams).
_SHARED_TEST_GLOBS = (
    "test/app/router_routes_test.dart",
    "test/app/role_guard_test.dart",
)


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


def tier_state_path(root: Path) -> Path:
    return root / EVIDENCE_DIR / TIER_STATE


def load_tier_state(root: Path) -> dict:
    p = tier_state_path(root)
    if not p.is_file():
        return {"ships_since_full": 0, "last_full_card": None, "last_full_at": None}
    try:
        data = json.loads(p.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            return {"ships_since_full": 0, "last_full_card": None, "last_full_at": None}
        data.setdefault("ships_since_full", 0)
        return data
    except (OSError, json.JSONDecodeError):
        return {"ships_since_full": 0, "last_full_card": None, "last_full_at": None}


def save_tier_state(root: Path, state: dict) -> None:
    p = tier_state_path(root)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(state, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


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
    tier = ev.get("tier", "full")
    return {"pending": False, "card_id": card_id, "summary": card["summary"],
            "reason": "verified %s (evidence %s)" % (tier, evidence_path(root, card_id).name),
            "tier": tier}


def _stale(ship_date: str, recorded_iso: str) -> bool:
    try:
        rec = datetime.fromisoformat(recorded_iso).date().isoformat()
        return rec < ship_date
    except ValueError:
        return True


# --------------------------------------------------------------- tier / scope

def resolve_mode(argv_flags: set[str], ships_since_full: int) -> str:
    """Return 'scoped' | 'full'. Env FOS_VERIFY_MODE overrides auto when set."""
    env = (os.environ.get("FOS_VERIFY_MODE") or "").strip().lower()
    if "full" in argv_flags or env == "full":
        return "full"
    if "scoped" in argv_flags or env == "scoped":
        return "scoped"
    # auto: full on every Nth ship (1-based index after this ship)
    # ships_since_full=0,1 → scoped; =2 → this is 3rd → full
    if ships_since_full + 1 >= _FULL_EVERY:
        return "full"
    return "scoped"


def _camel_to_snake(name: str) -> str:
    s1 = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s1).lower()


def _screen_names_from_summary(summary: str) -> list[str]:
    """Pull CamelCase *Screen identifiers from the ship summary."""
    return re.findall(r"\b([A-Z][A-Za-z0-9]+Screen)\b", summary or "")


def resolve_scoped_paths(root: Path, card_id: str, summary: str) -> list[str]:
    """Return relative paths under app/ for scoped flutter test.

    Escalates to [] (caller treats as full) when nothing useful is found.
    """
    app = root / APP_DIR
    test_root = app / "test"
    if not test_root.is_dir():
        return []

    found: list[Path] = []

    # 1) Explicit map override
    map_path = root / EVIDENCE_DIR / "scope_map.json"
    if map_path.is_file():
        try:
            mapping = json.loads(map_path.read_text(encoding="utf-8"))
            entries = mapping.get(card_id) or mapping.get(card_id.upper())
            if isinstance(entries, str):
                entries = [entries]
            if isinstance(entries, list):
                for e in entries:
                    p = app / e
                    if p.is_file() or p.is_dir():
                        found.append(p)
        except (OSError, json.JSONDecodeError):
            pass

    # 2) From *Screen names in summary → matching *_test.dart
    for screen in _screen_names_from_summary(summary):
        snake = _camel_to_snake(screen)
        # child_focus_screen_test.dart etc.
        for p in test_root.rglob(f"{snake}_test.dart"):
            found.append(p)
        # also directory named after feature if present
        for p in test_root.rglob(f"{snake}.dart"):
            if p.name.endswith("_test.dart"):
                found.append(p)

    # 3) Card-id heuristic folders (n17_child_learn etc. — soft)
    cid = card_id.upper()
    if cid.startswith("SCR-CHD-") or cid.startswith("SCR-FAT-") or cid.startswith("SCR-SHR-"):
        # Prefer any test file whose path mentions the numeric id fragment
        num = re.sub(r"^SCR-(CHD|FAT|SHR)-", "", cid, flags=re.I)
        if num.isdigit():
            needle = num.zfill(3) if len(num) <= 3 else num
            for p in test_root.rglob("*_test.dart"):
                # Avoid matching every file; only if filename contains screen hint already handled
                pass
            _ = needle  # reserved for future map; keep heuristic light

    # 4) SET/UI cards — prefer matching evidence-named tests under features
    if cid.startswith("SET-") or cid.startswith("UI-"):
        for p in test_root.rglob(f"*{cid.lower().replace('-', '_')}*"):
            if p.suffix == ".dart" and p.name.endswith("_test.dart"):
                found.append(p)
        # UI packs often live as ui_00N_*_test.dart
        m = re.match(r"UI-(\d+)", cid, re.I)
        if m:
            n = int(m.group(1))
            for p in test_root.rglob(f"ui_{n:03d}*_test.dart"):
                found.append(p)

    # 5) Shared seams
    for rel in _SHARED_TEST_GLOBS:
        p = app / rel
        if p.is_file():
            found.append(p)

    # Deduplicate, keep only existing, relative to app/
    uniq: list[str] = []
    seen: set[str] = set()
    for p in found:
        try:
            rel = p.resolve().relative_to(app.resolve()).as_posix()
        except ValueError:
            continue
        if rel not in seen and (app / rel).exists():
            seen.add(rel)
            uniq.append(rel)

    # Need at least one feature test (not only shared) — else escalate
    # PRT / generator cards may live under test/app/ (shell_config etc.)
    feature = [u for u in uniq if not u.startswith("test/app/")]
    if not feature and cid.startswith("PRT-"):
        feature = [u for u in uniq if u.endswith("_test.dart")]
    if not feature:
        return []
    return uniq


# ------------------------------------------------------------------- runners

def _run(cmd: list[str], cwd: Path, timeout: int) -> dict:
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
    env = os.environ.get("FOS_FLUTTER")
    if env:
        return [env]
    resolved = _resolve_tool("flutter", root)
    if resolved:
        return resolved
    for fixed in (r"C:\src\flutter\bin\flutter.bat", "/c/src/flutter/bin/flutter"):
        if Path(fixed).exists():
            return [fixed]
    return None


def run_verification(
    root: Path,
    skip_test: bool = False,
    mode: str = "auto",
) -> dict:
    """Run analyze (+ scoped|full test), record evidence, return the record."""
    card = newest_shipped_card(root)
    if card is None:
        raise VerifyError("no shipped card found in CONVERSION_LOG.md — nothing to verify")

    app_dir = root / APP_DIR
    if not (app_dir / "pubspec.yaml").is_file():
        raise VerifyError(f"{APP_DIR}/pubspec.yaml not found — nothing to analyze")

    tier_state = load_tier_state(root)
    ships_since = int(tier_state.get("ships_since_full") or 0)

    if mode == "auto":
        effective = resolve_mode(set(), ships_since)
    elif mode in ("scoped", "full"):
        effective = mode
    else:
        effective = resolve_mode(set(), ships_since)

    scoped_paths: list[str] = []
    if not skip_test and effective == "scoped":
        scoped_paths = resolve_scoped_paths(root, card["card_id"], card["summary"])
        if not scoped_paths:
            # Safe escalate: no feature tests found → full suite
            effective = "full"

    flutter = find_flutter(root)
    record: dict = {
        "card_id": card["card_id"],
        "summary": card["summary"],
        "ship_date": card["date"],
        "status": "failed",
        "tier": effective if not skip_test else "analyze-only",
        "ships_since_full_before": ships_since,
        "scoped_paths": scoped_paths if effective == "scoped" else [],
        "analyze": None,
        "test": None,
        "flutter": flutter,
        "recorded_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "policy": "Q-VERIFY-TIERED",
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
            record["status"] = "passed-analyze-only"
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
        if effective == "scoped":
            cmd = [*flutter, "test", *scoped_paths]
            timeout = _SCOPED_TEST_TIMEOUT
        else:
            cmd = [*flutter, "test"]
            timeout = _TEST_TIMEOUT
        test = _run(cmd, app_dir, timeout)
        record["test"] = {
            "ok": test["ok"],
            "seconds": round(time.monotonic() - t0, 1),
            "summary": _test_summary(test["output"]),
            "tail": _tail(test["output"]),
            "error": test["error"],
            "mode": effective,
            "paths": scoped_paths if effective == "scoped" else ["test/"],
        }

    analyze_ok = bool(record["analyze"] and record["analyze"]["ok"])
    test_ok = True if skip_test else bool(record["test"] and record["test"]["ok"])
    record["status"] = "passed" if (analyze_ok and test_ok) else "failed"

    try:
        record["log_mtime_at_verify"] = (root / LOG_PATH).stat().st_mtime
    except OSError:
        record["log_mtime_at_verify"] = 0

    _write_evidence(root, card["card_id"], record)

    # Update tier counter only on successful verify
    if record["status"] == "passed" and not skip_test:
        if effective == "full":
            save_tier_state(root, {
                "ships_since_full": 0,
                "last_full_card": card["card_id"],
                "last_full_at": record["recorded_at"],
                "full_every": _FULL_EVERY,
                "policy": "Q-VERIFY-TIERED",
            })
            record["ships_since_full_after"] = 0
        else:
            new_n = ships_since + 1
            save_tier_state(root, {
                "ships_since_full": new_n,
                "last_full_card": tier_state.get("last_full_card"),
                "last_full_at": tier_state.get("last_full_at"),
                "last_scoped_card": card["card_id"],
                "full_every": _FULL_EVERY,
                "policy": "Q-VERIFY-TIERED",
            })
            record["ships_since_full_after"] = new_n

    return record


def _write_evidence(root: Path, card_id: str, record: dict) -> None:
    p = evidence_path(root, card_id)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


# ----------------------------------------------------------------------- CLI

def _print_human(record: dict) -> None:
    print(f"card: {record['card_id']} — {record['summary'][:80]}")
    print(f"tier:    {record.get('tier', '?')} (policy {record.get('policy', '—')})")
    a = record.get("analyze") or {}
    t = record.get("test") or {}
    print(f"analyze: {'OK' if a.get('ok') else 'FAIL'}"
          + (f" ({a['seconds']}s)" if "seconds" in a else ""))
    if t:
        paths = t.get("paths") or record.get("scoped_paths") or []
        path_note = f", {len(paths)} path(s)" if paths and record.get("tier") == "scoped" else ""
        print(f"test:    {'OK' if t.get('ok') else 'FAIL'}"
              + (f" ({t.get('summary')}, {t.get('seconds')}s{path_note})" if t.get("summary") else ""))
        if record.get("tier") == "scoped" and paths:
            print("paths:   " + ", ".join(paths[:8]) + ("…" if len(paths) > 8 else ""))
    print(f"status:  {record['status']}")
    if record["status"] != "passed":
        tail = (t or {}).get("tail") or a.get("tail") or ""
        if tail:
            print("--- output tail ---")
            print(tail)


def main(argv: list[str]) -> int:
    flags = {a for a in argv if a.startswith("--")}
    args = [a for a in argv if not a.startswith("--")]
    skip_test = "--skip-test" in flags

    if "--full" in flags:
        mode = "full"
    elif "--scoped" in flags:
        mode = "scoped"
    else:
        mode = "auto"

    root = Path(args[1]).resolve() if len(args) > 1 else Path.cwd()

    if not args or args[0] not in ("verify", "check"):
        print(
            "usage: verify_ship.py verify|check [PROJECT_ROOT] "
            "[--auto|--scoped|--full] [--skip-test]",
            file=sys.stderr,
        )
        return 2

    if args[0] == "verify":
        try:
            record = run_verification(root, skip_test=skip_test, mode=mode)
        except VerifyError as exc:
            print(f"VERIFY ERROR: {exc}", file=sys.stderr)
            return 3
        _print_human(record)
        return 0 if record["status"] == "passed" else 1

    state = verification_status(root)
    loop_status = ""
    sp = root / STATE_PATH
    if sp.is_file():
        m = re.search(r"^\s*status\s*:\s*([A-Za-z]+)", sp.read_text(encoding="utf-8", errors="replace"), re.M)
        loop_status = m.group(1).upper() if m else ""
    state["loop_status"] = loop_status
    tier = load_tier_state(root)
    state["tier_ships_since_full"] = tier.get("ships_since_full", 0)
    state["tier_full_every"] = _FULL_EVERY
    print(json.dumps(state, ensure_ascii=False))
    return 0 if not state["pending"] else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
