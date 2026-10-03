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
  "childCallPlayTitle": "Call play",
  "@childCallPlayTitle": { "description": "SCR-CHD-036 AppBar" },
  "childCallPlayPeerGrandpa": "Grandpa",
  "@childCallPlayPeerGrandpa": { "description": "SCR-CHD-036 Rule 23 peer" },
  "childCallPlayYou": "You",
  "@childCallPlayYou": { "description": "SCR-CHD-036 you" },
  "childCallPlayHeroTitle": "Call with {peer}",
  "@childCallPlayHeroTitle": {
    "description": "SCR-CHD-036 hero",
    "placeholders": { "peer": { "type": "String" } }
  },
  "childCallPlayHeroSub": "Live now — and you are playing together!",
  "@childCallPlayHeroSub": { "description": "SCR-CHD-036 hero sub" },
  "childCallPlayGamesTitle": "Play while you talk",
  "@childCallPlayGamesTitle": { "description": "SCR-CHD-036 games" },
  "childCallPlayGameDraw": "Shared drawing board",
  "@childCallPlayGameDraw": { "description": "SCR-CHD-036 game" },
  "childCallPlayGameDrawSub": "Draw together at the same moment",
  "@childCallPlayGameDrawSub": { "description": "SCR-CHD-036 game sub" },
  "childCallPlayGameXo": "X-O",
  "@childCallPlayGameXo": { "description": "SCR-CHD-036 game" },
  "childCallPlayGameXoSub": "Grandpa is a champ — watch out!",
  "@childCallPlayGameXoSub": { "description": "SCR-CHD-036 game sub" },
  "childCallPlayGameQuiz": "Quiz race",
  "@childCallPlayGameQuiz": { "description": "SCR-CHD-036 game" },
  "childCallPlayGameQuizSub": "Who answers faster?",
  "@childCallPlayGameQuizSub": { "description": "SCR-CHD-036 game sub" },
  "childCallPlayCtaOpen": "Open",
  "@childCallPlayCtaOpen": { "description": "SCR-CHD-036 CTA" },
  "childCallPlayCtaPlay": "Play",
  "@childCallPlayCtaPlay": { "description": "SCR-CHD-036 CTA" },
  "childCallPlayCtaChallenge": "Challenge",
  "@childCallPlayCtaChallenge": { "description": "SCR-CHD-036 CTA" },
  "childCallPlayToastDraw": "Board open — Grandpa is drawing a palm! You finish the house",
  "@childCallPlayToastDraw": { "description": "SCR-CHD-036 toast" },
  "childCallPlayToastXo": "Grandpa took the center — what's your plan?",
  "@childCallPlayToastXo": { "description": "SCR-CHD-036 toast" },
  "childCallPlayToastQuiz": "Q1: capital of Yemen? — Grandpa tapped first!",
  "@childCallPlayToastQuiz": { "description": "SCR-CHD-036 toast" },
  "childCallPlayBanner": "Games stay inside your safe circle calls only — they bring you closer to people you love.",
  "@childCallPlayBanner": { "description": "SCR-CHD-036 banner" },
  "childCallPlayEmptyTitle": "No live call to play in",
  "@childCallPlayEmptyTitle": { "description": "SCR-CHD-036 empty" },
  "childCallPlayEmptyMessage": "When you are on a safe-circle call, drawing, X-O, and quiz race appear here.",
  "@childCallPlayEmptyMessage": { "description": "SCR-CHD-036 empty msg" },
  "childCallPlayEmptyCta": "My chats",
  "@childCallPlayEmptyCta": { "description": "SCR-CHD-036 →007" },
  "childCallPlayLoadingSemantics": "Loading call play",
  "@childCallPlayLoadingSemantics": { "description": "SCR-CHD-036 loading" },
  "childCallPlayParentLeanTitle": "Call play",
  "@childCallPlayParentLeanTitle": { "description": "SCR-CHD-036 parent lean" },
  "childCallPlayParentLeanMessage": "In-call games are on the child's device during safe-circle calls. Parents see call history, not the board.",
  "@childCallPlayParentLeanMessage": { "description": "SCR-CHD-036 parent lean msg" }
"""

AR = r"""
  "childCallPlayTitle": "مرح المكالمة",
  "@childCallPlayTitle": { "description": "SCR-CHD-036 AppBar" },
  "childCallPlayPeerGrandpa": "جدّو",
  "@childCallPlayPeerGrandpa": { "description": "SCR-CHD-036 Rule 23 peer" },
  "childCallPlayYou": "أنت",
  "@childCallPlayYou": { "description": "SCR-CHD-036 you" },
  "childCallPlayHeroTitle": "مكالمة مع {peer}",
  "@childCallPlayHeroTitle": {
    "description": "SCR-CHD-036 hero",
    "placeholders": { "peer": { "type": "String" } }
  },
  "childCallPlayHeroSub": "الآن — وتلعبان معًا!",
  "@childCallPlayHeroSub": { "description": "SCR-CHD-036 hero sub" },
  "childCallPlayGamesTitle": "العبا وأنتما تتكلمان",
  "@childCallPlayGamesTitle": { "description": "SCR-CHD-036 games" },
  "childCallPlayGameDraw": "لوحة رسم مشتركة",
  "@childCallPlayGameDraw": { "description": "SCR-CHD-036 game" },
  "childCallPlayGameDrawSub": "ترسمان معًا في نفس اللحظة",
  "@childCallPlayGameDrawSub": { "description": "SCR-CHD-036 game sub" },
  "childCallPlayGameXo": "إكس-أو",
  "@childCallPlayGameXo": { "description": "SCR-CHD-036 game" },
  "childCallPlayGameXoSub": "جدّو بطل فيها — انتبه!",
  "@childCallPlayGameXoSub": { "description": "SCR-CHD-036 game sub" },
  "childCallPlayGameQuiz": "سباق الأسئلة",
  "@childCallPlayGameQuiz": { "description": "SCR-CHD-036 game" },
  "childCallPlayGameQuizSub": "من يجيب أسرع؟",
  "@childCallPlayGameQuizSub": { "description": "SCR-CHD-036 game sub" },
  "childCallPlayCtaOpen": "افتح",
  "@childCallPlayCtaOpen": { "description": "SCR-CHD-036 CTA" },
  "childCallPlayCtaPlay": "العب",
  "@childCallPlayCtaPlay": { "description": "SCR-CHD-036 CTA" },
  "childCallPlayCtaChallenge": "تحدَّ",
  "@childCallPlayCtaChallenge": { "description": "SCR-CHD-036 CTA" },
  "childCallPlayToastDraw": "فُتحت اللوحة — جدّو يرسم نخلة! أكمل أنت البيت",
  "@childCallPlayToastDraw": { "description": "SCR-CHD-036 toast" },
  "childCallPlayToastXo": "جدّو بدأ بالوسط — خطتك؟",
  "@childCallPlayToastXo": { "description": "SCR-CHD-036 toast" },
  "childCallPlayToastQuiz": "سؤال ١: عاصمة اليمن؟ — جدّو ضغط قبلك!",
  "@childCallPlayToastQuiz": { "description": "SCR-CHD-036 toast" },
  "childCallPlayBanner": "الألعاب داخل مكالمات دائرتك الآمنة فقط — تقرّبك ممن تحب.",
  "@childCallPlayBanner": { "description": "SCR-CHD-036 banner" },
  "childCallPlayEmptyTitle": "لا مكالمة حية للعب",
  "@childCallPlayEmptyTitle": { "description": "SCR-CHD-036 empty" },
  "childCallPlayEmptyMessage": "عندما تكون في مكالمة دائرة آمنة، تظهر هنا الرسم وإكس-أو وسباق الأسئلة.",
  "@childCallPlayEmptyMessage": { "description": "SCR-CHD-036 empty msg" },
  "childCallPlayEmptyCta": "محادثاتي",
  "@childCallPlayEmptyCta": { "description": "SCR-CHD-036 →007" },
  "childCallPlayLoadingSemantics": "جاري تحميل مرح المكالمة",
  "@childCallPlayLoadingSemantics": { "description": "SCR-CHD-036 loading" },
  "childCallPlayParentLeanTitle": "مرح المكالمة",
  "@childCallPlayParentLeanTitle": { "description": "SCR-CHD-036 parent lean" },
  "childCallPlayParentLeanMessage": "ألعاب المكالمة على جهاز الابن أثناء مكالمات الدائرة الآمنة. الوالدان يريان سجل المكالمات لا اللوحة.",
  "@childCallPlayParentLeanMessage": { "description": "SCR-CHD-036 parent lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "childCallPlayTitle")
    splice(ROOT / "app_ar.arb", AR, "childCallPlayTitle")
