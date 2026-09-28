#!/usr/bin/env python3
"""VX-B4 mechanical residue sweeps."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(r"D:/special projects/family/app/lib")

CHEVRON_FILES = [
    "features/n02_day/alerts_hub_screen.dart",
    "features/n12_devices/settings_hub_screen.dart",
    "features/n02_day/child_profile_screen.dart",
    "features/n14_studio/studio_board_screen.dart",
    "features/n03_screen_time/child_apps_screen.dart",
    "features/n03_screen_time/time_expiry_screen.dart",
    "features/n17_child_learn/child_learn_home_screen.dart",
    "features/n01_linking/trial_mode_screen.dart",
    "features/n07_advisor/family_advisor_hub_screen.dart",
    "features/n12_devices/language_help_screen.dart",
    "features/n01_linking/link_qr_screen.dart",
    "features/sys3_identity/sys3_identity_screens.dart",
    "app/gallery_screen.dart",
    "features/n01_linking/setup_wizard_screen.dart",
    "features/n17_child_learn/child_wallet_screen.dart",
    "features/n14_studio/add_from_source_screen.dart",
    "features/n12_devices/device_health_list_screen.dart",
    "features/n14_studio/materials_lessons_screen.dart",
    "features/n02_day/children_list_screen.dart",
]

SNACK_FILES = [
    "features/n10_emergency/child_sos_in_progress_screen.dart",
    "features/n02_day/alert_detail_screen.dart",
    "features/n02_day/child_conversation_screen.dart",
    "features/n02_day/call_history_screen.dart",
    "features/n02_day/child_chats_screen.dart",
    "features/n04_web_filter/web_filter_screen.dart",
    "features/n02_day/conversations_list_screen.dart",
    "features/n02_day/conversation_screen.dart",
    "features/n02_day/child_active_call_screen.dart",
    "features/n02_day/request_inbox_screen.dart",
    "features/n02_day/active_call_screen.dart",
    "features/n02_day/create_safe_zone_screen.dart",
    "features/n10_emergency/sos_alert_screen.dart",
]


def ensure_app_toast_import(text: str) -> str:
    needle = "package:family_os/core/design/components/app_toast.dart"
    if needle in text:
        return text
    # Insert after first family_os design import or after package imports block.
    m = re.search(
        r"(import 'package:family_os/core/design/[^\n]+;\n)",
        text,
    )
    line = f"import '{needle}';\n"
    if m:
        return text[: m.end()] + line + text[m.end() :]
    m2 = re.search(r"(import 'package:flutter[^\n]+;\n)", text)
    if m2:
        return text[: m2.end()] + line + text[m2.end() :]
    return line + text


def replace_simple_snackbars(text: str) -> str:
    # Multi-line ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(X)));
    pattern = re.compile(
        r"ScaffoldMessenger\.of\(\s*context\s*\)\s*\.showSnackBar\(\s*"
        r"SnackBar\(\s*content:\s*Text\(([^)]+)\)\s*,?\s*\)\s*,?\s*\)\s*;",
        re.MULTILINE | re.DOTALL,
    )
    text = pattern.sub(r"AppToast.show(context, message: \1);", text)

    # With action — SnackBar(content: Text(X), action: SnackBarAction(label: Y, onPressed: Z))
    pattern2 = re.compile(
        r"ScaffoldMessenger\.of\(\s*context\s*\)\s*\.showSnackBar\(\s*"
        r"SnackBar\(\s*content:\s*Text\(([^)]+)\)\s*,\s*"
        r"action:\s*SnackBarAction\(\s*label:\s*([^,]+),\s*"
        r"onPressed:\s*([^)]+)\)\s*,?\s*\)\s*,?\s*\)\s*;",
        re.MULTILINE | re.DOTALL,
    )
    text = pattern2.sub(
        r"AppToast.show(\n"
        r"      context,\n"
        r"      message: \1,\n"
        r"      actionLabel: \2,\n"
        r"      onAction: \3,\n"
        r"    );",
        text,
    )
    return text


def main() -> None:
    chevron_n = 0
    for rel in CHEVRON_FILES:
        p = ROOT / rel
        if not p.exists():
            print("missing chevron", rel)
            continue
        t = p.read_text(encoding="utf-8")
        n = t.replace("Icons.chevron_left", "Icons.chevron_right")
        if n != t:
            p.write_text(n, encoding="utf-8")
            chevron_n += 1
            print("chevron", rel)
    print("chevron files", chevron_n)

    snack_n = 0
    for rel in SNACK_FILES:
        p = ROOT / rel
        if not p.exists():
            print("missing snack", rel)
            continue
        t = p.read_text(encoding="utf-8")
        n = replace_simple_snackbars(t)
        if "ScaffoldMessenger" in n or "SnackBar(" in n:
            # leave file for manual — still write partial replacements
            pass
        if n != t:
            if "AppToast.show" in n:
                n = ensure_app_toast_import(n)
            p.write_text(n, encoding="utf-8")
            snack_n += 1
            left = n.count("ScaffoldMessenger") + n.count("showSnackBar")
            print("snack", rel, "remaining_messengerish", left)
    print("snack files touched", snack_n)


if __name__ == "__main__":
    main()
