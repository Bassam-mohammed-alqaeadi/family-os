# 02 — FS-003 Capability Inventory

**Mode:** Evidence-only. Capabilities appear only if supported by repo evidence, or explicitly marked **Missing / Unknown**.  
**Do not** add parental-control “industry defaults” as if present.

Classification key:

| Tag | Meaning |
|---|---|
| **I** | Exists and implemented (in-app / in-process) |
| **P** | Exists but partial |
| **U** | UI/mock only |
| **R** | Referenced (docs/catalog/gap specs) but not implemented |
| **M** | Missing |
| **C** | Conflicts with stated Family OS docs/direction |
| **?** | Cannot be verified from repository |

**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## Matrix (minimum 38)

| # | Capability | Class | Evidence | Confidence |
|---|---|---|---|---|
| 1 | Installed application inventory | **U** | `child_apps_mock.dart` seeded slugs; empty-state copy aspirational (“when device reports installed apps”) | High |
| 2 | Per-child app policy | **P** | `AppAccessRuleSet(childId)` + prefs key `app_access_rules:{childId}`; `child_apps_repository.dart` | High |
| 3 | Family/shared app policy | **U/C** | UI copy “shared between father and mother”; storage is per-child only; no family-level rule set | High |
| 4 | Block application | **P/U** | FAT-034 block → `AppAccessRule.blocked` persisted; **no OS hide/block** | High |
| 5 | Allow application | **P/U** | Same path, `ChildAppStatus.allowed` | High |
| 6 | Temporary application exception | **M/R** | Flutter `TimeGrant` = entertainment **minutes** cap; prototype lock `tempException` ≠ per-app unlock | High |
| 7 | Application unlock/request flow | **M** | CHD-020 = minutes; WebUnlock = URLs; **no dedicated app-unlock inbox** | High |
| 8 | Parent approval/denial | **P** | FAT-035 (new app); FAT-033 (time minutes) | High |
| 9 | Scheduled app restrictions | **M/P** | `ScheduleWindow` affects global time context; **not** per-app schedules in rules | High |
| 10 | Mode-driven app restrictions | **P** | `TimeEngine.deniedMode`; SmartModes bus; mode allowed lists not fed from FAT-034 | High |
| 11 | System-app restrictions | **U/R** | Tools/edu “free” category in mock; no system-app policy entity | High |
| 12 | Browser vs app boundary | **R/C** | WF-OD-12 documented; separate codebases; no unified runtime evaluator | High |
| 13 | Package-ID based targeting | **M** | Slug `appId` strings only (`minecraft`, not `com.*`) | High |
| 14 | Launch interception | **M** | No Accessibility/overlay/activity intercept service | High |
| 15 | Foreground application detection | **M** | No UsageStats listener | High |
| 16 | Usage Access | **R** | `perm_key USAGE_STATS` in schema; device-health labels; no native grant/enforcement | High |
| 17 | Accessibility enforcement | **R** | Platform gates docs; zero Android AccessibilityService | High |
| 18 | Device Owner enforcement | **R** | Strategic docs (`18_PLATFORM_GATES.md`); no DevicePolicyManager code | High |
| 19 | Profile Owner enforcement | **R** | Same | High |
| 20 | Kiosk/lock-task mechanisms | **U** | In-app Child Mode Lock / Instant Lock; not `lockTaskMode` | High |
| 21 | Uninstall resistance | **U/R** | `AntiTamperPolicy` UI flags + prefs; no `setUninstallBlocked` | High |
| 22 | Force-stop resistance | **M** | No evidence | High |
| 23 | Settings bypass resistance | **U** | Anti-tamper toggles + honesty badges | High |
| 24 | Offline enforcement | **M** | App rules parent-local only; no child enforcement agent | High |
| 25 | Last-acknowledged policy | **M** (for app rules) | `ChildPolicyMirror.lastAppliedAt` exists for **screen time only** | High |
| 26 | Policy versioning | **M** (app rules) | Web/anti-tamper have `policyVersion`; `AppAccessRule` does not | High |
| 27 | Device acknowledgement | **U** | `PolicySyncStatus` in-process for ST; not for app rules | High |
| 28 | Multi-device synchronization | **M** | No FCM; app rules not on sync bus | High |
| 29 | Outbox/replay | **M** (app rules) | `PolicySyncBus` / `TimeRequestService` queues — not app rules | High |
| 30 | Notifications | **U** | Pending app CTA in FAT-034; no push pipeline | High |
| 31 | Audit/events | **M/P** | App mutations largely unaudited; lock/web have partial `AuditAppend` | Medium |
| 32 | Evidence | **U** | FAT-069 fixture usage; device_health UI | High |
| 33 | Degraded / unsupported honesty | **I/P** | `EnforcementStatusBadge` (“simulated, not MDM”); empty/observer states | High |
| 34 | SOS precedence | **I** | SOS CTAs on app screens; `TimeExpirySurface` exempts SOS | High |
| 35 | Interaction with Screen Time | **P/C** | `AppAccessRuleQuery` + tests; **features never call it**; older truth docs still say disconnected | High |
| 36 | Interaction with Web Filtering | **R** | Stricter intersection documented; no combined evaluator | High |
| 37 | Interaction with Modes | **P** | `TimeContext.modeActive`; FAT-085 bus; app lists not integrated | High |
| 38 | Wallet/Minutes independence | **P** | `TimeEngine`: blocked ignores wallet (Ruling A); wallets separate from FAT-034 `limitMins` | High |

---

## Rollup buckets

| Bucket | Items |
|---|---|
| **I** | SOS reachability on surfaces; honesty badge pattern; FAT-034/035 screens + child lean RoleGuard behavior; basic in-screen AuthZ gates |
| **P** | Per-child rule model + prefs; allow/block UI→rule persist; new-app approve; TimeEngine algebra (test-only wiring); mode flag; minutes requests adjacent |
| **U** | Mock inventory; usage report fixtures; anti-tamper / lock “resistance” UI; shared-policy copy |
| **R** | DO/PO/UsageStats/Accessibility in platform docs; WF∩AppControl stricter intersection; schema permission keys |
| **M** | Real inventory; package IDs; launch intercept; OS block; offline child enforcement; app-rule sync/version/ack/outbox; app unlock tickets; force-stop resistance |
| **C** | Mother Partner edit vs eng doc; “feeds TimeEngine” / “on child device” claims; family-shared vs per-child |

---

## Explicit non-additions

The following are **not** claimed as capabilities merely because they are common in parental-control products. They remain **M** or **?** unless evidence appears:

- Always-on MDM enrollment UX  
- Play Protect / Play Store install blocking APIs as product features  
- iOS Screen Time FamilyControls (schema enum only → not audited as implemented)  
- Per-app VPN kill-switch  

---

## Related docs

- [01_FS003_CURRENT_STATE.md](01_FS003_CURRENT_STATE.md)  
- [04_FS003_PLATFORM_ENFORCEMENT_AUDIT.md](04_FS003_PLATFORM_ENFORCEMENT_AUDIT.md)  
- [08_FS003_GAPS_AND_MOCKS.md](08_FS003_GAPS_AND_MOCKS.md)  
