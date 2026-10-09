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
  "quranProgressSurahMulk": "Al-Mulk",
  "@quranProgressSurahMulk": { "description": "SCR-FAT-072 surah Al-Mulk (P15-QUR-002)" },
  "quranProgressCycleSurahCta": "Switch ward surah",
  "@quranProgressCycleSurahCta": { "description": "SCR-FAT-072 edit plan surah CTA" },
  "quranProgressCycleSurahToast": "Ward surah set to {surah} — save to send to your child",
  "@quranProgressCycleSurahToast": {
    "description": "SCR-FAT-072 cycle surah toast",
    "placeholders": { "surah": { "type": "String" } }
  },
  "quranProgressPublishPlanCta": "Save plan to child",
  "@quranProgressPublishPlanCta": { "description": "SCR-FAT-072 publish ward plan CTA (P15-QUR-002)" },
  "quranProgressPublishPlanToast": "Ward plan sent — {surah} · +{minutes} minutes reward",
  "@quranProgressPublishPlanToast": {
    "description": "SCR-FAT-072 publish plan toast",
    "placeholders": {
      "surah": { "type": "String" },
      "minutes": { "type": "int" }
    }
  },
  "childQuranWardAyahNaba1": "عَمَّ يَتَسَاءَلُونَ ﴿١﴾",
  "@childQuranWardAyahNaba1": { "description": "SCR-CHD-025 licensed An-Naba 1 (never AI-generated)" }
"""

AR = r"""
  "quranProgressSurahMulk": "الملك",
  "@quranProgressSurahMulk": { "description": "SCR-FAT-072 surah Al-Mulk (P15-QUR-002)" },
  "quranProgressCycleSurahCta": "تبديل سورة الورد",
  "@quranProgressCycleSurahCta": { "description": "SCR-FAT-072 edit plan surah CTA" },
  "quranProgressCycleSurahToast": "سورة الورد أصبحت {surah} — احفظ لإرسالها لابنك",
  "@quranProgressCycleSurahToast": {
    "description": "SCR-FAT-072 cycle surah toast",
    "placeholders": { "surah": { "type": "String" } }
  },
  "quranProgressPublishPlanCta": "حفظ الخطة للابن",
  "@quranProgressPublishPlanCta": { "description": "SCR-FAT-072 publish ward plan CTA (P15-QUR-002)" },
  "quranProgressPublishPlanToast": "أُرسلت خطة الورد — {surah} · مكافأة +{minutes} دقيقة",
  "@quranProgressPublishPlanToast": {
    "description": "SCR-FAT-072 publish plan toast",
    "placeholders": {
      "surah": { "type": "String" },
      "minutes": { "type": "int" }
    }
  },
  "childQuranWardAyahNaba1": "عَمَّ يَتَسَاءَلُونَ ﴿١﴾",
  "@childQuranWardAyahNaba1": { "description": "SCR-CHD-025 licensed An-Naba 1 (never AI-generated)" }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "quranProgressSurahMulk")
    splice(ROOT / "app_ar.arb", AR, "quranProgressSurahMulk")


if __name__ == "__main__":
    main()
