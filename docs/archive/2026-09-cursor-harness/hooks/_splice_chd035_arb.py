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
  "childFocusSoundsTitle": "Focus sounds",
  "@childFocusSoundsTitle": { "description": "SCR-CHD-035 AppBar" },
  "childFocusSoundsRain": "Quiet rain",
  "@childFocusSoundsRain": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsWaves": "Waves",
  "@childFocusSoundsWaves": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsForest": "Forest",
  "@childFocusSoundsForest": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsFire": "Hearth",
  "@childFocusSoundsFire": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsToastRain": "Quiet rain is playing softly…",
  "@childFocusSoundsToastRain": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsToastWaves": "Ocean waves…",
  "@childFocusSoundsToastWaves": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsToastForest": "Leaves in the forest…",
  "@childFocusSoundsToastForest": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsToastFire": "Warm hearth…",
  "@childFocusSoundsToastFire": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsWithFocusTitle": "With focus mode",
  "@childFocusSoundsWithFocusTitle": { "description": "SCR-CHD-035 settings" },
  "childFocusSoundsAutoTitle": "Auto-play with focus session",
  "@childFocusSoundsAutoTitle": { "description": "SCR-CHD-035 auto" },
  "childFocusSoundsAutoSub": "Sound starts and stops with the session",
  "@childFocusSoundsAutoSub": { "description": "SCR-CHD-035 auto sub" },
  "childFocusSoundsFadeTitle": "Gentle fade in the last two minutes",
  "@childFocusSoundsFadeTitle": { "description": "SCR-CHD-035 fade" },
  "childFocusSoundsFadeSub": "Softly warns you the session is ending",
  "@childFocusSoundsFadeSub": { "description": "SCR-CHD-035 fade sub" },
  "childFocusSoundsStartCta": "Start a focus session now — sound with you",
  "@childFocusSoundsStartCta": { "description": "SCR-CHD-035 →018" },
  "childFocusSoundsBanner": "Steady natural sounds — no words, no beat. That is what helps the brain focus.",
  "@childFocusSoundsBanner": { "description": "SCR-CHD-035 banner" },
  "childFocusSoundsEmptyTitle": "No focus sounds yet",
  "@childFocusSoundsEmptyTitle": { "description": "SCR-CHD-035 empty" },
  "childFocusSoundsEmptyMessage": "Open focus mode to unlock calm nature loops for your sessions.",
  "@childFocusSoundsEmptyMessage": { "description": "SCR-CHD-035 empty msg" },
  "childFocusSoundsEmptyCta": "Focus mode",
  "@childFocusSoundsEmptyCta": { "description": "SCR-CHD-035 empty CTA" },
  "childFocusSoundsLoadingSemantics": "Loading focus sounds",
  "@childFocusSoundsLoadingSemantics": { "description": "SCR-CHD-035 loading" },
  "childFocusSoundsParentLeanTitle": "Focus sounds",
  "@childFocusSoundsParentLeanTitle": { "description": "SCR-CHD-035 parent lean" },
  "childFocusSoundsParentLeanMessage": "Nature loops live on the child's device next to focus mode. Parents see session stats, not the playlist.",
  "@childFocusSoundsParentLeanMessage": { "description": "SCR-CHD-035 parent lean msg" }
"""

AR = r"""
  "childFocusSoundsTitle": "أصوات التركيز",
  "@childFocusSoundsTitle": { "description": "SCR-CHD-035 AppBar" },
  "childFocusSoundsRain": "مطر هادئ",
  "@childFocusSoundsRain": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsWaves": "أمواج",
  "@childFocusSoundsWaves": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsForest": "غابة",
  "@childFocusSoundsForest": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsFire": "موقد",
  "@childFocusSoundsFire": { "description": "SCR-CHD-035 sound" },
  "childFocusSoundsToastRain": "صوت المطر يعمل بهدوء…",
  "@childFocusSoundsToastRain": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsToastWaves": "أمواج البحر…",
  "@childFocusSoundsToastWaves": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsToastForest": "حفيف الأشجار…",
  "@childFocusSoundsToastForest": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsToastFire": "دفء الموقد…",
  "@childFocusSoundsToastFire": { "description": "SCR-CHD-035 toast" },
  "childFocusSoundsWithFocusTitle": "مع وضع التركيز",
  "@childFocusSoundsWithFocusTitle": { "description": "SCR-CHD-035 settings" },
  "childFocusSoundsAutoTitle": "تشغيل تلقائي مع جلسة التركيز",
  "@childFocusSoundsAutoTitle": { "description": "SCR-CHD-035 auto" },
  "childFocusSoundsAutoSub": "يبدأ الصوت ويتوقف معها",
  "@childFocusSoundsAutoSub": { "description": "SCR-CHD-035 auto sub" },
  "childFocusSoundsFadeTitle": "خفوت تدريجي آخر دقيقتين",
  "@childFocusSoundsFadeTitle": { "description": "SCR-CHD-035 fade" },
  "childFocusSoundsFadeSub": "ينبهك بلطف أن الجلسة تنتهي",
  "@childFocusSoundsFadeSub": { "description": "SCR-CHD-035 fade sub" },
  "childFocusSoundsStartCta": "ابدأ جلسة تركيز الآن — والصوت معك",
  "@childFocusSoundsStartCta": { "description": "SCR-CHD-035 →018" },
  "childFocusSoundsBanner": "أصوات طبيعية ثابتة بلا كلمات ولا إيقاع — هذا ما يساعد الدماغ على التركيز.",
  "@childFocusSoundsBanner": { "description": "SCR-CHD-035 banner" },
  "childFocusSoundsEmptyTitle": "لا أصوات تركيز بعد",
  "@childFocusSoundsEmptyTitle": { "description": "SCR-CHD-035 empty" },
  "childFocusSoundsEmptyMessage": "افتح وضع التركيز لفتح حلقات الطبيعة الهادئة لجلساتك.",
  "@childFocusSoundsEmptyMessage": { "description": "SCR-CHD-035 empty msg" },
  "childFocusSoundsEmptyCta": "وضع التركيز",
  "@childFocusSoundsEmptyCta": { "description": "SCR-CHD-035 empty CTA" },
  "childFocusSoundsLoadingSemantics": "جاري تحميل أصوات التركيز",
  "@childFocusSoundsLoadingSemantics": { "description": "SCR-CHD-035 loading" },
  "childFocusSoundsParentLeanTitle": "أصوات التركيز",
  "@childFocusSoundsParentLeanTitle": { "description": "SCR-CHD-035 parent lean" },
  "childFocusSoundsParentLeanMessage": "حلقات الطبيعة على جهاز الابن بجانب وضع التركيز. الوالدان يريان إحصاءات الجلسة لا قائمة الأصوات.",
  "@childFocusSoundsParentLeanMessage": { "description": "SCR-CHD-035 parent lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "childFocusSoundsTitle")
    splice(ROOT / "app_ar.arb", AR, "childFocusSoundsTitle")
