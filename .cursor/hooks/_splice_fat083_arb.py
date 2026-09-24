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
  "advisorVoiceTitle": "Talk with Family Advisor",
  "@advisorVoiceTitle": { "description": "SCR-FAT-083 AppBar" },
  "advisorVoiceHint": "Press and speak — while driving or hands-busy",
  "@advisorVoiceHint": { "description": "SCR-FAT-083 hint" },
  "advisorVoiceTalkCta": "Press and talk",
  "@advisorVoiceTalkCta": { "description": "SCR-FAT-083 talk" },
  "advisorVoiceListeningToast": "Listening… answers from your family data only",
  "@advisorVoiceListeningToast": { "description": "SCR-FAT-083 toast" },
  "advisorVoiceLastHeading": "Last conversation",
  "@advisorVoiceLastHeading": { "description": "SCR-FAT-083 last" },
  "advisorVoiceUserHomework": "Did Child A finish homework?",
  "@advisorVoiceUserHomework": { "description": "SCR-FAT-083 user · Rule 23" },
  "advisorVoiceReplyHomework": "Yes — finished math and science an hour ago; English review is due tomorrow.",
  "@advisorVoiceReplyHomework": { "description": "SCR-FAT-083 reply · Rule 23" },
  "advisorVoiceHonestyBanner": "Same honesty pledge: if data is thin, it says aloud — «I do not know precisely enough».",
  "@advisorVoiceHonestyBanner": { "description": "SCR-FAT-083 honesty" },
  "advisorVoiceEmptyTitle": "No voice advisor yet",
  "@advisorVoiceEmptyTitle": { "description": "SCR-FAT-083 empty" },
  "advisorVoiceEmptyMessage": "Add a child so Family Advisor voice can answer from family data.",
  "@advisorVoiceEmptyMessage": { "description": "SCR-FAT-083 empty msg" },
  "advisorVoiceEmptyCta": "Add a child",
  "@advisorVoiceEmptyCta": { "description": "SCR-FAT-083 →003" },
  "advisorVoiceLoadingSemantics": "Loading advisor voice",
  "@advisorVoiceLoadingSemantics": { "description": "SCR-FAT-083 loading" },
  "advisorVoiceChildLeanTitle": "Advisor voice",
  "@advisorVoiceChildLeanTitle": { "description": "SCR-FAT-083 child lean" },
  "advisorVoiceChildLeanMessage": "Parent voice mode is for parents. Your tutor voice lives in My learning.",
  "@advisorVoiceChildLeanMessage": { "description": "SCR-FAT-083 child lean msg" }
"""

AR = r"""
  "advisorVoiceTitle": "تحدث مع مستشار العائلة",
  "@advisorVoiceTitle": { "description": "SCR-FAT-083 AppBar" },
  "advisorVoiceHint": "اضغط وتكلم — وأنت تقود السيارة أو مشغول اليدين",
  "@advisorVoiceHint": { "description": "SCR-FAT-083 hint" },
  "advisorVoiceTalkCta": "اضغط وتحدث",
  "@advisorVoiceTalkCta": { "description": "SCR-FAT-083 talk" },
  "advisorVoiceListeningToast": "يستمع… يجيب صوتًا من بيانات عائلتك فقط",
  "@advisorVoiceListeningToast": { "description": "SCR-FAT-083 toast" },
  "advisorVoiceLastHeading": "آخر محادثة",
  "@advisorVoiceLastHeading": { "description": "SCR-FAT-083 last" },
  "advisorVoiceUserHomework": "هل أنهى الابن أ واجباته؟",
  "@advisorVoiceUserHomework": { "description": "SCR-FAT-083 user · Rule 23" },
  "advisorVoiceReplyHomework": "نعم — أنهى الرياضيات والعلوم قبل ساعة، وبقي له مراجعة الإنجليزية المستحقة غدًا.",
  "@advisorVoiceReplyHomework": { "description": "SCR-FAT-083 reply · Rule 23" },
  "advisorVoiceHonestyBanner": "نفس عهد الصدق: إن نقصت البيانات سيقولها صوتًا — «لا أعلم بدقة كافية».",
  "@advisorVoiceHonestyBanner": { "description": "SCR-FAT-083 honesty" },
  "advisorVoiceEmptyTitle": "لا محادثة صوتية بعد",
  "@advisorVoiceEmptyTitle": { "description": "SCR-FAT-083 empty" },
  "advisorVoiceEmptyMessage": "أضف ابنًا ليجيب مستشار العائلة صوتًا من بيانات العائلة.",
  "@advisorVoiceEmptyMessage": { "description": "SCR-FAT-083 empty msg" },
  "advisorVoiceEmptyCta": "أضف ابنًا",
  "@advisorVoiceEmptyCta": { "description": "SCR-FAT-083 →003" },
  "advisorVoiceLoadingSemantics": "جاري تحميل المحادثة الصوتية",
  "@advisorVoiceLoadingSemantics": { "description": "SCR-FAT-083 loading" },
  "advisorVoiceChildLeanTitle": "محادثة المستشار الصوتية",
  "@advisorVoiceChildLeanTitle": { "description": "SCR-FAT-083 child lean" },
  "advisorVoiceChildLeanMessage": "الوضع الصوتي للوالدين. صوت معلّمك في تعلّمي.",
  "@advisorVoiceChildLeanMessage": { "description": "SCR-FAT-083 child lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "advisorVoiceTitle")
    splice(ROOT / "app_ar.arb", AR, "advisorVoiceTitle")
