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
  "childSmartTilawahTitle": "My smart tilawah",
  "@childSmartTilawahTitle": { "description": "SCR-CHD-032 AppBar" },
  "childSmartTilawahSurahMulk": "Surah Al-Mulk",
  "@childSmartTilawahSurahMulk": { "description": "SCR-CHD-032 surah" },
  "childSmartTilawahAyahMeta": "{surah} · ayah {ayah}",
  "@childSmartTilawahAyahMeta": {
    "description": "SCR-CHD-032 ayah meta",
    "placeholders": {
      "surah": { "type": "String" },
      "ayah": { "type": "int" }
    }
  },
  "childSmartTilawahAyahMulk16": "ءَأَمِنتُم مَّن فِى ٱلسَّمَآءِ…",
  "@childSmartTilawahAyahMulk16": { "description": "SCR-CHD-032 licensed ayah excerpt Mulk 16" },
  "childSmartTilawahListenCta": "Recite — I'm listening",
  "@childSmartTilawahListenCta": { "description": "SCR-CHD-032 listen" },
  "childSmartTilawahListenToast": "Listening to your tilawah… mashaAllah! One gentle note below",
  "@childSmartTilawahListenToast": { "description": "SCR-CHD-032 listen toast" },
  "childSmartTilawahTipTitle": "Today's note — only one",
  "@childSmartTilawahTipTitle": { "description": "SCR-CHD-032 tip" },
  "childSmartTilawahTipMadd": "Stretch «as-samaa» six counts",
  "@childSmartTilawahTipMadd": { "description": "SCR-CHD-032 tip title" },
  "childSmartTilawahTipMaddBody": "Connected madd before hamza — hear the sheikh, then try again",
  "@childSmartTilawahTipMaddBody": { "description": "SCR-CHD-032 tip body" },
  "childSmartTilawahSheikhCta": "Listen",
  "@childSmartTilawahSheikhCta": { "description": "SCR-CHD-032 sheikh" },
  "childSmartTilawahSheikhToast": "Sheikh clip for ayah 16 — from a licensed mushaf",
  "@childSmartTilawahSheikhToast": { "description": "SCR-CHD-032 sheikh toast" },
  "childSmartTilawahPraise": "Well done on: letter exits ✓ · ghunnah ✓ · pause ✓",
  "@childSmartTilawahPraise": { "description": "SCR-CHD-032 praise" },
  "childSmartTilawahBanner": "Correction uses licensed mushaf sheikh audio — Family Advisor gives one gentle note at a time so it never overwhelms you.",
  "@childSmartTilawahBanner": { "description": "SCR-CHD-032 banner" },
  "childSmartTilawahEmptyTitle": "No tilawah session yet",
  "@childSmartTilawahEmptyTitle": { "description": "SCR-CHD-032 empty" },
  "childSmartTilawahEmptyMessage": "Open your Quran ward to start a gentle smart-tilawah session.",
  "@childSmartTilawahEmptyMessage": { "description": "SCR-CHD-032 empty msg" },
  "childSmartTilawahEmptyCta": "My Quran ward",
  "@childSmartTilawahEmptyCta": { "description": "SCR-CHD-032 →014/025" },
  "childSmartTilawahLoadingSemantics": "Loading smart tilawah",
  "@childSmartTilawahLoadingSemantics": { "description": "SCR-CHD-032 loading" },
  "childSmartTilawahParentLeanTitle": "Smart tilawah",
  "@childSmartTilawahParentLeanTitle": { "description": "SCR-CHD-032 parent lean" },
  "childSmartTilawahParentLeanMessage": "This gentle recitation coach is on the child's device. Progress shows in Quran progress for parents.",
  "@childSmartTilawahParentLeanMessage": { "description": "SCR-CHD-032 parent lean msg" }
"""

AR = r"""
  "childSmartTilawahTitle": "تلاوتي الذكية",
  "@childSmartTilawahTitle": { "description": "SCR-CHD-032 AppBar" },
  "childSmartTilawahSurahMulk": "سورة الملك",
  "@childSmartTilawahSurahMulk": { "description": "SCR-CHD-032 surah" },
  "childSmartTilawahAyahMeta": "{surah} · الآية {ayah}",
  "@childSmartTilawahAyahMeta": {
    "description": "SCR-CHD-032 ayah meta",
    "placeholders": {
      "surah": { "type": "String" },
      "ayah": { "type": "int" }
    }
  },
  "childSmartTilawahAyahMulk16": "ءَأَمِنتُم مَّن فِى ٱلسَّمَآءِ…",
  "@childSmartTilawahAyahMulk16": { "description": "SCR-CHD-032 licensed ayah excerpt Mulk 16" },
  "childSmartTilawahListenCta": "اقرأ وأنا أستمع",
  "@childSmartTilawahListenCta": { "description": "SCR-CHD-032 listen" },
  "childSmartTilawahListenToast": "يستمع لتلاوتك… ما شاء الله! ملاحظة لطيفة واحدة أدناه",
  "@childSmartTilawahListenToast": { "description": "SCR-CHD-032 listen toast" },
  "childSmartTilawahTipTitle": "ملاحظة اليوم — واحدة فقط",
  "@childSmartTilawahTipTitle": { "description": "SCR-CHD-032 tip" },
  "childSmartTilawahTipMadd": "مدّ «السَّمَآء» ست حركات",
  "@childSmartTilawahTipMadd": { "description": "SCR-CHD-032 tip title" },
  "childSmartTilawahTipMaddBody": "مدّ متصل بالهمزة — استمع للشيخ ثم أعد",
  "@childSmartTilawahTipMaddBody": { "description": "SCR-CHD-032 tip body" },
  "childSmartTilawahSheikhCta": "استمع",
  "@childSmartTilawahSheikhCta": { "description": "SCR-CHD-032 sheikh" },
  "childSmartTilawahSheikhToast": "مقطع الشيخ للآية ١٦ — من مصحف مرخّص",
  "@childSmartTilawahSheikhToast": { "description": "SCR-CHD-032 sheikh toast" },
  "childSmartTilawahPraise": "أحسنت في: مخارج الحروف ✓ · الغنّة ✓ · وقفك سليم ✓",
  "@childSmartTilawahPraise": { "description": "SCR-CHD-032 praise" },
  "childSmartTilawahBanner": "مرجع التصحيح تلاوات مشايخ معتمدين من مصاحف مرخّصة — ومستشار العائلة يلاحظ بلطف، ملاحظة واحدة كل مرة حتى لا تثقل عليك.",
  "@childSmartTilawahBanner": { "description": "SCR-CHD-032 banner" },
  "childSmartTilawahEmptyTitle": "لا جلسة تلاوة بعد",
  "@childSmartTilawahEmptyTitle": { "description": "SCR-CHD-032 empty" },
  "childSmartTilawahEmptyMessage": "افتح وردك القرآني لتبدأ جلسة تلاوة ذكية لطيفة.",
  "@childSmartTilawahEmptyMessage": { "description": "SCR-CHD-032 empty msg" },
  "childSmartTilawahEmptyCta": "وردي القرآني",
  "@childSmartTilawahEmptyCta": { "description": "SCR-CHD-032 →014/025" },
  "childSmartTilawahLoadingSemantics": "جاري تحميل التلاوة الذكية",
  "@childSmartTilawahLoadingSemantics": { "description": "SCR-CHD-032 loading" },
  "childSmartTilawahParentLeanTitle": "التلاوة الذكية",
  "@childSmartTilawahParentLeanTitle": { "description": "SCR-CHD-032 parent lean" },
  "childSmartTilawahParentLeanMessage": "مدرب التلاوة اللطيف على جهاز الابن. التقدّم يظهر في تقدّم القرآن للوالدين.",
  "@childSmartTilawahParentLeanMessage": { "description": "SCR-CHD-032 parent lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "childSmartTilawahTitle")
    splice(ROOT / "app_ar.arb", AR, "childSmartTilawahTitle")
