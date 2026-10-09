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
  "addFromSourceAttachedTitle": "Attached sources ({count})",
  "@addFromSourceAttachedTitle": {
    "description": "SCR-FAT-041 attached SourceRef strip",
    "placeholders": { "count": { "type": "int" } }
  },
  "addFromSourceAttachedSemantics": "Attached learning sources, {count} items",
  "@addFromSourceAttachedSemantics": {
    "description": "SCR-FAT-041 attached strip semantics",
    "placeholders": { "count": { "type": "int" } }
  },
  "addFromSourceLabelPdfMath": "Math workbook PDF",
  "@addFromSourceLabelPdfMath": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelPdfScience": "Science unit PDF",
  "@addFromSourceLabelPdfScience": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelPdfDevice": "PDF from this device",
  "@addFromSourceLabelPdfDevice": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelLink": "Educational video link",
  "@addFromSourceLabelLink": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelTopic": "Topic seed for Advisor",
  "@addFromSourceLabelTopic": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelVoice": "Voice note for Advisor",
  "@addFromSourceLabelVoice": { "description": "SCR-FAT-041 SourceRef label" }
"""

AR = r"""
  "addFromSourceAttachedTitle": "مصادر مُرفقة ({count})",
  "@addFromSourceAttachedTitle": {
    "description": "SCR-FAT-041 attached SourceRef strip",
    "placeholders": { "count": { "type": "int" } }
  },
  "addFromSourceAttachedSemantics": "مصادر تعلّم مُرفقة، {count} عناصر",
  "@addFromSourceAttachedSemantics": {
    "description": "SCR-FAT-041 attached strip semantics",
    "placeholders": { "count": { "type": "int" } }
  },
  "addFromSourceLabelPdfMath": "ملف PDF لكتاب الرياضيات",
  "@addFromSourceLabelPdfMath": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelPdfScience": "ملف PDF لوحدة العلوم",
  "@addFromSourceLabelPdfScience": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelPdfDevice": "ملف PDF من هذا الجهاز",
  "@addFromSourceLabelPdfDevice": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelLink": "رابط فيديو تعليمي",
  "@addFromSourceLabelLink": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelTopic": "بذرة موضوع للمستشار",
  "@addFromSourceLabelTopic": { "description": "SCR-FAT-041 SourceRef label" },
  "addFromSourceLabelVoice": "ملاحظة صوتية للمستشار",
  "@addFromSourceLabelVoice": { "description": "SCR-FAT-041 SourceRef label" }
"""


def main() -> None:
    splice(ROOT / "app_en.arb", EN, "addFromSourceAttachedTitle")
    splice(ROOT / "app_ar.arb", AR, "addFromSourceAttachedTitle")


if __name__ == "__main__":
    main()
