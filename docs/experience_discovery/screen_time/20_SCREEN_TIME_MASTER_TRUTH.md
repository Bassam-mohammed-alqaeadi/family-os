# 20 — Screen Time Master Truth

**Authoritative entry point for System #2 — Screen Time + Minutes Economy**  
**Discovery date:** 2026-09-23  
**Mode:** Experience / Product Engineering discovery **ONLY**  
**Application code modified:** **NO**  
**Other system started:** **NO** (SOS remains frozen/complete; this pack is Screen Time only)

**Label legend:** `CURRENT FACT` · `PROPOSED DESIGN` · `OWNER DECISION REQUIRED` · `PLATFORM CONSTRAINT` · `UNKNOWN` · `ALREADY DEFINED`

---

## Verdict

| Dimension | Verdict |
|---|---|
| **1. Screen Time maturity** | **B / F** — strong in-process policy UI + `TimeEngine` + sync bus; **no OS enforcement**; several parent/child surfaces cosmetic |
| **2. Minutes Economy maturity** | **B** — `Minutes` VO + `WalletLedger.earn` + education attribution path; **no consume**; request grants & child wallet **disconnected** |
| **Biggest honesty risk** | Remaining minutes / app rules / usage report / child request look real while metering & loops are Stage-1 mocks |
| **Non-negotiables** | Minutes-only · Instant lock top · Wallet ≠ unblock · Chat/Quran/SOS never time-locked · Mother ceilings · Father sovereignty |

---

## Doc index

| # | File | Purpose |
|---|---|---|
| 01 | [01_CURRENT_SCREEN_TIME_TRUTH.md](01_CURRENT_SCREEN_TIME_TRUTH.md) | Capability matrix A–H + journeys |
| 02 | [02_MINUTES_ECONOMY_CURRENT_TRUTH.md](02_MINUTES_ECONOMY_CURRENT_TRUTH.md) | Earn/spend/wallet current truth |
| 03 | [03_COMPETITIVE_SCREEN_TIME_ANALYSIS.md](03_COMPETITIVE_SCREEN_TIME_ANALYSIS.md) | Qustodio / Family Link / Apple / Bark |
| 04 | [04_SCREEN_TIME_POLICY_MODEL.md](04_SCREEN_TIME_POLICY_MODEL.md) | Policy objects |
| 05 | [05_TIME_PRECEDENCE_MODEL.md](05_TIME_PRECEDENCE_MODEL.md) | Current vs target ladder |
| 06 | [06_MINUTES_ECONOMY_POLICY.md](06_MINUTES_ECONOMY_POLICY.md) | Target economy contract |
| 07 | [07_PARENT_EXPERIENCE.md](07_PARENT_EXPERIENCE.md) | Father target UX |
| 08 | [08_MOTHER_EXPERIENCE.md](08_MOTHER_EXPERIENCE.md) | Observer / Partner / Full |
| 09 | [09_CHILD_EXPERIENCE.md](09_CHILD_EXPERIENCE.md) | Before / near / after expiry |
| 10 | [10_REQUEST_AND_EXCEPTION_MODEL.md](10_REQUEST_AND_EXCEPTION_MODEL.md) | Requests + grants |
| 11 | [11_STATE_MACHINE.md](11_STATE_MACHINE.md) | Five orthogonal machines |
| 12 | [12_OFFLINE_SYNC_MULTI_DEVICE.md](12_OFFLINE_SYNC_MULTI_DEVICE.md) | Sync semantics |
| 13 | [13_CROSS_SYSTEM_DEPENDENCIES.md](13_CROSS_SYSTEM_DEPENDENCIES.md) | Edges to other systems |
| 14 | [14_PLATFORM_ENFORCEMENT_REQUIREMENTS.md](14_PLATFORM_ENFORCEMENT_REQUIREMENTS.md) | Android / iOS requirements |
| 15 | [15_SCREEN_INVENTORY_AND_ENGINEERING.md](15_SCREEN_INVENTORY_AND_ENGINEERING.md) | Screen dispositions |
| 16 | [16_UX_INFORMATION_ARCHITECTURE.md](16_UX_INFORMATION_ARCHITECTURE.md) | IA placement |
| 17 | [17_SCREEN_TIME_EXPERIENCE_GAPS.md](17_SCREEN_TIME_EXPERIENCE_GAPS.md) | ST-GAP register |
| 18 | [18_SCREEN_TIME_OWNER_DECISIONS.md](18_SCREEN_TIME_OWNER_DECISIONS.md) | ST-OD decisions |
| 19 | [19_SCREEN_TIME_VALIDATION_MODEL.md](19_SCREEN_TIME_VALIDATION_MODEL.md) | Proof model |
| 20 | **This file** | Master entry |

---

## 3. Major domains / screens discovered

**Domains:** `n03_screen_time`, `core/policy` (TimeEngine, WalletLedger, PolicySyncBus, TimeRequest*), `n02_day` (inbox, child board), `n05_lock`, `n09_smart_modes`, `n04_web_filter` (adjacent), `n14_studio` attribution, `n17_child_learn` wallet UI, mother permissions.

**Core screens:** FAT-032, 033, 034, 035, 037, 038, 069, 085 · CHD-004, 019, 020, 021 (+ CHD-008/018 exempt/edu).

---

## 4. Confirmed capabilities (`CURRENT FACT`)

- Daily cap + overflow toggle + schedule windows (prefs) + PolicySyncBus mirror  
- `TimeEngine` precedence (lock → block → mode → cap → wallet)  
- `Minutes` + `WalletLedger.earn/deposit/balance`  
- Education attribution → earn  
- FAT-033 time request decide with mother ceiling + offline queue + child-visible reject reason  
- CHD-021 calm expiry with chat/Quran/SOS  
- Instant lock + smart mode flags in-process  
- Role actor gates for requests / lock  

---

## 5. Confirmed gaps

- No OS metering/consume  
- CHD-020 ⇄ FAT-033 disconnected  
- TimeGrant inert (no credit effect)  
- CHD-019 ≠ WalletLedger  
- FAT-034 ≠ TimeEngine  
- S-3 warning pipeline absent  
- Mother FULL FAT-032 edit absent  
- Schema economy tables absent  
- Multi-device / day rollover undefined in code  

---

## 6. Policy conflicts / ambiguities

- Doc 33 per-app limit step vs current TimeEngine (no per-app branch)  
- Temporary grant placement vs wallet/cap (Owner ST-OD-004)  
- Schedule hard-block vs grant (ST-OD-005)  
- Constitution `PolicyEngine.earn` name vs `WalletLedger.earn`  
- Unlimited/Always Allowed counting semantics (ST-OD-010)  
- Web filter vs time — separate (clear) but UX confusion risk  

---

## 7. Competitive lessons

- Separate Daily / Schedule / App limits / Bonus in IA  
- Bonus is same-day and explicit  
- Always Allowed counting policy must be visible  
- Multi-device must be stated (Family Link: per device)  
- Minutes earn-from-chores is Family OS differentiator — keep  

---

## 8. Platform requirements

Android: Usage Access, stronger Device Owner path for hard lock, reboot persistence, tamper signals.  
iOS: FamilyControls + ManagedSettings + DeviceActivity; honesty for weaker BYOD enforcement.  
Documented in [14](14_PLATFORM_ENFORCEMENT_REQUIREMENTS.md).

---

## 9. Owner decisions required

ST-OD-001…012 in [18](18_SCREEN_TIME_OWNER_DECISIONS.md) — prioritized: grant effect, multi-device, wallet expiry/shape, schedule bypass, request spam/timeout, timezone, stale fail mode, unlimited semantics, focus auto-reward, mother overflow edit.

---

## 10. Exact output path

`D:\special projects\family\docs\experience_discovery\screen_time\`

---

## 11–12. Confirmations

| Check | Status |
|---|---|
| **NO application code modified** | **Confirmed** — docs only under `docs/experience_discovery/screen_time/` |
| **NO `core/policy/` modified** | **Confirmed** |
| **NO `tokens.dart` modified** | **Confirmed** |
| **NO Flutter / backend / Android / iOS enforcement started** | **Confirmed** |
| **NO other system started** | **Confirmed** — System #2 discovery only; SOS untouched |

---

## Quality checklist coverage

Father · Mother Observer/Partner/Full · Child · Daily limits · Schedules · App/category · Unlimited/allowed · Minutes economy · Wallet/ledger · Earned · Temporary grants · Requests · Approvals · Warnings · Expiry · Smart Modes · Web Filter · Instant Lock · SOS · Notifications · Audit · Offline · Multi-device · Android · iOS · Screen inventory · UX IA · Competitive · Owner decisions — **covered across docs 01–19**.

---

## Next (out of scope for this stop)

Owner reviews ST-OD decisions → optional QUESTIONS.md halt if harness must block → then engineering cards for wiring fixes — **not started here**.

**STOP after Screen Time discovery.**
