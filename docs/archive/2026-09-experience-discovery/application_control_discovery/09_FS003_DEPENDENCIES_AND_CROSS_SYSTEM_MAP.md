# 09 — FS-003 Dependencies and Cross-System Map

**Mode:** Map adjacency only. Do not merge systems or invent precedence beyond documented evidence.  
**Master:** [10_FS003_DISCOVERY_MASTER.md](10_FS003_DISCOVERY_MASTER.md)

---

## 1. System diagram (CURRENT)

```
Screen Time (minutes / caps / grants / wallets)
    ↕ TimeEngine algebra (partial; app rules test-only)
App Control FAT-034/035 (allow/block + axes) ──X──► OS
    ↕ WF-OD-12 (docs only)
Web Filter (URL / categories)
Modes (modeActive flag)
Instant Lock / Anti-tamper (in-app)
SOS (always reachable on surfaces)
Wallet / Minutes (Ruling A: block ≠ wallet open)
```

---

## 2. Dependency table

| Other system | Relationship to FS-003 | Evidence | Coupled now? |
|---|---|---|---|
| **Screen Time** | Shared `TimeEngine` / `TimeContext`; FAT-034 axes intended to feed permanentlyBlocked / limits / unlimited | `app_access_rules.dart`, ST eng docs | **Partial** — persist yes; feature apply **no** |
| **Web Filtering (FS-002)** | Documented **stricter intersection** + source-of-deny (WF-OD-12) | Web Filter L2/L3 docs | **Docs only** |
| **Modes / Smart Modes** | `modeActive` / `appAllowedInMode` in TimeEngine | FAT-085, time_engine | **Partial** — flag exists; app lists not fed from FAT-034 |
| **Instant Lock** | Higher precedence in TimeEngine / prototype `canUseApp` | n05_lock, time_engine | Adjacent in-app |
| **Anti-tamper** | Uninstall/settings resistance **UI** | anti_tamper_* | Adjacent; not OS |
| **SOS** | Must remain reachable; time expiry never locks SOS | Screens, TimeExpirySurface | **Yes** (precedence I on surfaces) |
| **Wallet / Minutes** | Ruling A: balance never opens blocked apps | Policy Register + TimeEngine | Algebra exists; runtime merge incomplete |
| **Identity / ChildId** | Per-child rule sets keyed by ChildId | AppAccessRuleSet | **Yes** |
| **Policy sync** | Bus could carry app rules later; today ST only | policy_sync_bus.dart | **Not coupled** |
| **Audit** | Expected for mutations; thin today | AuditAppend elsewhere | **Weak** |
| **Education / Quran free apps** | Edu IDs forced non-countable | EducationAppIds | Partial via models |

---

## 3. Browser vs app boundary (evidence)

- Web unlock is **URL/host**-scoped (`WebUnlockService`).  
- App control uses **slug appId**.  
- Prototype treats YouTube **app** separately from browser URLs.  
- Future L2/L3 must not silently let a Web Filter temporary allow override App Control deny (WF-OD-12) — **not implemented**.

---

## 4. Interaction with Screen Time (detail)

| Axis | Screen Time owner? | App Control owner? | CURRENT |
|---|---|---|---|
| Daily entertainment cap | ST | — | ST |
| Temporary grant (minutes) | ST | — | ST |
| Per-app wallet | ST | — | ST |
| Permanent block | — | App Control | FAT-034 → prefs; not live-evaluated in features |
| Unlimited (bypass cap only) | Shared intent (ST-OD-010) | FAT-034 toggle | Persisted; feature apply incomplete |
| Per-app daily limit | Ambiguous / shared intent | FAT-034 `limitMins` | Mock + rule field; not OS |

**Do not freeze ownership here — L2.**

---

## 5. Precedence evidence (CURRENT algebra)

`TimeEngine` ladder (when inputs supplied): instant lock → permanently blocked → mode → daily/cap → wallet rules.

Prototype `canUseApp` is richer (includes per-app instant lock). Flutter `instantLocked` on `ChildAppEntry` is **not wired** as a toggle.

---

## 6. External platform dependencies (referenced)

| Dependency | In code? |
|---|---|
| Android Device Owner provisioning | **No** |
| AccessibilityService (Play policy risk documented) | **No** |
| UsageStats special access | **No** |
| FCM / multi-device push | **No** for app rules |
| Backend app_rule API | **No** |

---

## 7. Contradictions touching cross-system claims

| Topic | Docs / UI | Code |
|---|---|---|
| FAT-034 → TimeEngine | Older ST truth: disconnected | Query+repo exist; **features don’t call** |
| Reflects on child | Tip/copy | No bus entry for app rules |
| Stricter ∩ Web Filter | WF-OD-12 frozen in FS-002 L2 | No combined evaluator |
| Shared family app policy | UI note | Per-child store |

---

## 8. L2 boundary reminder

Choosing how App Control intersects Screen Time, Web Filter, Modes, and SOS honesty is **Owner/Product L2** — not this package.
