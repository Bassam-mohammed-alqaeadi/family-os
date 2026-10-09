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
  "childStickersBackgroundsTitle": "My stickers",
  "@childStickersBackgroundsTitle": { "description": "SCR-CHD-037 AppBar" },
  "childStickersBackgroundsStickersTitle": "Your stickers",
  "@childStickersBackgroundsStickersTitle": { "description": "SCR-CHD-037 stickers" },
  "childStickersBackgroundsSpaceHint": "Space pack unlocks after two Quran wards — you are close!",
  "@childStickersBackgroundsSpaceHint": { "description": "SCR-CHD-037 hint" },
  "childStickersBackgroundsUnlockCta": "Unlocks after two wards",
  "@childStickersBackgroundsUnlockCta": { "description": "SCR-CHD-037 unlock CTA" },
  "childStickersBackgroundsUnlockToast": "Space pack unlocks automatically after two wards — you are {wards} ward away!",
  "@childStickersBackgroundsUnlockToast": {
    "description": "SCR-CHD-037 unlock toast",
    "placeholders": { "wards": { "type": "int" } }
  },
  "childStickersBackgroundsBgTitle": "Family chat background",
  "@childStickersBackgroundsBgTitle": { "description": "SCR-CHD-037 bg" },
  "childStickersBackgroundsBgSemantics": "Chat background {id}",
  "@childStickersBackgroundsBgSemantics": {
    "description": "SCR-CHD-037 bg semantics",
    "placeholders": { "id": { "type": "String" } }
  },
  "childStickersBackgroundsBgToast": "Background changed — looking great!",
  "@childStickersBackgroundsBgToast": { "description": "SCR-CHD-037 bg toast" },
  "childStickersBackgroundsBanner": "Every sticker is drawn with care and stays modest — express yourself in your sweet way.",
  "@childStickersBackgroundsBanner": { "description": "SCR-CHD-037 banner" },
  "childStickersBackgroundsEmptyTitle": "No sticker pack yet",
  "@childStickersBackgroundsEmptyTitle": { "description": "SCR-CHD-037 empty" },
  "childStickersBackgroundsEmptyMessage": "Open family chat to pick stickers and a wallpaper for your conversations.",
  "@childStickersBackgroundsEmptyMessage": { "description": "SCR-CHD-037 empty msg" },
  "childStickersBackgroundsEmptyCta": "My chats",
  "@childStickersBackgroundsEmptyCta": { "description": "SCR-CHD-037 →007" },
  "childStickersBackgroundsLoadingSemantics": "Loading stickers and backgrounds",
  "@childStickersBackgroundsLoadingSemantics": { "description": "SCR-CHD-037 loading" },
  "childStickersBackgroundsParentLeanTitle": "Stickers & backgrounds",
  "@childStickersBackgroundsParentLeanTitle": { "description": "SCR-CHD-037 parent lean" },
  "childStickersBackgroundsParentLeanMessage": "Modest sticker packs live on the child's device. Parents approve packs from Studio, not the picker.",
  "@childStickersBackgroundsParentLeanMessage": { "description": "SCR-CHD-037 parent lean msg" }
"""

AR = r"""
  "childStickersBackgroundsTitle": "ملصقاتي",
  "@childStickersBackgroundsTitle": { "description": "SCR-CHD-037 AppBar" },
  "childStickersBackgroundsStickersTitle": "ملصقاتك",
  "@childStickersBackgroundsStickersTitle": { "description": "SCR-CHD-037 stickers" },
  "childStickersBackgroundsSpaceHint": "حزمة «الفضاء» تُفتح بإنجاز وردين — أنت قريب!",
  "@childStickersBackgroundsSpaceHint": { "description": "SCR-CHD-037 hint" },
  "childStickersBackgroundsUnlockCta": "تُفتح بإنجاز وردين",
  "@childStickersBackgroundsUnlockCta": { "description": "SCR-CHD-037 unlock CTA" },
  "childStickersBackgroundsUnlockToast": "حزمة الفضاء تُفتح تلقائيًا فور إتمام وردين — أنت على بعد {wards} ورد!",
  "@childStickersBackgroundsUnlockToast": {
    "description": "SCR-CHD-037 unlock toast",
    "placeholders": { "wards": { "type": "int" } }
  },
  "childStickersBackgroundsBgTitle": "خلفية محادثة العائلة",
  "@childStickersBackgroundsBgTitle": { "description": "SCR-CHD-037 bg" },
  "childStickersBackgroundsBgSemantics": "خلفية محادثة {id}",
  "@childStickersBackgroundsBgSemantics": {
    "description": "SCR-CHD-037 bg semantics",
    "placeholders": { "id": { "type": "String" } }
  },
  "childStickersBackgroundsBgToast": "تغيرت خلفيتك — شكلها رهيب!",
  "@childStickersBackgroundsBgToast": { "description": "SCR-CHD-037 bg toast" },
  "childStickersBackgroundsBanner": "كل الملصقات مرسومة بعناية ومهذبة — عبّر عن نفسك بشخصيتك الحلوة.",
  "@childStickersBackgroundsBanner": { "description": "SCR-CHD-037 banner" },
  "childStickersBackgroundsEmptyTitle": "لا حزمة ملصقات بعد",
  "@childStickersBackgroundsEmptyTitle": { "description": "SCR-CHD-037 empty" },
  "childStickersBackgroundsEmptyMessage": "افتح محادثة العائلة لاختيار ملصقات وخلفية لمحادثاتك.",
  "@childStickersBackgroundsEmptyMessage": { "description": "SCR-CHD-037 empty msg" },
  "childStickersBackgroundsEmptyCta": "محادثاتي",
  "@childStickersBackgroundsEmptyCta": { "description": "SCR-CHD-037 →007" },
  "childStickersBackgroundsLoadingSemantics": "جاري تحميل الملصقات والخلفيات",
  "@childStickersBackgroundsLoadingSemantics": { "description": "SCR-CHD-037 loading" },
  "childStickersBackgroundsParentLeanTitle": "الملصقات والخلفيات",
  "@childStickersBackgroundsParentLeanTitle": { "description": "SCR-CHD-037 parent lean" },
  "childStickersBackgroundsParentLeanMessage": "حزم الملصقات المهذبة على جهاز الابن. الوالدان يعتمدون الحزم من الاستوديو لا من المنتقي.",
  "@childStickersBackgroundsParentLeanMessage": { "description": "SCR-CHD-037 parent lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "childStickersBackgroundsTitle")
    splice(ROOT / "app_ar.arb", AR, "childStickersBackgroundsTitle")
