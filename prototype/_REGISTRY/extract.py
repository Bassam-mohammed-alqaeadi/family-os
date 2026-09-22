#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
مستخرِج الخدمات — يبني services.csv من وثائق الجوانب الخمسة المعتمدة.
لا يُعدّل الوثائق. المصدر الوحيد للحقيقة هو الوثائق؛ وهذا السكربت يترجمها إلى سجل.
"""
import csv, re, os, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT  = os.path.join(BASE, "_REGISTRY", "services.csv")

# الجوانب الخمسة: (الملف، رمز المجال، اسم المجال)
DOCS = [
    ("06_DOMAIN_1_SECURITY.md",       "SEC", "الأمن والرعاية"),
    ("07_DOMAIN_2_COMMUNICATION.md",  "COM", "التواصل"),
    ("09_DOMAIN_3_EDUCATION.md",      "EDU", "التعليم"),
    ("11_DOMAIN_4_AI.md",             "AIC", "الذكاء"),
    ("12_DOMAIN_5_ADMINISTRATION.md", "ADM", "الإدارة"),
]

# الحروف العربية المستخدمة لترقيم الأنظمة الفرعية
ABJAD = ["أ","ب","ج","د","هـ","و","ز","ح","ط","ي","ك","ل"]
AR_DIGITS = {"٠":"0","١":"1","٢":"2","٣":"3","٤":"4","٥":"5","٦":"6","٧":"7","٨":"8","٩":"9"}

def ar2en(s):
    return "".join(AR_DIGITS.get(c, c) for c in s)

def clean(s):
    """تنظيف خلية من التشكيل الماركداوني."""
    s = s.replace("**", "").replace("`", "").strip()
    s = re.sub(r"\s+", " ", s)
    return s.strip()

# عنوان نظام فرعي:  ## أ — اسم النظام (٧ خدمات)
RE_SUBSYS = re.compile(r"^##\s+([" + "".join(set("".join(ABJAD))) + r"ـ]{1,2})\s*[—–-]\s*(.+)$")
# صف خدمة:  | أ-١ | اسم | حالة | P0 |
RE_ROW = re.compile(r"^\|\s*([\u0621-\u064A]{1,2})\s*[-–]\s*([٠-٩0-9]+)\s*\|(.+)$")

def parse_priority(cells):
    """استخراج الأولوية من آخر خلية تحوي P0/P1/P2/P3."""
    for c in reversed(cells):
        m = re.search(r"\bP([0-3])\b", c)
        if m:
            return "P" + m.group(1)
    return "P?"

def parse_status(cells, name_cell):
    """تحديد: موجودة أم جديدة، والرمز القديم إن وُجد."""
    blob = " ".join(cells) + " " + name_cell
    legacy = ""
    m = re.search(r"\b(S-[A-Z]{3}-\d{3}|AI-\d{3})\b", blob)
    if m:
        legacy = m.group(1)
    if "جديد" in blob and not legacy:
        return "جديدة", ""
    if legacy:
        return "موجودة", legacy
    if "قاعدة" in blob or "الميثاق" in blob:
        return "قاعدة حاكمة", ""
    return "جديدة", ""

def main():
    rows = []
    for fname, dom, dom_ar in DOCS:
        path = os.path.join(BASE, fname)
        if not os.path.exists(path):
            print("!! مفقود:", fname); continue

        cur_letter = ""
        cur_sub    = ""
        in_deleted = False   # لتجاهل جداول سجل الحذف
        seq = 0

        with open(path, encoding="utf-8") as fh:
            for line in fh:
                line = line.rstrip("\n")

                # أقسام يجب تجاهلها تمامًا
                if line.startswith("# القسم الخامس: سجل الحذف") or line.startswith("## ⛔"):
                    in_deleted = True
                if line.startswith("# القسم الثالث") or line.startswith("# القسم الرابع"):
                    in_deleted = False
                    cur_letter = ""     # انتهى قسم تفصيل الأنظمة
                if in_deleted:
                    continue

                m = RE_SUBSYS.match(line)
                if m:
                    cur_letter = m.group(1)
                    title = clean(m.group(2))
                    title = re.sub(r"\(.*?\)", "", title)
                    title = re.sub(r"[🎬🆕🌟🟣📿⛔✅]", "", title)
                    cur_sub = title.strip()
                    continue

                if not cur_letter:
                    continue

                m = RE_ROW.match(line)
                if not m:
                    continue
                if m.group(1) != cur_letter:
                    continue   # صف من جدول آخر

                num = int(ar2en(m.group(2)))
                cells = [clean(c) for c in m.group(3).split("|") if clean(c)]
                if not cells:
                    continue

                name = cells[0]
                name = re.sub(r"\s*\(.*?\)\s*$", "", name).strip()
                name = re.sub(r"^[📸🔗📄✍️🎤🌍🧠🎯⛔🔴🟡🟢]+\s*", "", name).strip()
                if not name or name in ("الخدمة", "القاعدة"):
                    continue

                prio = parse_priority(cells)
                status, legacy = parse_status(cells, name)

                seq += 1
                sid = "S-%s-%03d" % (dom, seq)
                rows.append({
                    "service_id": sid,
                    "domain": dom,
                    "domain_ar": dom_ar,
                    "subsystem_letter": cur_letter,
                    "subsystem": cur_sub,
                    "local_ref": "%s-%d" % (cur_letter, num),
                    "name": name,
                    "priority": prio,
                    "status": status,
                    "legacy_id": legacy,
                    "wave": "",
                    "screens": "",
                })

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8-sig", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)

    print("✅ استُخرجت %d خدمة → %s" % (len(rows), OUT))
    from collections import Counter
    for dom, _, dom_ar in [(d[1], d[0], d[2]) for d in DOCS]:
        n = sum(1 for r in rows if r["domain"] == dom)
        p0 = sum(1 for r in rows if r["domain"] == dom and r["priority"] == "P0")
        print("   %s %-14s %3d خدمة  (%d P0)" % (dom, dom_ar, n, p0))
    print("   " + "-"*34)
    print("   الإجمالي: %d خدمة (%d P0)" % (len(rows), sum(1 for r in rows if r["priority"]=="P0")))
    unknown = [r["service_id"] for r in rows if r["priority"] == "P?"]
    if unknown:
        print("   ⚠️ بلا أولوية:", ", ".join(unknown))

if __name__ == "__main__":
    main()
