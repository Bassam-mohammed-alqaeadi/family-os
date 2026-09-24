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


EN082 = r"""
  "smartChoreTitle": "Smart chore distributor",
  "@smartChoreTitle": { "description": "SCR-FAT-082 AppBar" },
  "smartChoreProposalHeading": "This week's distribution suggestion",
  "@smartChoreProposalHeading": { "description": "SCR-FAT-082 proposal" },
  "smartChoreChildOne": "Child A",
  "@smartChoreChildOne": { "description": "SCR-FAT-082 Rule 23" },
  "smartChoreChildTwo": "Child B",
  "@smartChoreChildTwo": { "description": "SCR-FAT-082 Rule 23" },
  "smartChoreChildThree": "Child C",
  "@smartChoreChildThree": { "description": "SCR-FAT-082 Rule 23" },
  "smartChoreDishesPlants": "dishes (3 days) + plants",
  "@smartChoreDishesPlants": { "description": "SCR-FAT-082 chores" },
  "smartChoreLivingLaundry": "living room + laundry",
  "@smartChoreLivingLaundry": { "description": "SCR-FAT-082 chores" },
  "smartChoreTrashWater": "trash + watering plants",
  "@smartChoreTrashWater": { "description": "SCR-FAT-082 chores" },
  "smartChoreNoteExam": "Lighten Tuesday — exam day",
  "@smartChoreNoteExam": { "description": "SCR-FAT-082 note" },
  "smartChoreNoteRotated": "Rotated — was tired of dishes",
  "@smartChoreNoteRotated": { "description": "SCR-FAT-082 note" },
  "smartChoreNoteAge8": "Light chores for age 8",
  "@smartChoreNoteAge8": { "description": "SCR-FAT-082 note" },
  "smartChoreApproveCta": "Approve distribution",
  "@smartChoreApproveCta": { "description": "SCR-FAT-082 approve" },
  "smartChoreApprovedCta": "Approved",
  "@smartChoreApprovedCta": { "description": "SCR-FAT-082 approved" },
  "smartChoreShuffleCta": "Shuffle",
  "@smartChoreShuffleCta": { "description": "SCR-FAT-082 shuffle" },
  "smartChoreApproveToast": "Approved — each child got their tasks with set minutes",
  "@smartChoreApproveToast": { "description": "SCR-FAT-082 toast" },
  "smartChoreShuffleToast": "Alternate distribution ready — same fairness",
  "@smartChoreShuffleToast": { "description": "SCR-FAT-082 shuffle toast" },
  "smartChoreFairnessHeading": "Why this distribution is fair",
  "@smartChoreFairnessHeading": { "description": "SCR-FAT-082 fairness" },
  "smartChoreFairnessBody": "Equal minutes per child by age · no chore repeats for the same child two weeks · school schedules counted.",
  "@smartChoreFairnessBody": { "description": "SCR-FAT-082 fairness body" },
  "smartChoreObserverHint": "Approving chore distributions needs Partner level or above — you can review the proposal.",
  "@smartChoreObserverHint": { "description": "SCR-FAT-082 observer" },
  "smartChoreEmptyTitle": "No chore plan yet",
  "@smartChoreEmptyTitle": { "description": "SCR-FAT-082 empty" },
  "smartChoreEmptyMessage": "Add children so ChoreAI can propose a fair weekly distribution.",
  "@smartChoreEmptyMessage": { "description": "SCR-FAT-082 empty msg" },
  "smartChoreEmptyCta": "Add a child",
  "@smartChoreEmptyCta": { "description": "SCR-FAT-082 →003" },
  "smartChoreLoadingSemantics": "Loading chore distributor",
  "@smartChoreLoadingSemantics": { "description": "SCR-FAT-082 loading" },
  "smartChoreChildLeanTitle": "Chore distributor",
  "@smartChoreChildLeanTitle": { "description": "SCR-FAT-082 child lean" },
  "smartChoreChildLeanMessage": "Weekly chore planning is for parents. Your assigned tasks appear in My tasks.",
  "@smartChoreChildLeanMessage": { "description": "SCR-FAT-082 child lean msg" }
"""

AR082 = r"""
  "smartChoreTitle": "موزع المهام الذكي",
  "@smartChoreTitle": { "description": "SCR-FAT-082 AppBar" },
  "smartChoreProposalHeading": "اقتراح توزيع هذا الأسبوع",
  "@smartChoreProposalHeading": { "description": "SCR-FAT-082 proposal" },
  "smartChoreChildOne": "الابن أ",
  "@smartChoreChildOne": { "description": "SCR-FAT-082 Rule 23" },
  "smartChoreChildTwo": "الابن ب",
  "@smartChoreChildTwo": { "description": "SCR-FAT-082 Rule 23" },
  "smartChoreChildThree": "الابن ج",
  "@smartChoreChildThree": { "description": "SCR-FAT-082 Rule 23" },
  "smartChoreDishesPlants": "الصحون (٣ أيام) + النباتات",
  "@smartChoreDishesPlants": { "description": "SCR-FAT-082 chores" },
  "smartChoreLivingLaundry": "ترتيب الصالة + الغسيل",
  "@smartChoreLivingLaundry": { "description": "SCR-FAT-082 chores" },
  "smartChoreTrashWater": "إخراج النفايات + سقي النباتات",
  "@smartChoreTrashWater": { "description": "SCR-FAT-082 chores" },
  "smartChoreNoteExam": "خفّف عنه الثلاثاء — عنده اختبار",
  "@smartChoreNoteExam": { "description": "SCR-FAT-082 note" },
  "smartChoreNoteRotated": "بدّلنا مهامها — ملّت من الصحون",
  "@smartChoreNoteRotated": { "description": "SCR-FAT-082 note" },
  "smartChoreNoteAge8": "مهام خفيفة تناسب ٨ سنوات",
  "@smartChoreNoteAge8": { "description": "SCR-FAT-082 note" },
  "smartChoreApproveCta": "اعتمد التوزيع",
  "@smartChoreApproveCta": { "description": "SCR-FAT-082 approve" },
  "smartChoreApprovedCta": "مُعتمد",
  "@smartChoreApprovedCta": { "description": "SCR-FAT-082 approved" },
  "smartChoreShuffleCta": "بدّل",
  "@smartChoreShuffleCta": { "description": "SCR-FAT-082 shuffle" },
  "smartChoreApproveToast": "اعتُمد التوزيع — وصلت كل ابن مهامه بدقائقها المحددة",
  "@smartChoreApproveToast": { "description": "SCR-FAT-082 toast" },
  "smartChoreShuffleToast": "توزيع بديل جاهز — بنفس العدالة",
  "@smartChoreShuffleToast": { "description": "SCR-FAT-082 shuffle toast" },
  "smartChoreFairnessHeading": "لماذا هذا التوزيع عادل؟",
  "@smartChoreFairnessHeading": { "description": "SCR-FAT-082 fairness" },
  "smartChoreFairnessBody": "دقائق متساوية لكل ابن حسب عمره · لا مهمة تتكرر لنفس الابن أسبوعين · الجداول الدراسية محسوبة.",
  "@smartChoreFairnessBody": { "description": "SCR-FAT-082 fairness body" },
  "smartChoreObserverHint": "اعتماد توزيع المهام يحتاج مستوى شريكة أو أعلى — يمكنك مراجعة الاقتراح.",
  "@smartChoreObserverHint": { "description": "SCR-FAT-082 observer" },
  "smartChoreEmptyTitle": "لا خطة مهام بعد",
  "@smartChoreEmptyTitle": { "description": "SCR-FAT-082 empty" },
  "smartChoreEmptyMessage": "أضف أبناءً ليقترح موزع المهام توزيعًا عادلًا للأسبوع.",
  "@smartChoreEmptyMessage": { "description": "SCR-FAT-082 empty msg" },
  "smartChoreEmptyCta": "أضف ابنًا",
  "@smartChoreEmptyCta": { "description": "SCR-FAT-082 →003" },
  "smartChoreLoadingSemantics": "جاري تحميل موزع المهام",
  "@smartChoreLoadingSemantics": { "description": "SCR-FAT-082 loading" },
  "smartChoreChildLeanTitle": "موزع المهام",
  "@smartChoreChildLeanTitle": { "description": "SCR-FAT-082 child lean" },
  "smartChoreChildLeanMessage": "تخطيط المهام الأسبوعية للوالدين. مهامك تظهر في مهامي.",
  "@smartChoreChildLeanMessage": { "description": "SCR-FAT-082 child lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN082, "smartChoreTitle")
    splice(ROOT / "app_ar.arb", AR082, "smartChoreTitle")
