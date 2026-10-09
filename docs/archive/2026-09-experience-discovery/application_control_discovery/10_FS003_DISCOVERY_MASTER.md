# 10 — FS-003 Discovery Master

# FS-003 APPLICATION & SYSTEM CONTROL — DISCOVERY COMPLETE (EVIDENCE ONLY)

**Date:** 2026-09-23  
**Status:** CURRENT STATE audited — **NEW TARGET DESIGN not started**  
**App code modified:** **NO**  
**Screens / wireframes / policy freezes:** **NO**

**Package:** `docs/experience_discovery/application_control_discovery/`

---

## 1. Exact current FS-003 scope found

In-repository “Application & System Control” = **Flutter parent UX + in-process domain**, not OS enforcement:

1. Parent manages mock inventory and allow/block/unlimited axes on **SCR-FAT-034**.  
2. Pending mock installs decide on **SCR-FAT-035**.  
3. Mutations persist `AppAccessRule` axes to parent-process prefs (`app_access_rules:{childId}`).  
4. `AppAccessRuleQuery` can map rules into `TimeContext` for `TimeEngine` — **unit tests only**; features do not call it.  
5. **No** Device Owner / Profile Owner / Accessibility / Usage Access / PackageManager enforcement.  
6. **No** `schema.sql` app_rule / installed_app tables; app rules **not** on `PolicySyncBus`.

There is **no** prior dedicated FS-003 discovery folder before this package (only cross-references from Web Filter / Screen Time docs).

---

## 2. Document index

| # | File |
|---|---|
| 01 | [01_FS003_CURRENT_STATE.md](01_FS003_CURRENT_STATE.md) |
| 02 | [02_FS003_CAPABILITY_INVENTORY.md](02_FS003_CAPABILITY_INVENTORY.md) |
| 03 | [03_FS003_CODE_AND_DATA_MAP.md](03_FS003_CODE_AND_DATA_MAP.md) |
| 04 | [04_FS003_PLATFORM_ENFORCEMENT_AUDIT.md](04_FS003_PLATFORM_ENFORCEMENT_AUDIT.md) |
| 05 | [05_FS003_OFFLINE_SYNC_AUDIT.md](05_FS003_OFFLINE_SYNC_AUDIT.md) |
| 06 | [06_FS003_SECURITY_AND_AUTHZ_AUDIT.md](06_FS003_SECURITY_AND_AUTHZ_AUDIT.md) |
| 07 | [07_FS003_TEST_AND_VALIDATION_AUDIT.md](07_FS003_TEST_AND_VALIDATION_AUDIT.md) |
| 08 | [08_FS003_GAPS_AND_MOCKS.md](08_FS003_GAPS_AND_MOCKS.md) |
| 09 | [09_FS003_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md](09_FS003_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md) |
| 10 | this file |

---

## 3. Implemented capabilities (in-app)

- FAT-034 / FAT-035 screens with RoleGuard lean + observer variants  
- Allow / block / unlimited UI mutations against repository seam  
- Per-child `AppAccessRule` persistence (parent process)  
- SOS CTAs / precedence on app-control surfaces  
- Honesty badge pattern (`EnforcementStatusBadge` — simulated, not MDM)  
- In-screen AuthZ: Father + Mother Partner/Full mutate; Observer read-only  
- Widget/unit tests for those UI loops + rule→TimeEngine algebra

---

## 4. Partial capabilities

- Per-child policy model without live feature evaluation path  
- New-app approve/deny on **mock** pending rows (no install pipeline)  
- Mode flag in TimeEngine without FAT-034 allow-lists  
- Schedules affecting global time context (not per-app schedule rules)  
- Wallet independence algebra (Ruling A) without OS block  
- Screen Time adjacency (minutes grants/requests — not app unlock)  
- Anti-tamper / lock UI as resistance theater  

---

## 5. UI / mock-only capabilities

- Installed-app inventory (seeded slugs)  
- Category headers (display buckets)  
- Usage report fixtures (adjacent FAT-069)  
- Shared family allow/block copy  
- Device acknowledgement / sync status for **other** planes (ST simulation)  
- Uninstall / settings “resistance” toggles without native hooks  

---

## 6. Referenced-but-missing capabilities

- Device Owner / Profile Owner / Accessibility / Usage Access enforcement (platform gates docs + schema perm keys)  
- WF-OD-12 App Control ∩ Web Filter stricter intersection evaluator  
- Registry S-SEC-008…013 depth beyond Stage-1 UI  
- Prototype `toggleAppInstantLock` / richer `canUseApp` ladder parity  

---

## 7. Missing capabilities

- Real device inventory / package-ID targeting  
- Launch interception / foreground detection  
- OS package hide/block  
- Temporary **application** exception tickets (distinct from minutes grants)  
- App unlock request inbox  
- Force-stop resistance  
- Offline child enforcement of app rules  
- App-rule policy versioning, ack, outbox, multi-device sync  
- Backend/Drift app_rule schema  
- Rich audit/event/evidence packs for app mutations  

---

## 8. Real enforcement mechanisms

**None at OS layer.**

In-process only: UI state, prefs persistence, and **test-invoked** TimeEngine algebra.

Android proof: bare `MainActivity : FlutterActivity()`; manifest has no enforcement services/permissions for app control.

---

## 9. Offline reality

Prefs may persist on the parent process.  
**No** verified child-device offline enforcement agent for app rules.  
**No** app-rule outbox/replay.  
Screen-time offline queue is **adjacent** and **does not** carry app rules.

---

## 10. AuthZ reality

| Topic | Reality |
|---|---|
| FAT-034/035 mutate | Father + Mother Partner/Full |
| Observer | Read-only |
| Child | Lean + SOS |
| Conflicts | Partner edit vs eng doc; father-only permanent-block reopen not gated; P-3 vs UI; shared copy vs per-child store |
| Target law | **Not adopted** — L2 later |

---

## 11. Test reality

Strong Flutter coverage for SET/UI Stage-1 FAT-034/035 **in-app**.  
**Zero** OS/DO/Accessibility/UsageStats/package-block integration proof.

---

## 12. Cross-system dependencies

- **Screen Time:** shared TimeEngine intent; incomplete runtime merge  
- **Web Filter:** stricter intersection documented only  
- **Modes / Instant Lock / Anti-tamper:** adjacent in-app  
- **SOS:** must remain reachable  
- **Wallet:** block never opened by balance (algebra)  

---

## 13. Contradictions (record only)

1. Docs: FAT-034 “not feeding TimeEngine” vs code: query+persist exist — **features still don’t call query**.  
2. UI “reflects on child device” vs no sync bus entry for app rules.  
3. Platform gates assume UsageStats/DO/Accessibility — absent in Android tree.  
4. Registry category/new-install services vs display-only category headers + mock pending.  
5. GAP_LOG silent on FAT-034 enforcement while product incomplete.  
6. Mother Partner authority: engineering vs code.  
7. Prototype instant-lock-per-app richer than Flutter wiring.  

---

## 14. Unknowns requiring future Owner / technical decisions

- Package-ID registry / mapping  
- Install detection → FAT-035 pipeline  
- App-specific unlock product intent  
- Category-level policy entity  
- Enforcement mechanism choice  
- Role authority for permanent blocks  
- System-app scope  
- Backend tables beyond Wave-1  

**Do not choose these in discovery.**

---

## 15. Recommended next phase

**FS-003 L2 Policy** — Owner/Product decisions only (mechanism, scope, schedules, exceptions, roles, system apps).  

**IMPLEMENTATION: NOT AUTHORIZED**

---

## 16. Capability class rollup (matches doc 02)

| Class | Meaning in this package |
|---|---|
| **I** | SOS surfaces; honesty badge; FAT-034/035 + tests; in-screen AuthZ gates |
| **P** | Rule model + prefs; approve UI; algebra test-only; mode flag; ST adjacency |
| **U** | Mock inventory; resistance UI; shared-policy copy; fixtures |
| **R** | DO/PO/UsageStats/Accessibility docs; WF intersection contract |
| **M** | OS control; package IDs; sync/ack/outbox for app rules; app unlock tickets |
| **C** | AuthZ/docs/copy vs code delivery contradictions |

---

DISCOVERY STATUS: COMPLETE  
L2 POLICY: NOT STARTED  
IMPLEMENTATION: NOT AUTHORIZED  
