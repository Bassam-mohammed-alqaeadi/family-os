# 11 — FS-005 Discovery Closure Report

**Date:** 2026-09-24  
**System:** FS-005 — Special / Custom Modes  
**Result:** CURRENT STATE audited — **L2 not started** · **ownership model not silently frozen**

```
FS-005 DISCOVERY: COMPLETE
FS-005 L2 POLICY: NOT STARTED
FS-005 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```

**Package:** `docs/experience_discovery/modes_discovery/`

---

## 1. Exact current Modes scope found

Stage-1 has a **real but thin** Modes spine:

1. **Domain:** `BuiltInModeId`, `ModeGrace`, `ModeConflictResolver`, `GrantOnModeStart`  
2. **Prefs:** per-child `SmartModePrefs` / rows (active + school TOD) in memory store  
3. **Activation:** in-process `SmartModeActivationBus` → CHD-004 tint/label  
4. **UI:** FAT-085 toggles + school times; tombstone FAT-039 redirects here  
5. **Kernel:** `TimeEngine` P3 consumes `modeActive` / allow / exception **flags**  
6. **Competing producer:** FAT-032 `ScheduleWindow` → `ScheduleWindowQuery` also sets `modeActive`  
7. **Missing:** FamilyMode schema, allow-lists, exceptions store, clock/geofence auto-activate, AuthZ, audit, durable sync, OS enforcement, custom builder, web/camera overlays  

Sibling L2 packs **already name** FS-005 as schedule owner — this discovery **records** that hypothesis and the Stage-1 **duplication risk**, without adopting it as FS-005 L2 law.

---

## 2. Document index

| # | File |
|---|---|
| 01 | [01_FS005_SCOPE_AND_MISSION.md](01_FS005_SCOPE_AND_MISSION.md) |
| 02 | [02_FS005_CURRENT_REPO_EVIDENCE.md](02_FS005_CURRENT_REPO_EVIDENCE.md) |
| 03 | [03_FS005_CAPABILITY_INVENTORY.md](03_FS005_CAPABILITY_INVENTORY.md) |
| 04 | [04_FS005_MODE_POLICY_AND_AUTHZ_DISCOVERY.md](04_FS005_MODE_POLICY_AND_AUTHZ_DISCOVERY.md) |
| 05 | [05_FS005_SCHEDULING_DISCOVERY.md](05_FS005_SCHEDULING_DISCOVERY.md) |
| 06 | [06_FS005_ENFORCEMENT_AND_OVERRIDE_DISCOVERY.md](06_FS005_ENFORCEMENT_AND_OVERRIDE_DISCOVERY.md) |
| 07 | [07_FS005_OFFLINE_SYNC_AUDIT.md](07_FS005_OFFLINE_SYNC_AUDIT.md) |
| 08 | [08_FS005_EVENTS_AUDIT_NOTIFICATIONS.md](08_FS005_EVENTS_AUDIT_NOTIFICATIONS.md) |
| 09 | [09_FS005_CROSS_SYSTEM_DEPENDENCIES.md](09_FS005_CROSS_SYSTEM_DEPENDENCIES.md) |
| 10 | [10_FS005_GAP_AND_CONTRADICTION_REGISTER.md](10_FS005_GAP_AND_CONTRADICTION_REGISTER.md) |
| 11 | this file |

---

## 3. Capability count

**70** inventory rows (doc 03).

| Bucket (approx) | Count |
|---|---|
| IMPLEMENTED | 12 |
| PARTIAL | 18 |
| MOCK/SIMULATION | 8 |
| DOCUMENTED ONLY | 14 |
| MISSING | 14 |
| UNKNOWN | 4 |

OS Focus / MDM lifestyle enforcement **IMPLEMENTED:** **0**.

---

## 4. Scheduler count / locations

| Metric | Value |
|---|---|
| Primary mode-related (S1–S3) | **3** |
| Total schedule-like inventoried (S1–S10) | **10** |
| OS cron/WorkManager for Modes | **0** |

| ID | Location |
|---|---|
| S1 | `schedule_window*.dart`, FAT-032, `PolicySyncKind.schedule` |
| S2 | `smart_mode_prefs.dart`, FAT-085 |
| S3 | `smart_mode_activation_bus.dart` |
| S4–S10 | Focus, contacts, quiet hours, grants, SOS ladder, wipe, UI timers |

**Highest duplication risk:** S1 (ST windows → `modeActive`) vs expected FS-005 schedule ownership.

---

## 5. Major contradictions and gaps

| Item | Summary |
|---|---|
| MODE-C-01 | ST ScheduleWindow vs Modes ownership |
| MODE-C-02 | Single-active UI vs M-B multi conflict |
| MODE-C-03 | Tighten-only L2 vs prototype vacation loosen |
| MODE-C-04 | `exams` vs `famtime` catalog |
| MODE-GAP-01…03 | No clock auto-activate; no schema; no allow-lists |
| MODE-GAP-04 | No AuthZ on FAT-085 |
| MODE-GAP-12 | No OS enforcement |

---

## 6. Owner questions (OPEN)

**Q-MODE-01…14** — scope, AuthZ, catalog, custom, stacking, S1 vs Modes priority, tighten/loosen, scheduling ownership, activation channels, child visibility/grace, exceptions, overlay planes, Co-Parent split, SOS/chat/Quran copy.

Full text: [10_FS005_GAP_AND_CONTRADICTION_REGISTER.md](10_FS005_GAP_AND_CONTRADICTION_REGISTER.md) §D.

**Not appended to `QUESTIONS.md`** in this tick (would block harness); live in this package until Owner opens L2.

---

## 7. Technical questions (OPEN)

**T-MODE-01…10** — evaluator unity, platform wake, schema, outbox vs PolicySyncBus, ack TTL, grace channel, location fact handoff, Kernel fact typing, conflict notify, audit catalog.

**No mechanisms selected. No TTLs invented.**

---

## 8. Cross-check vs frozen systems

| System | Outcome |
|---|---|
| Policy Kernel | Consumes flags; typed mode facts later |
| Screen Time Final | Minutes separate; **S1 schedule→mode is the live conflict** |
| FS-002 | No mode→filter code; L2 expects Modes schedule + tighten |
| FS-003 | Mode flag partial; no second AC scheduler; allow-lists not from Modes |
| FS-004 | No camera facet |
| FS-001 | Geofence ownership not moved; S-SEC-059 unwired |
| SOS Final | Never gated by Mode |
| Offline / Audit / Notifications | Lean activation only; audit/notify **MISSING** |
| Identity | No Modes RBAC matrix yet |

---

## 9. Validation

| Check | Result |
|---|---|
| Evidence-only; no L2 freeze of ownership | **PASS** |
| No wireframes / app code / mechanism selection | **PASS** |
| All schedulers inventoried | **PASS** |
| Q-MODE / T-MODE open | **PASS** |
| Fake/sim labeled | **PASS** |
| Changes outside this package | **NONE** |

---

## 10. Recommended next phase

**FS-005 L2 Policy** — Owner answers **Q-MODE-01…14** first (especially **08** scheduling ownership and **07** tighten/loosen), then technical verification **T-MODE** without inventing product law.

---

## 11. Gate

```
FS-005 DISCOVERY: COMPLETE
FS-005 L2 POLICY: NOT STARTED
FS-005 L3: NOT STARTED
IMPLEMENTATION: NOT AUTHORIZED
```
