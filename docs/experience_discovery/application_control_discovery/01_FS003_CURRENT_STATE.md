# 01 — FS-003 Application & System Control · Current State

**System label:** FS-003 Application & System Control (discovery only)  
**Date:** 2026-09-23  
**Mode:** Read-only evidence audit — **no** redesign, **no** policy freeze, **no** app changes  
**Authority for CURRENT STATE:** repository + prior experience-discovery matrices + gap logs + frozen prototype  
**Authority for NEW TARGET:** **none yet** — explicitly out of scope  

**Entry:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. What “FS-003” means in this repo today

There is **no** folder or symbol named `FS-003`. The closest implemented cluster is:

| Cluster | Location |
|---|---|
| Feature UI | `app/lib/features/n03_screen_time/child_apps_*`, `new_app_approval_screen.dart` |
| Policy core | `app/lib/core/policy/app_access_rules.dart`, `app_access_rules_repository.dart` |
| Screens (registry) | `SCR-FAT-034` تطبيقات الابن · `SCR-FAT-035` موافقة تطبيق جديد |
| Services (catalog) | `S-SEC-008`…`S-SEC-013` |
| Adjacent (not FS-003 proper) | Screen Time minutes, Web Filter, Instant Lock / Anti-tamper, Smart Modes, Child Mode Lock |

**CURRENT STATE definition:** parent-facing **app inventory UI** (mock slugs) + **allow/block/unlimited axes** persisted to parent-process prefs as `AppAccessRule` + **new-install approval screen** + **unit-tested** `AppAccessRuleQuery` → `TimeEngine` algebra (**not wired into live feature evaluation paths**).

**Not present:** Device Owner / Profile Owner / Accessibility / Usage Access enforcement, PackageManager inventory, launch interception, package-ID targeting, app-rule sync on `PolicySyncBus`, schema tables for installed apps / app rules, dedicated app-unlock ticket flow.

---

## 2. CURRENT STATE vs NEW TARGET DESIGN

| | CURRENT STATE (this package) | NEW TARGET DESIGN |
|---|---|---|
| Status | Documented from evidence | **Not started** |
| Source | Code, tests, GAP_LOG, discovery matrices, catalogs, prototype JS | Future L2/L3 packages |
| Rule | Classify only | Do not invent here |

Existing Stage-1 screens are **evidence**, not the future UX authority. Do **not** infer the new Family OS target design from Stage-1 implementation.

---

## 3. Exact current FS-003 scope (evidence)

| Layer | Status |
|---|---|
| **Parent UI (FAT-034/035)** | Shipped Flutter screens with mock inventory, allow/block, new-app approval |
| **Policy domain** | `AppAccessRule`, `TimeEngine`, `TemporaryGrantQuery` exist; partial wiring |
| **Runtime enforcement** | **Absent** — bare `FlutterActivity`, no UsageStats/Accessibility/DO/PO |
| **Child device delivery** | App rules persist **parent-side prefs only**; not on `PolicySyncBus` |
| **Package identity** | Mock slugs (`minecraft`, `youtube`) — not Android package names |
| **FS-003 docs (prior)** | Referenced only in Web Filter cross-system docs; **no dedicated FS-003 pack before this folder** |

**Maturity:** Strong **parent UX + policy algebra** · Weak **engine wiring** · **Zero OS enforcement**

---

## 4. Screens in scope (CURRENT)

| Screen ID | Route | Widget | Role in FS-003 |
|---|---|---|---|
| **SCR-FAT-034** | `/scr-fat-034?childId=` | `ChildAppsScreen` | Per-child app inventory, allow/block, limits, pending CTA |
| **SCR-FAT-035** | `/scr-fat-035?childId=&appId=` | `NewAppApprovalScreen` | New-install approval card |

### Adjacent screens (evidence boundary — not claimed as FS-003 complete)

| Screen ID | Why adjacent |
|---|---|
| SCR-FAT-032 | Daily cap / schedules (minutes — Screen Time) |
| SCR-FAT-033 | Approve/deny **minutes** requests |
| SCR-FAT-037 / 038 | Instant lock / anti-tamper **UI** |
| SCR-FAT-069 | Usage report (fixture) |
| SCR-FAT-085 | Smart Modes (affects `TimeContext.modeActive`) |
| SCR-CHD-019 / 020 / 021 | Wallets / time request / time expiry |
| SCR-CHD-011 | In-app child mode lock (not lock-task) |

---

## 5. Distinctions (CURRENT STATE)

| Plane | What it controls today | Enforcement |
|---|---|---|
| **Screen Time (minutes)** | Daily cap, wallets, temporary grants, schedules | In-app mirror only (`PolicySyncBus`) |
| **App Control (allow/block)** | Per-app blocked/allowed/free/pending, limits, unlimited | **UI + prefs; no OS** |
| **Web Filter** | URL/category deny, unlock inbox | Evaluator in Dart; **no VPN/DO** |

**Documented law (not implemented in a combined evaluator):** Web Filter ∩ App Control = **stricter intersection** + source-of-deny (`WF-OD-12`).

---

## 6. Prototype surface (frozen HTML — evidence of intended ladder, not Flutter enforcement)

Source: `family-os/family_os_app.html`

| Function | Behavior |
|---|---|
| `openAppControlSheet(appId)` | Bottom sheet: status, allow/block, limit presets, free toggle |
| `setAppStatus` / `setAppLimit` | Mutates prototype `S.childApps[]` |
| `canUseApp(appId)` | Unified judge: block → device lock → app instant lock → mode → daily cap → per-app limit → wallet |
| `requestUnlockFromKid` / `grantUnlockExtension` | Instant-lock exception (minutes), not dedicated app unlock |
| `toggleAppInstantLock(appId)` | Per-app instant lock in prototype |

Audit note: `family-os/31A_SYSTEM_AUDIT_LOG.md` confirms control functions exist in prototype.

---

## 7. What this discovery does **not** decide

- Enforcement mechanism (DO / Accessibility / other)  
- Policy scope (family vs per-child vs category)  
- Scheduling ownership  
- Exception semantics  
- Role authority  
- System-app scope  

Those belong to **FS-003 L2 Policy** — **not started**.

---

## 8. Document index

| # | File |
|---|---|
| 01 | this file |
| 02 | [02_FS003_CAPABILITY_INVENTORY.md](02_FS003_CAPABILITY_INVENTORY.md) |
| 03 | [03_FS003_CODE_AND_DATA_MAP.md](03_FS003_CODE_AND_DATA_MAP.md) |
| 04 | [04_FS003_PLATFORM_ENFORCEMENT_AUDIT.md](04_FS003_PLATFORM_ENFORCEMENT_AUDIT.md) |
| 05 | [05_FS003_OFFLINE_SYNC_AUDIT.md](05_FS003_OFFLINE_SYNC_AUDIT.md) |
| 06 | [06_FS003_SECURITY_AND_AUTHZ_AUDIT.md](06_FS003_SECURITY_AND_AUTHZ_AUDIT.md) |
| 07 | [07_FS003_TEST_AND_VALIDATION_AUDIT.md](07_FS003_TEST_AND_VALIDATION_AUDIT.md) |
| 08 | [08_FS003_GAPS_AND_MOCKS.md](08_FS003_GAPS_AND_MOCKS.md) |
| 09 | [09_FS003_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md](09_FS003_DEPENDENCIES_AND_CROSS_SYSTEM_MAP.md) |
| 10 | [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md) |
