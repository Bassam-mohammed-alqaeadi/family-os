# 23 — Screen Time Screen Engineering Master

**Authoritative screen-engineering entry point for System #2**  
**Product authority:** [`../screen_time_final/13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md`](../screen_time_final/13_SCREEN_TIME_FINAL_MASTER_CONTRACT.md)  
**Date:** 2026-09-23  

**Phase:** SCREEN ENGINEERING DOCUMENTATION ONLY  

| Gate | Status |
|---|---|
| Application code modified | **NO** |
| Backend started | **NO** |
| Android/iOS enforcement started | **NO** |
| Other system started | **NO** |
| Product decisions reopened | **NO** |

---

## Verdict

Screen Time UI architecture is specified for all core parent/child surfaces, role variants, three-budget economy UI, request/grant UX (incl. Ruling C), Policy Health, degraded/offline honesty, components, wireflows, traceability, and a11y/RTL — **without implementation**.

---

## Doc index

| # | File |
|---|---|
| 01 | [01_SCREEN_ARCHITECTURE.md](01_SCREEN_ARCHITECTURE.md) |
| 02 | [02_FAT_032_ENGINEERING.md](02_FAT_032_ENGINEERING.md) |
| 03 | [03_FAT_033_ENGINEERING.md](03_FAT_033_ENGINEERING.md) |
| 04 | [04_FAT_034_ENGINEERING.md](04_FAT_034_ENGINEERING.md) |
| 05 | [05_FAT_035_ENGINEERING.md](05_FAT_035_ENGINEERING.md) |
| 06 | [06_FAT_037_ENGINEERING.md](06_FAT_037_ENGINEERING.md) |
| 07 | [07_FAT_038_ENGINEERING.md](07_FAT_038_ENGINEERING.md) |
| 08 | [08_FAT_069_ENGINEERING.md](08_FAT_069_ENGINEERING.md) |
| 09 | [09_FAT_085_ENGINEERING.md](09_FAT_085_ENGINEERING.md) |
| 10 | [10_CHD_004_ENGINEERING.md](10_CHD_004_ENGINEERING.md) |
| 11 | [11_CHD_019_ENGINEERING.md](11_CHD_019_ENGINEERING.md) |
| 12 | [12_CHD_020_ENGINEERING.md](12_CHD_020_ENGINEERING.md) |
| 13 | [13_CHD_021_ENGINEERING.md](13_CHD_021_ENGINEERING.md) |
| 14 | [14_ROLE_VARIANTS.md](14_ROLE_VARIANTS.md) |
| 15 | [15_MINUTES_ECONOMY_UI.md](15_MINUTES_ECONOMY_UI.md) |
| 16 | [16_REQUEST_GRANT_UX.md](16_REQUEST_GRANT_UX.md) |
| 17 | [17_POLICY_HEALTH_UX.md](17_POLICY_HEALTH_UX.md) |
| 18 | [18_DEGRADED_OFFLINE_UX.md](18_DEGRADED_OFFLINE_UX.md) |
| 19 | [19_COMPONENT_SPECIFICATION.md](19_COMPONENT_SPECIFICATION.md) |
| 20 | [20_SCREEN_TIME_WIREFLOW.md](20_SCREEN_TIME_WIREFLOW.md) |
| 21 | [21_SCREEN_TIME_TRACEABILITY.md](21_SCREEN_TIME_TRACEABILITY.md) |
| 22 | [22_ACCESSIBILITY_RTL.md](22_ACCESSIBILITY_RTL.md) |
| 23 | **This file** |

---

## Screens covered

FAT-032 · 033 · 034 · 035 · 037 · 038 · 069 · 085 · CHD-004 · 019 · 020 · 021  
(+ supporting links: Profile, FAT-031/036/045, CHD-005/008/018)

---

## Components identified

**Reuse:** AppCard, BannerNote, Tag, PrimaryBtn, RowTile, ProgressBar, Empty/Error, Toast, BottomSheetHost, SettingsPersistToggle, HubGrid  

**New (proposed):** ScreenTimeOverviewCard, RemainingMinutesCard, ActivePolicyBanner, ScheduleRuleCard, AppRuleCard, MinutesWalletCard, TemporaryGrantCard, RequestCard, RequestDecisionSheet, PolicyHealthCard, SyncStateIndicator, EnforcementStatusBadge, TimeWarningBanner, CalmExpirySurface, RoleActionGuard, WhyUnavailableSheet, MeteringHonestyBadge  

---

## Quality checklist

| Check | OK |
|---|---|
| Father / Observer / Partner / Full / Child | Yes |
| Three budgets separated | Yes |
| Grant ≠ earned · grant ≠ ModeException | Yes |
| SOS always available | Yes |
| No points/XP | Yes |
| WARNING ≤5m · calm expiry | Yes |
| Request loop specified | Yes |
| Precedence + Policy Health | Yes |
| Offline/degraded · SIMULATED vs ENFORCING | Yes |
| No global redesign / backend / OS / app code | Yes |

---

## Unresolved contradictions

| Item | Notes |
|---|---|
| Register S-5 vs ST-OD-011 | Product freeze already closed (suggest≠auto); UI follows ST-OD-011; Register amendment still docs follow-up |
| Engineering Time Balance facets vs freeze primary states | **Resolved in 01:** AVAILABLE/WARNING/EXPIRED primary; TEMPORARY_GRANT/WALLET_ONLY/OVERFLOW_BLOCKED are explanation facets + quantities — no LOW_TIME |
| Partner “Add Time” vs inbox-only | Spec prefers grants via FAT-033 for Partner; Primary/Full may use Overview Add Time — consistent with ceiling rules |

No product freeze reopened.

---

## Exact output path

`docs/experience_discovery/screen_time_screen_engineering/`

**STOP** after Screen Time Screen Engineering documentation. Next implementation only when Owner directs.
