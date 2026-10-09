# 12 — Screen Time Decision Closure Report

**Date:** 2026-09-23  
**System:** #2 only  
**Result:** Product decisions **CLOSED / FROZEN**

---

## 1. What was frozen

All ST-OD-001…012 plus additional freezes:

- Temporary Grant child-wide  
- Earned Minutes do not bypass hard schedules/modes  
- No mandatory LOW_TIME  
- Three-part remaining model  
- Precedence P0→P6  
- Minutes buckets + future consume order  
- Request loop shape  
- Child / Mother experience postures  
- Honesty law  
- SOS universal availability  

**Owner decisions remaining:** **NONE**  
(Platform feasibility reviews may follow; they are not open product forks.)

---

## 2. Resolved contradictions / clarifications

| Topic | Resolution |
|---|---|
| Discovery P4 name “Device Daily Cap” vs ST-OD-001 shared child budget | **Clarified:** ladder step P4 is the **child-level** daily entertainment cap; devices enforce/consume shared meter |
| Temporary Grant G-A vs G-B | **G-A frozen** |
| Free wallet | **Out of phase** — per-app only |
| LOW_TIME optional in discovery | **Removed** as mandatory state |
| Grant vs ModeException | Separated — grant≠exception |
| Unlimited vs countable | Orthogonal axes frozen |
| SOS “unavailable in mode” misreading | **Voided** — SOS always available |
| CHD-020 / grant inert / wallet fixture | Remain **implementation gaps**, not open Owner questions |

---

## 3. Explicit law conflict (reported — not silently invented)

### ST-OD-011 vs Register S-5

| Source | Text |
|---|---|
| Register **S-5** | Focus self-discipline channel has **automatic reward**; `rewardSelfDiscipline` is **untouchable** |
| Owner **ST-OD-011** | **No automatic credit**; AI may suggest; **parent approval required** |

**Closure stance:** Owner freeze **ST-OD-011** is authoritative for the Screen Time / Minutes product contract.  
**Follow-up (documentation law only):** Register/ADR should be amended to replace “automatic reward” with “suggested reward requiring parent approval,” preserving the spirit that the self-discipline channel cannot be removed as a channel.

This is **not** an open product decision and **not** a reason to unfreeze the package.

### No conflict with SOS Final Contract

SOS forever-available under expiry/lock/subscription is reinforced, not weakened.

### No conflict with E-1 / Rule 11 / Ruling A–B

Minutes-only, exemptions, wallet-never-opens-blocks, overflow defaults — preserved.

---

## 4. Remaining platform constraints (not Owner product decisions)

| Constraint | Note |
|---|---|
| Android Usage Access / Device Owner / OEM variance | Feasibility for ENFORCING state |
| iOS FamilyControls / ManagedSettings / DeviceActivity entitlements | Honesty + capability matrix |
| Bounded grace numeric TTL for stale policy | Deferred technical/ops choice (ST-OD-009) |
| Travel timezone UX | Must be explicit+auditable when designed |
| Real multi-device shared-meter sync | Backend/device Stage-3 |
| Tamper resistance limits on BYOD | Signals ≠ guarantees |

---

## 5. What this freeze does **not** authorize

- Flutter / backend / OS implementation  
- Screen Engineering pack start  
- Changing `core/policy/` or app code  
- Starting System #3+  
- Weakening SOS  

---

## 6. Authority order after freeze

1. This `screen_time_final/` package (product freeze)  
2. Constitution + Policy Register (except S-5 automatic-credit clause flagged above)  
3. Frozen SOS final contract (safety supremacy)  
4. Discovery `screen_time/01–20` (evidence; superseded where conflict)  

---

## Confirmations

| Check | Result |
|---|---|
| Application code changed | **NO** |
| Other system started | **NO** |
| Product status | **FROZEN** |
