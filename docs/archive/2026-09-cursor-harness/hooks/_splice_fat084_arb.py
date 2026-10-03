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
  "stagedProjectTitle": "Staged project",
  "@stagedProjectTitle": { "description": "SCR-FAT-084 AppBar" },
  "stagedProjectHomeGarden": "Our home garden",
  "@stagedProjectHomeGarden": { "description": "SCR-FAT-084 project" },
  "stagedProjectChildOne": "Child A",
  "@stagedProjectChildOne": { "description": "SCR-FAT-084 Rule 23" },
  "stagedProjectHeroTitle": "{child}'s project: {name}",
  "@stagedProjectHeroTitle": {
    "description": "SCR-FAT-084 hero",
    "placeholders": {
      "child": { "type": "String" },
      "name": { "type": "String" }
    }
  },
  "stagedProjectHeroSub": "{stages} stages · {weeks} weeks · stage {current} now",
  "@stagedProjectHeroSub": {
    "description": "SCR-FAT-084 hero sub",
    "placeholders": {
      "stages": { "type": "int" },
      "weeks": { "type": "int" },
      "current": { "type": "int" }
    }
  },
  "stagedProjectStageResearch": "S1: Research & plan",
  "@stagedProjectStageResearch": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStageResearchSub": "Picked 3 plants and drew the garden",
  "@stagedProjectStageResearchSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectStagePlant": "S2: Planting",
  "@stagedProjectStagePlant": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStagePlantSub": "Photo proof of planting — awaiting your confirm",
  "@stagedProjectStagePlantSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectStageWater": "S3: Water & care",
  "@stagedProjectStageWater": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStageWaterSub": "Unlocks when S2 is done",
  "@stagedProjectStageWaterSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectStageHarvest": "S4: Harvest & present",
  "@stagedProjectStageHarvest": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStageHarvestSub": "Family presentation!",
  "@stagedProjectStageHarvestSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectConfirmCta": "Confirm",
  "@stagedProjectConfirmCta": { "description": "SCR-FAT-084 confirm" },
  "stagedProjectConfirmToast": "Stage approved! +{minutes} min deposited",
  "@stagedProjectConfirmToast": {
    "description": "SCR-FAT-084 toast",
    "placeholders": { "minutes": { "type": "int" } }
  },
  "stagedProjectMinutesTag": "+{minutes} min",
  "@stagedProjectMinutesTag": {
    "description": "SCR-FAT-084 minutes tag",
    "placeholders": { "minutes": { "type": "int" } }
  },
  "stagedProjectTemplateCta": "+ New project from template",
  "@stagedProjectTemplateCta": { "description": "SCR-FAT-084 template" },
  "stagedProjectTemplateToast": "Templates ready: science model, family research, first app, charity…",
  "@stagedProjectTemplateToast": { "description": "SCR-FAT-084 template toast" },
  "stagedProjectEmptyTitle": "No staged project yet",
  "@stagedProjectEmptyTitle": { "description": "SCR-FAT-084 empty" },
  "stagedProjectEmptyMessage": "Add a child and create a multi-week staged project from the studio.",
  "@stagedProjectEmptyMessage": { "description": "SCR-FAT-084 empty msg" },
  "stagedProjectEmptyCta": "Add a child",
  "@stagedProjectEmptyCta": { "description": "SCR-FAT-084 →003" },
  "stagedProjectLoadingSemantics": "Loading staged project",
  "@stagedProjectLoadingSemantics": { "description": "SCR-FAT-084 loading" },
  "stagedProjectChildLeanTitle": "Staged project",
  "@stagedProjectChildLeanTitle": { "description": "SCR-FAT-084 child lean" },
  "stagedProjectChildLeanMessage": "Parents confirm stages. Your active stage lives in My learning / My tasks.",
  "@stagedProjectChildLeanMessage": { "description": "SCR-FAT-084 child lean msg" }
"""

AR = r"""
  "stagedProjectTitle": "مشروع بمراحل",
  "@stagedProjectTitle": { "description": "SCR-FAT-084 AppBar" },
  "stagedProjectHomeGarden": "حديقتنا المنزلية",
  "@stagedProjectHomeGarden": { "description": "SCR-FAT-084 project" },
  "stagedProjectChildOne": "الابن أ",
  "@stagedProjectChildOne": { "description": "SCR-FAT-084 Rule 23" },
  "stagedProjectHeroTitle": "مشروع {child}: {name}",
  "@stagedProjectHeroTitle": {
    "description": "SCR-FAT-084 hero",
    "placeholders": {
      "child": { "type": "String" },
      "name": { "type": "String" }
    }
  },
  "stagedProjectHeroSub": "{stages} مراحل · {weeks} أسابيع · المرحلة {current} الآن",
  "@stagedProjectHeroSub": {
    "description": "SCR-FAT-084 hero sub",
    "placeholders": {
      "stages": { "type": "int" },
      "weeks": { "type": "int" },
      "current": { "type": "int" }
    }
  },
  "stagedProjectStageResearch": "م١: البحث والتخطيط",
  "@stagedProjectStageResearch": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStageResearchSub": "اختار ٣ نباتات ورسم الحديقة",
  "@stagedProjectStageResearchSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectStagePlant": "م٢: الزراعة",
  "@stagedProjectStagePlant": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStagePlantSub": "صوّر إثبات الزراعة — بانتظار تأكيدك",
  "@stagedProjectStagePlantSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectStageWater": "م٣: المتابعة والري",
  "@stagedProjectStageWater": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStageWaterSub": "تُفتح بإتمام م٢",
  "@stagedProjectStageWaterSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectStageHarvest": "م٤: الحصاد والعرض",
  "@stagedProjectStageHarvest": { "description": "SCR-FAT-084 stage" },
  "stagedProjectStageHarvestSub": "عرض تقديمي للعائلة!",
  "@stagedProjectStageHarvestSub": { "description": "SCR-FAT-084 stage sub" },
  "stagedProjectConfirmCta": "أكّد",
  "@stagedProjectConfirmCta": { "description": "SCR-FAT-084 confirm" },
  "stagedProjectConfirmToast": "اعتمدت المرحلة! +{minutes} د أُودعت",
  "@stagedProjectConfirmToast": {
    "description": "SCR-FAT-084 toast",
    "placeholders": { "minutes": { "type": "int" } }
  },
  "stagedProjectMinutesTag": "+{minutes} د",
  "@stagedProjectMinutesTag": {
    "description": "SCR-FAT-084 minutes tag",
    "placeholders": { "minutes": { "type": "int" } }
  },
  "stagedProjectTemplateCta": "+ مشروع جديد من قالب",
  "@stagedProjectTemplateCta": { "description": "SCR-FAT-084 template" },
  "stagedProjectTemplateToast": "قوالب جاهزة: مجسم علمي، بحث عائلي، تطبيق أول، مشروع خيري…",
  "@stagedProjectTemplateToast": { "description": "SCR-FAT-084 template toast" },
  "stagedProjectEmptyTitle": "لا مشروع بمراحل بعد",
  "@stagedProjectEmptyTitle": { "description": "SCR-FAT-084 empty" },
  "stagedProjectEmptyMessage": "أضف ابنًا وأنشئ مشروعًا متعدد الأسابيع من الاستوديو.",
  "@stagedProjectEmptyMessage": { "description": "SCR-FAT-084 empty msg" },
  "stagedProjectEmptyCta": "أضف ابنًا",
  "@stagedProjectEmptyCta": { "description": "SCR-FAT-084 →003" },
  "stagedProjectLoadingSemantics": "جاري تحميل المشروع بمراحل",
  "@stagedProjectLoadingSemantics": { "description": "SCR-FAT-084 loading" },
  "stagedProjectChildLeanTitle": "مشروع بمراحل",
  "@stagedProjectChildLeanTitle": { "description": "SCR-FAT-084 child lean" },
  "stagedProjectChildLeanMessage": "الوالدان يؤكدان المراحل. مرحلتك النشطة في تعلّمي / مهامي.",
  "@stagedProjectChildLeanMessage": { "description": "SCR-FAT-084 child lean msg" }
"""

if __name__ == "__main__":
    splice(ROOT / "app_en.arb", EN, "stagedProjectTitle")
    splice(ROOT / "app_ar.arb", AR, "stagedProjectTitle")
