#!/usr/bin/env python3
from pathlib import Path

root = Path(r"D:/special projects/family/app/test")
pairs = [
    ("'ابن ١'", "'ابن 1'"),
    ("'ابن ٢'", "'ابن 2'"),
    ("'ابن ٣'", "'ابن 3'"),
    ("'شريكة ١'", "'شريكة 1'"),
    ("'أب ١'", "'أب 1'"),
    ("'عائلة ١'", "'عائلة 1'"),
    ("find.textContaining('ابن ١')", "find.textContaining('ابن 1')"),
    ("find.textContaining('ابن ٢')", "find.textContaining('ابن 2')"),
    ("find.textContaining('ابن ٣')", "find.textContaining('ابن 3')"),
    ("find.textContaining('شريكة ١')", "find.textContaining('شريكة 1')"),
    ("find.text('ابن ١')", "find.text('ابن 1')"),
    ("find.text('أب ١')", "find.text('أب 1')"),
    ("['ابن ١', 'ابن ٢']", "['ابن 1', 'ابن 2']"),
    ("displayLabel: 'ابن ١'", "displayLabel: 'ابن 1'"),
    ("peerLabel: 'ابن ١'", "peerLabel: 'ابن 1'"),
    ("displayName, 'ابن ١'", "displayName, 'ابن 1'"),
    ("find.text('١٤ سنة')", "find.text('14 سنة')"),
    ("find.textContaining('٤:٥٩')", "find.textContaining('4:59')"),
]

files = 0
for p in root.rglob("*_test.dart"):
    t = p.read_text(encoding="utf-8")
    orig = t
    for a, b in pairs:
        t = t.replace(a, b)
    if t != orig:
        p.write_text(t, encoding="utf-8")
        files += 1
        print(p.relative_to(root))
print("files", files)
