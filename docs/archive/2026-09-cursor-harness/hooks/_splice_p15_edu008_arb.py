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
  "dayBoardPendingQuizSubmittedTitle": "Child quiz submitted",
  "@dayBoardPendingQuizSubmittedTitle": { "description": "SCR-FAT-010 priority from CHD-015 LearningResult (P15-EDU-008)" },
  "dayBoardPendingJustSubmitted": "Just submitted — open results follow-up",
  "@dayBoardPendingJustSubmitted": { "description": "SCR-FAT-010 learning pending subtitle" },
  "dayBoardPendingEarnedMinutes": "Earned +{minutes} minutes — review on Results",
  "@dayBoardPendingEarnedMinutes": {
    "description": "SCR-FAT-010 learning pending with minutes",
    "placeholders": { "minutes": { "type": "int" } }
  }
"""

AR = r"""
  "dayBoardPendingQuizSubmittedTitle": "اختبار الابن مُرسل",
  "@dayBoardPendingQuizSubmittedTitle": { "description": "SCR-FAT-010 priority from CHD-015 LearningResult (P15-EDU-008)" },
  "dayBoardPendingJustSubmitted": "أُرسل للتو — افتح متابعة النتائج",
  "@dayBoardPendingJustSubmitted": { "description": "SCR-FAT-010 learning pending subtitle" },
  "dayBoardPendingEarnedMinutes": "حصل على +{minutes} دقيقة — راجع في النتائج",
  "@dayBoardPendingEarnedMinutes": {
    "description": "SCR-FAT-010 learning pending with minutes",
    "placeholders": { "minutes": { "type": "int" } }
  }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "dayBoardPendingQuizSubmittedTitle")
    splice(ROOT / "app_ar.arb", AR, "dayBoardPendingQuizSubmittedTitle")


if __name__ == "__main__":
    main()
