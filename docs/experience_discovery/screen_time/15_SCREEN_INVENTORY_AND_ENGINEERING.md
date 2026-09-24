# 15 — Screen Inventory and Engineering

**Date:** 2026-09-23  
**Disposition:** KEEP · EXTEND · MODIFY · SPLIT · REPLACE · PLACEHOLDER / WIRING FIX  
**No implementation in this phase.**

---

## Inventory

| Screen ID | Route | Widget | Repository / service | Logic today | States | Actions | Role access | Child impact | Dependencies | Gap | Disposition |
|---|---|---|---|---|---|---|---|---|---|---|---|
| FAT-032 | `/scr-fat-032` | `ChildScreenTimeScreen` | Prefs policy + schedules + sync | Cap/schedules/overflow | loading/edit/sync | save, toggle | Father edit; others view? | Mirror remaining | TimeEngine inputs | Mother FULL edit missing | **EXTEND** |
| FAT-033 | `/scr-fat-033` | `RequestInboxScreen` | `TimeRequestService` | Approve/reject/ceiling | pending list | decide | Partner+ | Grant inert | ADR-039 | No ledger credit | **EXTEND** |
| FAT-034 | `/scr-fat-034` | `ChildAppsScreen` | Mock apps repo | Display statuses/limits | fixture | local toggles? | Parent | None real | Should → TimeEngine | Disconnected | **WIRING FIX** → **EXTEND** |
| FAT-035 | `/scr-fat-035` | `NewAppApprovalScreen` | Mock | Approve install UX | fixture | approve/deny | Parent | None | Device install events | No OS hook | **EXTEND** later |
| FAT-036 | `/scr-fat-036` | Web filter | Web filter repos | Filter policy | — | unlock loop | Parent | Browse deny | Orthogonal | Don’t merge into Minutes | **KEEP** (adjacent) |
| FAT-037 | `/scr-fat-037` | `InstantLockScreen` | `DeviceLockService` | Lock kinds | locked/unlocked | lock/unlock | Father + Mother Full | Deny entertainment | Top precedence | OS lock missing | **EXTEND** |
| FAT-038 | `/scr-fat-038` | Anti-tamper | honesty | List signals | — | view | Father only | — | Device sensors | Simulated | **KEEP**/honesty |
| FAT-045 | studio | Attribution | WalletLedger | Earn minutes | — | assign | Father | Wallet credit | Education | CHD-019 not reflecting | **KEEP** + wire child |
| FAT-069 | `/scr-fat-069` | `ChildUsageReportScreen` | Fixture | Charts | fixture | view | Parent | None | Metering | Fake data | **REPLACE** data seam |
| FAT-085 | `/scr-fat-085` | `SmartModesScreen` | Activation bus | Mode flags | active | activate | Parent | Board tint | TimeContext | OS Focus H | **EXTEND** |
| FAT-031 | mother level | Mother permissions | MotherLevel | Sets ceiling context | — | set level | Father | Indirect | ADR-039 | — | **KEEP** |
| CHD-004 | day board | `ChildDayBoardScreen` | PolicySyncBus | Remaining | live | navigate | Child | Sees remaining | Sync | Warning H | **EXTEND** |
| CHD-019 | `/scr-chd-019` | `ChildWalletScreen` | Fixture wallet | Display | fixture | view | Child | Misleading | WalletLedger | Disconnected | **WIRING FIX** |
| CHD-020 | `/scr-chd-020` | `ChildTimeRequestScreen` | Local snapshot | Submit local | pending local | submit | Child | No parent notify | Must → TimeRequestService | Disconnected | **WIRING FIX** |
| CHD-021 | `/scr-chd-021` | `TimeExpiryScreen` | TimeExpirySurface | Calm expiry | expired | request/SOS/chat/Quran | Child | Correct exempt | Rule 11 | Wire request | **EXTEND** |
| CHD-008 | chat | Chat | ChatAvailability | Never lock | — | chat | Child | Exempt | C-1 | — | **KEEP** |
| CHD-018 | focus | Focus | edu free | Focus mode | — | focus | Child | Non-countable | S-5 | — | **KEEP**/align |
| Mirror host | n/a | `ChildScreenTimeMirror` | Sync bus | P12 proof | — | — | test | — | — | Not registry screen | **KEEP** as proof |

FAT-039 tombstone → FAT-085 (**REPLACE** already done).

---

## Engineering priorities (discovery order, not ship order)

1. **WIRING FIX** CHD-020 ↔ FAT-033  
2. **WIRING FIX** approve → TemporaryGrant/wallet effect  
3. **WIRING FIX** CHD-019 ↔ WalletLedger  
4. **WIRING FIX** FAT-034 → policy/TimeEngine  
5. **EXTEND** S-3 warning pipeline  
6. **EXTEND** Mother FULL edit on FAT-032  
7. Platform agents (Stage-3) per doc 14  

See: [16_UX_INFORMATION_ARCHITECTURE.md](16_UX_INFORMATION_ARCHITECTURE.md).
