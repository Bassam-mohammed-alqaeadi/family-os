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
  "previewApproveApprovedToast": "Approved — ready to assign rewards to your child",
  "@previewApproveApprovedToast": { "description": "SCR-FAT-044 approve persisted pack toast" },
  "childQuizSkillApprovedPack": "Lesson your parent approved",
  "@childQuizSkillApprovedPack": { "description": "SCR-CHD-015 skill from FAT-044 pack" },
  "childQuizExplainApproved": "Your parent approved this question for you — great work!",
  "@childQuizExplainApproved": { "description": "SCR-CHD-015 approved pack explain" }
"""

AR = r"""
  "previewApproveApprovedToast": "تم الاعتماد — جاهز لتعيين المكافآت لابنك",
  "@previewApproveApprovedToast": { "description": "SCR-FAT-044 approve persisted pack toast" },
  "childQuizSkillApprovedPack": "درس اعتمده ولي أمرك",
  "@childQuizSkillApprovedPack": { "description": "SCR-CHD-015 skill from FAT-044 pack" },
  "childQuizExplainApproved": "ولي أمرك اعتمد هذا السؤال لك — أحسنت!",
  "@childQuizExplainApproved": { "description": "SCR-CHD-015 approved pack explain" }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "previewApproveApprovedToast")
    splice(ROOT / "app_ar.arb", AR, "previewApproveApprovedToast")


if __name__ == "__main__":
    main()
