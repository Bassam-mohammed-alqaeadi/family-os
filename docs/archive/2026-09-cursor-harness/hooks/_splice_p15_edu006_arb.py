# -*- coding: utf-8 -*-
from pathlib import Path

ROOT = Path(r"D:/special projects/family/app/lib/core/i18n")


def splice(path: Path, block: str, marker: str) -> None:
    t = path.read_text(encoding="utf-8").rstrip()
    if marker in t:
        print(path.name, "skip", marker)
        return
    body = t[:-1].rstrip()
    if not body.endswith(","):
        body += ","
    path.write_text(body + "\n" + block.strip() + "\n}\n", encoding="utf-8")
    print(path.name, "ok", marker)


EN = r"""
  "resultsFollowupActivityQuizSubmittedTitle": "Child quiz submitted",
  "@resultsFollowupActivityQuizSubmittedTitle": { "description": "SCR-FAT-050 activity from CHD-015 quiz submit (P15-EDU-006)" },
  "resultsFollowupActivityJustSubmitted": "Just submitted — awaiting your review",
  "@resultsFollowupActivityJustSubmitted": { "description": "SCR-FAT-050 live submit subtitle without minutes" }
"""

AR = r"""
  "resultsFollowupActivityQuizSubmittedTitle": "اختبار الابن مُرسل",
  "@resultsFollowupActivityQuizSubmittedTitle": { "description": "SCR-FAT-050 activity from CHD-015 quiz submit (P15-EDU-006)" },
  "resultsFollowupActivityJustSubmitted": "أُرسل للتو — بانتظار مراجعتك",
  "@resultsFollowupActivityJustSubmitted": { "description": "SCR-FAT-050 live submit subtitle without minutes" }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "resultsFollowupActivityQuizSubmittedTitle")
    splice(ROOT / "app_ar.arb", AR, "resultsFollowupActivityQuizSubmittedTitle")


if __name__ == "__main__":
    main()
