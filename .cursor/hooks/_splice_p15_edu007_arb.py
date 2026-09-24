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
  "materialsLessonsSubjectCustom": "New subject",
  "@materialsLessonsSubjectCustom": { "description": "SCR-FAT-048 user-added subject title (P15-EDU-007)" },
  "materialsLessonsMetaJustAdded": "Just added — ready for lessons",
  "@materialsLessonsMetaJustAdded": { "description": "SCR-FAT-048 new subject subtitle" },
  "materialsLessonsMetaLessonCount": "{count} lessons",
  "@materialsLessonsMetaLessonCount": {
    "description": "SCR-FAT-048 lesson count subtitle for custom subject",
    "placeholders": { "count": { "type": "int" } }
  },
  "materialsLessonsAddSubjectPersistedToast": "Subject added to your materials",
  "@materialsLessonsAddSubjectPersistedToast": { "description": "SCR-FAT-048 add subject persisted toast" },
  "materialsLessonsAddLessonPersistedToast": "Lesson slot added — pick a source next",
  "@materialsLessonsAddLessonPersistedToast": { "description": "SCR-FAT-048 add lesson persisted toast" }
"""

AR = r"""
  "materialsLessonsSubjectCustom": "مادة جديدة",
  "@materialsLessonsSubjectCustom": { "description": "SCR-FAT-048 user-added subject title (P15-EDU-007)" },
  "materialsLessonsMetaJustAdded": "أُضيفت للتو — جاهزة للدروس",
  "@materialsLessonsMetaJustAdded": { "description": "SCR-FAT-048 new subject subtitle" },
  "materialsLessonsMetaLessonCount": "{count} دروس",
  "@materialsLessonsMetaLessonCount": {
    "description": "SCR-FAT-048 lesson count subtitle for custom subject",
    "placeholders": { "count": { "type": "int" } }
  },
  "materialsLessonsAddSubjectPersistedToast": "أُضيفت المادة إلى موادك",
  "@materialsLessonsAddSubjectPersistedToast": { "description": "SCR-FAT-048 add subject persisted toast" },
  "materialsLessonsAddLessonPersistedToast": "أُضيف درس — اختر المصدر التالي",
  "@materialsLessonsAddLessonPersistedToast": { "description": "SCR-FAT-048 add lesson persisted toast" }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "materialsLessonsSubjectCustom")
    splice(ROOT / "app_ar.arb", AR, "materialsLessonsSubjectCustom")


if __name__ == "__main__":
    main()
