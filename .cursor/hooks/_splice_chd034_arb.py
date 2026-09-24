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
  "childFamilyChallengesTitle": "Family challenges",
  "@childFamilyChallengesTitle": { "description": "SCR-CHD-034 AppBar" },
  "childFamilyChallengesActiveTitle": "This week's challenge: review marathon",
  "@childFamilyChallengesActiveTitle": { "description": "SCR-CHD-034 active" },
  "childFamilyChallengesActiveSub": "Who completes review cards every day? Prize: pick Friday's outing!",
  "@childFamilyChallengesActiveSub": { "description": "SCR-CHD-034 active sub" },
  "childFamilyChallengesYou": "You",
  "@childFamilyChallengesYou": { "description": "SCR-CHD-034 you" },
  "childFamilyChallengesSibling": "Sibling",
  "@childFamilyChallengesSibling": { "description": "SCR-CHD-034 Rule 23 sibling" },
  "childFamilyChallengesTieNote": "Exciting tie! — and Dad is smiling as he watches",
  "@childFamilyChallengesTieNote": { "description": "SCR-CHD-034 tie" },
  "childFamilyChallengesDoneTitle": "Challenges we finished",
  "@childFamilyChallengesDoneTitle": { "description": "SCR-CHD-034 done" },
  "childFamilyChallengesDoneFajr": "Fajr-together week",
  "@childFamilyChallengesDoneFajr": { "description": "SCR-CHD-034 done item" },
  "childFamilyChallengesDoneFajrSub": "You all won — Friday ice cream",
  "@childFamilyChallengesDoneFajrSub": { "description": "SCR-CHD-034 done sub" },
  "childFamilyChallengesDoneAmma": "Family Juz Amma khatma",
  "@childFamilyChallengesDoneAmma": { "description": "SCR-CHD-034 done item" },
  "childFamilyChallengesDoneAmmaSub": "Sibling finished first",
  "@childFamilyChallengesDoneAmmaSub": { "description": "SCR-CHD-034 done sub" },
  "childFamilyChallengesDoneTag": "Done",
  "@childFamilyChallengesDoneTag": { "description": "SCR-CHD-034 tag" },
  "childFamilyChallengesBanner": "Here we race to grow together — no ranking that embarrasses anyone. The only loser is laziness.",
  "@childFamilyChallengesBanner": { "description": "SCR-CHD-034 banner" },
  "childFamilyChallengesEmptyTitle": "No family challenges yet",
  "@childFamilyChallengesEmptyTitle": { "description": "SCR-CHD-034 empty" },
  "childFamilyChallengesEmptyMessage": "When Dad starts a family challenge, your week streak lights up here.",
  "@childFamilyChallengesEmptyMessage": { "description": "SCR-CHD-034 empty msg" },
  "childFamilyChallengesEmptyCta": "Home",
  "@childFamilyChallengesEmptyCta": { "description": "SCR-CHD-034 →001" },
  "childFamilyChallengesLoadingSemantics": "Loading family challenges",
  "@childFamilyChallengesLoadingSemantics": { "description": "SCR-CHD-034 loading" },
  "childFamilyChallengesParentLeanTitle": "Family challenges",
  "@childFamilyChallengesParentLeanTitle": { "description": "SCR-CHD-034 parent lean" },
  "childFamilyChallengesParentLeanMessage": "Friendly sibling races live on the child's device. Parents set prizes from Tasks / Studio.",
  "@childFamilyChallengesParentLeanMessage": { "description": "SCR-CHD-034 parent lean msg" }
"""

AR = r"""
  "childFamilyChallengesTitle": "تحديات العائلة",
  "@childFamilyChallengesTitle": { "description": "SCR-CHD-034 AppBar" },
  "childFamilyChallengesActiveTitle": "تحدي الأسبوع: ماراثون المراجعة",
  "@childFamilyChallengesActiveTitle": { "description": "SCR-CHD-034 active" },
  "childFamilyChallengesActiveSub": "من يكمل بطاقات مراجعته كل يوم؟ الجائزة: يختار وجهة مشوار الجمعة!",
  "@childFamilyChallengesActiveSub": { "description": "SCR-CHD-034 active sub" },
  "childFamilyChallengesYou": "أنت",
  "@childFamilyChallengesYou": { "description": "SCR-CHD-034 you" },
  "childFamilyChallengesSibling": "أخ/أخت",
  "@childFamilyChallengesSibling": { "description": "SCR-CHD-034 Rule 23 sibling" },
  "childFamilyChallengesTieNote": "تعادل مثير! — وأبوكما يراقب مبتسمًا",
  "@childFamilyChallengesTieNote": { "description": "SCR-CHD-034 tie" },
  "childFamilyChallengesDoneTitle": "تحدياتنا المنجزة",
  "@childFamilyChallengesDoneTitle": { "description": "SCR-CHD-034 done" },
  "childFamilyChallengesDoneFajr": "أسبوع الفجر جماعة",
  "@childFamilyChallengesDoneFajr": { "description": "SCR-CHD-034 done item" },
  "childFamilyChallengesDoneFajrSub": "فزتم كلكم — مثلجات الجمعة",
  "@childFamilyChallengesDoneFajrSub": { "description": "SCR-CHD-034 done sub" },
  "childFamilyChallengesDoneAmma": "ختمة عمّ العائلية",
  "@childFamilyChallengesDoneAmma": { "description": "SCR-CHD-034 done item" },
  "childFamilyChallengesDoneAmmaSub": "الأخ/الأخت أنهى أولًا",
  "@childFamilyChallengesDoneAmmaSub": { "description": "SCR-CHD-034 done sub" },
  "childFamilyChallengesDoneTag": "تم",
  "@childFamilyChallengesDoneTag": { "description": "SCR-CHD-034 tag" },
  "childFamilyChallengesBanner": "هنا نتنافس لنكبر معًا — لا ترتيب يُحرج أحدًا، والخاسر الوحيد هو الكسل.",
  "@childFamilyChallengesBanner": { "description": "SCR-CHD-034 banner" },
  "childFamilyChallengesEmptyTitle": "لا تحديات عائلية بعد",
  "@childFamilyChallengesEmptyTitle": { "description": "SCR-CHD-034 empty" },
  "childFamilyChallengesEmptyMessage": "عندما يبدأ الأب تحديًا عائليًا، يضيء شريط أسبوعك هنا.",
  "@childFamilyChallengesEmptyMessage": { "description": "SCR-CHD-034 empty msg" },
  "childFamilyChallengesEmptyCta": "الرئيسية",
  "@childFamilyChallengesEmptyCta": { "description": "SCR-CHD-034 →001" },
  "childFamilyChallengesLoadingSemantics": "جاري تحميل التحديات العائلية",
  "@childFamilyChallengesLoadingSemantics": { "description": "SCR-CHD-034 loading" },
  "childFamilyChallengesParentLeanTitle": "التحديات العائلية",
  "@childFamilyChallengesParentLeanTitle": { "description": "SCR-CHD-034 parent lean" },
  "childFamilyChallengesParentLeanMessage": "سباقات الإخوة الودية على جهاز الابن. الوالدان يضعان الجوائز من المهام / الاستوديو.",
  "@childFamilyChallengesParentLeanMessage": { "description": "SCR-CHD-034 parent lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "childFamilyChallengesTitle")
    splice(ROOT / "app_ar.arb", AR, "childFamilyChallengesTitle")
