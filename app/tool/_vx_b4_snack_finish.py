#!/usr/bin/env python3
"""Finish VX-B4 SnackBar → AppToast conversions."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(r"D:/special projects/family/app/lib")

FILES = [
    "features/n02_day/create_safe_zone_screen.dart",
    "features/n02_day/active_call_screen.dart",
    "features/n10_emergency/child_sos_in_progress_screen.dart",
    "features/n02_day/child_conversation_screen.dart",
    "features/n04_web_filter/web_filter_screen.dart",
    "features/n02_day/request_inbox_screen.dart",
    "features/n10_emergency/sos_alert_screen.dart",
]


def ensure_import(text: str) -> str:
    needle = "package:family_os/core/design/components/app_toast.dart"
    if needle in text:
        return text
    line = f"import '{needle}';\n"
    m = re.search(r"(import 'package:family_os/core/design/[^\n]+;\n)", text)
    if m:
        return text[: m.end()] + line + text[m.end() :]
    m2 = re.search(r"(import 'package:flutter/[^\n]+;\n)", text)
    if m2:
        return text[: m2.end()] + line + text[m2.end() :]
    return line + text


def convert(text: str) -> str:
    # Split ScaffoldMessenger.of(\n context,\n).showSnackBar(SnackBar(content: Text(X)));
    text = re.sub(
        r"ScaffoldMessenger\.of\(\s*\n?\s*context\s*,?\s*\n?\s*\)\s*\.showSnackBar\(\s*"
        r"SnackBar\(\s*content:\s*Text\(([^)]+)\)\s*\)\s*\)\s*;",
        r"AppToast.show(context, message: \1);",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )

    # SnackBar with action on separate lines
    text = re.sub(
        r"ScaffoldMessenger\.of\(\s*context\s*\)\s*\.showSnackBar\(\s*"
        r"SnackBar\(\s*"
        r"content:\s*Text\(([^)]+)\)\s*,\s*"
        r"action:\s*SnackBarAction\(\s*"
        r"label:\s*([^,\n]+)\s*,\s*"
        r"onPressed:\s*([^,\n\)]+)\s*,?\s*"
        r"\)\s*,?\s*"
        r"\)\s*,?\s*\)\s*;",
        r"AppToast.show(\n"
        r"      context,\n"
        r"      message: \1,\n"
        r"      actionLabel: \2,\n"
        r"      onAction: \3,\n"
        r"    );",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )

    # Generic multi-line SnackBar(content: Text(...)) only
    text = re.sub(
        r"ScaffoldMessenger\.of\(\s*context\s*\)\s*\.showSnackBar\(\s*"
        r"SnackBar\(\s*"
        r"content:\s*Text\(([^)]+)\)\s*,?\s*"
        r"\)\s*,?\s*\)\s*;",
        r"AppToast.show(context, message: \1);",
        text,
        flags=re.MULTILINE | re.DOTALL,
    )
    return text


def main() -> None:
    for rel in FILES:
        p = ROOT / rel
        t = p.read_text(encoding="utf-8")
        n = convert(t)
        if n != t:
            n = ensure_import(n)
            p.write_text(n, encoding="utf-8")
        left = len(re.findall(r"ScaffoldMessenger|showSnackBar|SnackBar\(", n))
        print(rel, "remaining", left)


if __name__ == "__main__":
    main()
