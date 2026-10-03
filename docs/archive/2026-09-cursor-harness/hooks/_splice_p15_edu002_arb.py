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
  "childLearnHomeChallengeAssigned": "Lesson your parent assigned",
  "@childLearnHomeChallengeAssigned": { "description": "SCR-CHD-012 live assignment challenge" },
  "childLearnHomeChallengeAssignedHomework": "Homework from your parent",
  "@childLearnHomeChallengeAssignedHomework": { "description": "SCR-CHD-012 homework assignment" },
  "childLearnHomeChallengeAssignedSkill": "Skill practice from your parent",
  "@childLearnHomeChallengeAssignedSkill": { "description": "SCR-CHD-012 skill-gap assignment" },
  "childLearnHomeChallengeAssignedFamily": "Family challenge from your parent",
  "@childLearnHomeChallengeAssignedFamily": { "description": "SCR-CHD-012 family assignment" },
  "childLearnHomeAssignedFromFather": "Assigned just now by your parent",
  "@childLearnHomeAssignedFromFather": { "description": "SCR-CHD-012 material subtitle for live assign" }
"""

AR = r"""
  "childLearnHomeChallengeAssigned": "درس خصّصه ولي أمرك",
  "@childLearnHomeChallengeAssigned": { "description": "SCR-CHD-012 live assignment challenge" },
  "childLearnHomeChallengeAssignedHomework": "واجب من ولي أمرك",
  "@childLearnHomeChallengeAssignedHomework": { "description": "SCR-CHD-012 homework assignment" },
  "childLearnHomeChallengeAssignedSkill": "تدريب مهارة من ولي أمرك",
  "@childLearnHomeChallengeAssignedSkill": { "description": "SCR-CHD-012 skill-gap assignment" },
  "childLearnHomeChallengeAssignedFamily": "تحدّي عائلي من ولي أمرك",
  "@childLearnHomeChallengeAssignedFamily": { "description": "SCR-CHD-012 family assignment" },
  "childLearnHomeAssignedFromFather": "خُصّص للتو من ولي أمرك",
  "@childLearnHomeAssignedFromFather": { "description": "SCR-CHD-012 material subtitle for live assign" }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "childLearnHomeChallengeAssigned")
    splice(ROOT / "app_ar.arb", AR, "childLearnHomeChallengeAssigned")


if __name__ == "__main__":
    main()
