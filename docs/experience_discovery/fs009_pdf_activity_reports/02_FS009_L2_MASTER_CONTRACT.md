# FS-009 — PDF Activity Reports — L2 Master Contract

**Canonical ID:** `FS_009_PDF_Activity_Reports`  
**Date:** 2026-09-25  
**Status:** L2 DRAFT from Domain 1 § ي + G-7 + registry  
**PDF export:** OPEN (REP-C1)  

---

## 1. Responsibility

Own **activity reporting** for parents: per-child usage analytics, retention window, weekly summary delivery channels (in-app + email). Consume Screen Time / WF / AC / Modes **facts**; do not become a second enforcement engine.

## 2. Domain ownership

| Fact | Owner |
|------|--------|
| Usage report aggregation view | **FS-009** |
| Raw ST minutes / schedules | Screen Time / Policy (existing) |
| Weekly recommendation text | Insights/Advisor repos (Rule 26) — FS-009 **hosts/presents** |
| Email transport | REMOTE (boundary only) |
| Forget / privacy purge respect | Privacy / Audit (FAT-059/060) — reports must honor |
| Peer compare | Domain ي-٥ P3 — under FS-009 umbrella if retained |

## 3. Inputs / outputs

**Inputs:** ChildId; date range; notification/privacy prefs; ST/usage facts; optional Advisor weekly suggestion payload.  

**Outputs:** UsageReportSnapshot; WeeklyReportSnapshot; (optional) EmailJob; (optional OPEN) PdfArtifact.

## 4. Invariants

1. G-7: reports reflect **settings** and **real data** — never planted prototype numerals in production.  
2. Retention default **30 days** (S-SEC-052) unless Owner revises REP-C2.  
3. Respect Advisor forget / privacy collection toggles where Register requires.  
4. Safety ungated: reports never disable SOS/location/chat.  
5. AI recommendations remain **suggest-only** (no execute).  
6. PDF: **no invariant** until REP-C1 resolved.

## 5. State / offline

- Local-first: compute/cache report from Local facts when available.  
- Offline: show last Local snapshot + honesty if stale.  
- Email: queue Local outbox ≠ delivered (MOCK-REMOTE until REM).  
- PDF: N/A until specified.

## 6. Cross-system map

```
ST / WF / AC / Modes facts ──► FS-009 aggregator
Advisor Insights ────────────► weekly recommendation slot
Privacy prefs ───────────────► retention / redaction
Notification prefs ──────────► email enablement
Outbox / REM ────────────────► email (later)
```

## 7. UI / journey impact (existing — no redesign)

| Screen | Journey | Role |
|--------|---------|------|
| SCR-FAT-069 | JRN-FAT-33 | Usage report host |
| SCR-FAT-073 | JRN-FAT-36 | Weekly + recommendation |
| SCR-FAT-086 | JRN-FAT-45 | Pride moments / weekly retention engine |

Missing states to document for future: empty, loading, error, offline-stale, email-not-configured, PDF-unavailable (if PDF later required).

## 8. Native / Remote

| Plane | Boundary |
|-------|----------|
| Aggregation | Local |
| Email | REMOTE |
| PDF render | UNRESOLVED — if required, likely Local render + share sheet (NAT share) |
| Apple DeviceActivityReport API | Not this product; do not conflate |

## 9. L2 acceptance

```text
FS-009 L2: DRAFT COMPLETE
OPEN: REP-C1 PDF · REP-C2 retention · REP-C3 AIC split nuance
IMPLEMENTATION: NOT AUTHORIZED
```
