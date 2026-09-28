#!/usr/bin/env python3
from pathlib import Path

root = Path(r"D:/special projects/family/app/test")

# Exact old → new replacements (order matters for overlapping patterns).
replacements = [
    ("find.textContaining('unavailable until Native')", "find.textContaining('upcoming update')"),
    ("find.textContaining('camera Native CLOSED')", "find.textContaining('this device only')"),
    ("find.textContaining('English interface')", "find.textContaining('Interface language updated')"),
    ("find.textContaining('REMOTE CLOSED')", "find.textContaining('upcoming update')"),
    ("find.textContaining('NOT IMPLEMENTED')", "find.textContaining('قريبًا')"),
    ("find.textContaining('Native')", "find.textContaining('upcoming update')"),
    ("find.textContaining('Backend')", "find.textContaining('upcoming update')"),
    ("find.textContaining('FCM')", "find.textContaining('upcoming update')"),
]

child_gentle_files = {
    "child_flashcards_screen_test.dart",
    "child_media_share_screen_test.dart",
    "child_time_request_screen_test.dart",
    "child_arrival_screen_test.dart",
    "child_friends_screen_test.dart",
    "child_chats_screen_test.dart",
    "child_stickers_backgrounds_screen_test.dart",
    "child_tasks_screen_test.dart",
}

files_updated = 0
for p in root.rglob("*_test.dart"):
    t = p.read_text(encoding="utf-8")
    orig = t
    if p.name == "child_result_screen_test.dart":
        t = t.replace(
            "find.textContaining('REMOTE CLOSED')",
            "find.textContaining('adding fractions')",
        )
    elif p.name in child_gentle_files:
        for old in (
            "REMOTE CLOSED",
            "FCM",
            "camera Native CLOSED",
            "Native CLOSED",
            "Backend",
        ):
            t = t.replace(
                f"find.textContaining('{old}')",
                "find.textContaining('this device only')",
            )
    else:
        for a, b in replacements:
            t = t.replace(a, b)
    if t != orig:
        p.write_text(t, encoding="utf-8")
        files_updated += 1
        print("updated", p.relative_to(root))
print("total", files_updated)
