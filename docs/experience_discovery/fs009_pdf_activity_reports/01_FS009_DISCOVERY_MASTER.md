# FS-009 — PDF Activity Reports — Discovery Master

**Canonical ID:** `FS_009_PDF_Activity_Reports`  
**Title:** PDF Activity Reports  
**Date:** 2026-09-25  
**Phase:** 2 (analysis only)  

---

## 1. Authority sources checked

| Source | Finding |
|--------|---------|
| Owner Phase 2 identity | Named FS-009 = PDF Activity Reports |
| Domain 1 § ي التقارير والتحليلات | Usage reports, advanced analytics, 30-day retention, **weekly email summary**, peer compare — **no PDF wording** |
| Policy Register **G-7** | “Reports are settings-aware and built from real data” / weekly report generator — **no PDF** |
| Registry | SCR-FAT-069 / 073 / 086; S-SEC-050…053; S-AIC-019; JRN-FAT-33 / 36 / 45 |
| Flutter | `InMemoryChildUsageReportRepository`, `InMemoryWeeklyReportRepository` — fixtures; **no PDF export code** |
| Parent Studio PDF | **Education source upload** (FAT-041) — **not** activity reports |

---

## 2. Mission (evidence-bound)

Provide **parent-facing activity / usage reporting** (per-child usage analytics + weekly recommendation summary), settings-aware and built from real data (G-7).

**PDF as delivery format:** Owner title includes “PDF”, but **no approved Domain/Policy Register clause specifies PDF export**. Classify PDF packaging as **UNRESOLVED** (REP-C1) — do not invent PDF layout/export law.

Closest approved delivery: **in-app report UI** + **email weekly summary** (`S-SEC-053`).

---

## 3. Current repository truth

| Surface | State |
|---------|--------|
| SCR-FAT-069 usage report | ScreenBuild mock / InMemory fixtures |
| SCR-FAT-073 weekly + recommendation | Mock Advisor / InMemory |
| SCR-FAT-086 family moments (shares AIC-019) | Mock |
| Email weekly summary | Documented Domain; not live REM |
| PDF export of activity | **NOT DOCUMENTED · NOT IMPLEMENTED** |
| Retention 30d (S-SEC-052) | Documented; contradictions with other retention notes exist historically |

---

## 4. Capability honesty

| Capability | State |
|------------|--------|
| In-app usage/weekly UI | REAL LOCAL target; today MOCK fixtures |
| Preferences-aware generator (G-7) | Required; Stage-1 incomplete |
| Email delivery | MOCK-REMOTE / NOT CONFIGURED |
| PDF file generation | **UNSUPPORTED until Owner defines** (REP-C1) |
| Native DeviceActivityReport (Apple API) | Platform API name only — **not** this FS product name |

---

## 5. Open items

| ID | Item |
|----|------|
| **REP-C1** | Does “PDF” mandate export/shareable PDF, or is the title colloquial for “activity reports”? |
| **REP-C2** | Retention: 30d (S-SEC-052) vs other historical 90d/device-forever notes |
| **REP-C3** | Ownership split: SEC usage analytics vs AIC weekly recommendation — single FS-009 umbrella vs two authorities |

Working analysis baseline: FS-009 **owns the reporting product umbrella** (usage + weekly + email); AIC remains owner of **recommendation content** inside weekly report (suggest-only Rule 26).

---

## 6. Discovery acceptance

```text
FS-009 DISCOVERY: COMPLETE
PDF SPECIFIC LAW: UNRESOLVED (REP-C1)
IMPLEMENTATION: NOT AUTHORIZED
```
