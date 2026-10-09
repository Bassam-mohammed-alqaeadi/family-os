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
  "childInteractiveStoriesTitle": "My stories",
  "@childInteractiveStoriesTitle": { "description": "SCR-CHD-033 AppBar" },
  "childInteractiveStoriesChapterTitle": "Desert treasure — chapter 3",
  "@childInteractiveStoriesChapterTitle": { "description": "SCR-CHD-033 chapter" },
  "childInteractiveStoriesChapterBody": "You and your friend reach an old well. You find a bag of gold coins stamped with the caravan merchant's name… your friend whispers: \"No one will know!\"",
  "@childInteractiveStoriesChapterBody": { "description": "SCR-CHD-033 body" },
  "childInteractiveStoriesPrompt": "What do you do?",
  "@childInteractiveStoriesPrompt": { "description": "SCR-CHD-033 prompt" },
  "childInteractiveStoriesChoiceReturn": "Find the merchant and return the bag",
  "@childInteractiveStoriesChoiceReturn": { "description": "SCR-CHD-033 choice" },
  "childInteractiveStoriesChoiceTake": "Take it — no one will know",
  "@childInteractiveStoriesChoiceTake": { "description": "SCR-CHD-033 choice" },
  "childInteractiveStoriesChoiceAsk": "Ask my parent first",
  "@childInteractiveStoriesChoiceAsk": { "description": "SCR-CHD-033 choice" },
  "childInteractiveStoriesToastReturn": "You chose honesty! The merchant will reward you beyond imagining… ending: whoever leaves something for Allah, Allah replaces it with better.",
  "@childInteractiveStoriesToastReturn": { "description": "SCR-CHD-033 toast" },
  "childInteractiveStoriesToastTake": "Another path… you'll discover yourself in the ending: a calm heart cannot be bought with worldly gold.",
  "@childInteractiveStoriesToastTake": { "description": "SCR-CHD-033 toast" },
  "childInteractiveStoriesToastAsk": "Wisdom! Asking elders is the path of the wise — your parent in the story will surprise you.",
  "@childInteractiveStoriesToastAsk": { "description": "SCR-CHD-033 toast" },
  "childInteractiveStoriesFooter": "Your choices write the tale — there is never only one ending",
  "@childInteractiveStoriesFooter": { "description": "SCR-CHD-033 footer" },
  "childInteractiveStoriesEmptyTitle": "No story chapter yet",
  "@childInteractiveStoriesEmptyTitle": { "description": "SCR-CHD-033 empty" },
  "childInteractiveStoriesEmptyMessage": "Open My learning to unlock your next interactive story chapter.",
  "@childInteractiveStoriesEmptyMessage": { "description": "SCR-CHD-033 empty msg" },
  "childInteractiveStoriesEmptyCta": "My learning",
  "@childInteractiveStoriesEmptyCta": { "description": "SCR-CHD-033 →014" },
  "childInteractiveStoriesLoadingSemantics": "Loading interactive story",
  "@childInteractiveStoriesLoadingSemantics": { "description": "SCR-CHD-033 loading" },
  "childInteractiveStoriesParentLeanTitle": "Interactive stories",
  "@childInteractiveStoriesParentLeanTitle": { "description": "SCR-CHD-033 parent lean" },
  "childInteractiveStoriesParentLeanMessage": "Value-choice stories run on the child's device. Parents see themes in Family Advisor, never spoilers.",
  "@childInteractiveStoriesParentLeanMessage": { "description": "SCR-CHD-033 parent lean msg" }
"""

AR = r"""
  "childInteractiveStoriesTitle": "قصصي",
  "@childInteractiveStoriesTitle": { "description": "SCR-CHD-033 AppBar" },
  "childInteractiveStoriesChapterTitle": "كنز الصحراء — الفصل ٣",
  "@childInteractiveStoriesChapterTitle": { "description": "SCR-CHD-033 chapter" },
  "childInteractiveStoriesChapterBody": "وصلتَ أنت ورفيقك عند بئر قديمة. وجدتما كيسًا فيه دنانير ذهبية منقوش عليها اسم «تاجر القافلة»… ورفيقك يهمس: «لن يعرف أحد!»",
  "@childInteractiveStoriesChapterBody": { "description": "SCR-CHD-033 body" },
  "childInteractiveStoriesPrompt": "ماذا تفعل؟",
  "@childInteractiveStoriesPrompt": { "description": "SCR-CHD-033 prompt" },
  "childInteractiveStoriesChoiceReturn": "نبحث عن التاجر ونعيد الكيس",
  "@childInteractiveStoriesChoiceReturn": { "description": "SCR-CHD-033 choice" },
  "childInteractiveStoriesChoiceTake": "نأخذها — لن يعرف أحد",
  "@childInteractiveStoriesChoiceTake": { "description": "SCR-CHD-033 choice" },
  "childInteractiveStoriesChoiceAsk": "نسأل والدي أولًا",
  "@childInteractiveStoriesChoiceAsk": { "description": "SCR-CHD-033 choice" },
  "childInteractiveStoriesToastReturn": "اخترت الأمانة! التاجر سيكافئك بما لم تتخيل… وخاتمة الفصل: «من ترك شيئًا لله عوّضه الله خيرًا منه»",
  "@childInteractiveStoriesToastReturn": { "description": "SCR-CHD-033 toast" },
  "childInteractiveStoriesToastTake": "مسار آخر… وستكتشف بنفسك في الخاتمة: راحة القلب لا تُشترى بذهب الدنيا كله",
  "@childInteractiveStoriesToastTake": { "description": "SCR-CHD-033 toast" },
  "childInteractiveStoriesToastAsk": "حكمة! سؤال الكبار طريق الحكماء — والدك في القصة سيدهشك",
  "@childInteractiveStoriesToastAsk": { "description": "SCR-CHD-033 toast" },
  "childInteractiveStoriesFooter": "قراراتك تكتب الحكاية — لا توجد نهاية واحدة",
  "@childInteractiveStoriesFooter": { "description": "SCR-CHD-033 footer" },
  "childInteractiveStoriesEmptyTitle": "لا فصل قصة بعد",
  "@childInteractiveStoriesEmptyTitle": { "description": "SCR-CHD-033 empty" },
  "childInteractiveStoriesEmptyMessage": "افتح تعلّمي لفتح فصل قصتك التفاعلي التالي.",
  "@childInteractiveStoriesEmptyMessage": { "description": "SCR-CHD-033 empty msg" },
  "childInteractiveStoriesEmptyCta": "تعلّمي",
  "@childInteractiveStoriesEmptyCta": { "description": "SCR-CHD-033 →014" },
  "childInteractiveStoriesLoadingSemantics": "جاري تحميل القصة التفاعلية",
  "@childInteractiveStoriesLoadingSemantics": { "description": "SCR-CHD-033 loading" },
  "childInteractiveStoriesParentLeanTitle": "القصص التفاعلية",
  "@childInteractiveStoriesParentLeanTitle": { "description": "SCR-CHD-033 parent lean" },
  "childInteractiveStoriesParentLeanMessage": "قصص اختيارات القيم على جهاز الابن. الوالدان يريان الموضوعات في مستشار العائلة دون حرق للنهاية.",
  "@childInteractiveStoriesParentLeanMessage": { "description": "SCR-CHD-033 parent lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "childInteractiveStoriesTitle")
    splice(ROOT / "app_ar.arb", AR, "childInteractiveStoriesTitle")
