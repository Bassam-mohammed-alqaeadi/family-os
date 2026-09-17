#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
المدقّق الآلي — الضمانة ضد التيه.
يفحص السجل المركزي ويكشف الفجوات لحظة حدوثها.

التشغيل:  python3 _REGISTRY/validate.py
"""
import csv, os, sys
from collections import Counter, defaultdict

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG  = os.path.join(BASE, "_REGISTRY")

def load(name):
    p = os.path.join(REG, name)
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8-sig") as fh:
        return list(csv.DictReader(fh))

def split_ids(cell):
    if not cell: return []
    return [x.strip() for x in cell.replace("،", ";").replace(",", ";").split(";") if x.strip()]

def main():
    errors, warnings, notes = [], [], []
    # الموجة النشطة: تُفحص تغطيتها بصرامة. الموجات اللاحقة تُرصد كملاحظات.
    ACTIVE_WAVE = os.environ.get("WAVE", "1")

    services = load("services.csv")
    journeys = load("journeys.csv")
    screens  = load("screens.csv")

    if services is None:
        print("❌ services.csv مفقود — شغّل extract.py أولًا"); sys.exit(1)

    svc_ids = {r["service_id"] for r in services}
    jrn_ids = {r["journey_id"] for r in journeys} if journeys else set()
    scr_ids = {r["screen_id"]  for r in screens}  if screens  else set()

    # ── فحص ١: المعرّفات المكررة ──────────────────────────────
    for label, rows, key in (("خدمة", services, "service_id"),
                             ("رحلة", journeys or [], "journey_id"),
                             ("شاشة", screens  or [], "screen_id")):
        dup = [k for k, v in Counter(r[key] for r in rows).items() if v > 1]
        for d in dup:
            errors.append("معرّف %s مكرر: %s" % (label, d))

    # ── فحص ٢: خدمة P0 بلا شاشة  (ثغرة تنفيذ) ────────────────
    if screens:
        covered = set()
        for s in screens:
            covered |= set(split_ids(s.get("services", "")))
        pending = 0
        for r in services:
            if r["service_id"] in covered:
                continue
            if r["priority"] == "P0" and r.get("wave") == ACTIVE_WAVE:
                errors.append("خدمة P0 في الموجة %s بلا شاشة: %s — %s"
                              % (ACTIVE_WAVE, r["service_id"], r["name"]))
            else:
                pending += 1
        if pending:
            notes.append("%d خدمة خارج الموجة %s تنتظر شاشاتها" % (pending, ACTIVE_WAVE))
    else:
        warnings.append("screens.csv غير موجود بعد — فحص تغطية الخدمات مؤجَّل")

    # ── فحص ٣: شاشة بلا رحلة  (شاشة زائدة) ───────────────────
    if screens and journeys:
        for s in screens:
            j = s.get("journey", "").strip()
            if not j:
                errors.append("شاشة بلا رحلة (تُحذف): %s — %s" % (s["screen_id"], s.get("name", "")))
            else:
                for jid in split_ids(j):
                    if jid not in jrn_ids:
                        errors.append("شاشة %s تحيل إلى رحلة غير موجودة: %s" % (s["screen_id"], jid))

    # ── فحص ٤: رحلة بلا شاشات  (رحلة ناقصة) ──────────────────
    if journeys and screens:
        used = set()
        for s in screens:
            used |= set(split_ids(s.get("journey", "")))
        for j in journeys:
            if j["journey_id"] not in used and j.get("wave") == ACTIVE_WAVE:
                errors.append("رحلة بلا شاشات: %s — %s" % (j["journey_id"], j.get("name", "")))

    # ── فحص ٥: إحالات الخدمات في الرحلات والشاشات ────────────
    for rows, key, label in ((journeys or [], "services", "رحلة"),
                             (screens  or [], "services", "شاشة")):
        for r in rows:
            rid = r.get("journey_id") or r.get("screen_id")
            for sid in split_ids(r.get(key, "")):
                if sid not in svc_ids:
                    errors.append("%s %s تحيل إلى خدمة غير موجودة: %s" % (label, rid, sid))

    # ── فحص ٦: الأولويات والموجات ────────────────────────────
    for r in services:
        if r["priority"] not in ("P0", "P1", "P2", "P3"):
            warnings.append("أولوية غير صالحة: %s (%s)" % (r["service_id"], r["priority"]))
    nowave = [r["service_id"] for r in services if r["priority"] == "P0" and not r.get("wave")]
    if nowave:
        warnings.append("خدمات P0 بلا موجة: %d خدمة" % len(nowave))

    # توزيع الموجات
    wave_stat = defaultdict(lambda: [0, 0, 0])   # [كل, P0, مغطاة]
    cov = set()
    if screens:
        for s in screens:
            cov |= set(split_ids(s.get("services", "")))
    for r in services:
        w = r.get("wave") or "?"
        wave_stat[w][0] += 1
        if r["priority"] == "P0":
            wave_stat[w][1] += 1
        if r["service_id"] in cov:
            wave_stat[w][2] += 1

    # ── التقرير ──────────────────────────────────────────────
    print("=" * 58)
    print("  🤖 المدقّق الآلي — Family OS")
    print("=" * 58)
    print()
    print("  📊 السجل:")
    print("     الخدمات : %d" % len(services))
    print("     الرحلات : %s" % (len(journeys) if journeys is not None else "— لم يُنشأ بعد"))
    print("     الشاشات : %s" % (len(screens)  if screens  is not None else "— لم يُنشأ بعد"))
    print()

    by_dom = defaultdict(lambda: [0, 0])
    for r in services:
        by_dom[r["domain_ar"]][0] += 1
        if r["priority"] == "P0":
            by_dom[r["domain_ar"]][1] += 1
    print("  📦 التوزيع:")
    for d, (n, p0) in by_dom.items():
        print("     %-14s %3d خدمة  ·  %3d P0" % (d, n, p0))
    print("     %-14s %3d خدمة  ·  %3d P0" % ("الإجمالي", len(services),
          sum(1 for r in services if r["priority"] == "P0")))
    print()
    print("  🌊 الموجات:")
    for w in sorted(wave_stat):
        n, p0, c = wave_stat[w]
        pct = (100 * c // n) if n else 0
        mark = " ← النشطة" if w == ACTIVE_WAVE else ""
        print("     الموجة %s   %3d خدمة · %3d P0 · التغطية %3d%%%s" % (w, n, p0, pct, mark))
    print()

    if errors:
        print("  ❌ أخطاء حاجزة (%d):" % len(errors))
        for e in errors[:25]:
            print("     • " + e)
        if len(errors) > 25:
            print("     … و%d خطأ آخر" % (len(errors) - 25))
        print()
    if warnings:
        print("  ⚠️  تنبيهات (%d):" % len(warnings))
        for w in warnings[:15]:
            print("     • " + w)
        print()
    if notes:
        print("  ℹ️  ملاحظات: %d خدمة P1/P2/P3 بلا شاشة بعد" % len(notes))
        print()

    if not errors:
        print("  ✅ لا أخطاء حاجزة — السجل متسق.")
    print("=" * 58)
    sys.exit(1 if errors else 0)

if __name__ == "__main__":
    main()
