# Temporary PRT-1 helper
import re
from collections import Counter, defaultdict
from pathlib import Path

root = Path(r"D:/special projects/family")
csv_path = root / "prototype" / "_REGISTRY" / "screens.csv"
html_path = root / "prototype" / "family_os_app.html"

rows = []
for line in csv_path.read_text(encoding="utf-8").splitlines()[1:]:
    line = line.strip()
    if not line:
        continue
    cols = line.split(",")
    if not cols[0].startswith("SCR-"):
        continue
    rows.append(
        {
            "id": cols[0],
            "app": cols[1],
            "tab": cols[2],
            "name": cols[3],
            "type": cols[7],
            "notes": cols[8] if len(cols) > 8 else "",
        }
    )

html = html_path.read_text(encoding="utf-8")
icons = {}
for m in re.finditer(
    r"'(FAT|CHD|SHR)-(\d+)':\{[^\n]*hubIcon:'([^']+)'",
    html,
):
    icons[f"SCR-{m.group(1)}-{m.group(2)}"] = m.group(3)

print("icons found", len(icons))
by_type = defaultdict(lambda: defaultdict(int))
missing = []
for row in rows:
    icon = icons.get(row["id"])
    if icon is None:
        missing.append(row["id"])
        continue
    by_type[row["type"]][icon] += 1

for t in sorted(by_type):
    print(f"{t}: {dict(by_type[t])}")

print("missing icons:", missing)

tab_c = Counter()
app_tabless = Counter()
for row in rows:
    notes = (row["name"] + " " + row["notes"]).lower()
    is_tomb = "tombstone" in notes or "محذوفة" in row["name"]
    if is_tomb:
        print("TOMBSTONE", row["id"])
        continue
    if row["tab"] == "-":
        app_tabless[row["app"]] += 1
    else:
        tab_c[(row["app"], row["tab"])] += 1

print("TAB COUNTS:", dict(tab_c))
print("TABLESS BY APP:", dict(app_tabless))
