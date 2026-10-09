# 17 — Screen Time Experience Gaps

**Date:** 2026-09-23  
**Note:** Many SET/UI gaps in `GAP_LOG.md` are CLOSED for Stage-1 prefs — this register tracks **experience / product completeness** beyond that.

IDs: `ST-GAP-###`

---

## Critical loop gaps

| ID | Gap | Evidence | Impact |
|---|---|---|---|
| ST-GAP-001 | CHD-020 not calling `TimeRequestService.createRequest` | `child_time_request_repository.dart` local pending | Parent never sees child ask |
| ST-GAP-002 | Approve writes `TimeGrant` but no remaining/wallet effect | `time_request_service._applyApprove` | Closed-loop false |
| ST-GAP-003 | CHD-019 fixture ≠ `WalletLedger` | `child_wallet_repository.dart` | Child sees fake Minutes |
| ST-GAP-004 | FAT-034 inventory ≠ `ScreenTimePolicy` / `TimeEngine` | Mock `ChildAppEntry` | App rules cosmetic |
| ST-GAP-005 | No `consume` / metering | WalletLedger + mock `usedMinutesToday` | Remaining is fiction |
| ST-GAP-006 | S-3 5-minute warning pipeline missing | No warning service found | Child blindsided |
| ST-GAP-007 | Mother FULL cannot edit FAT-032 | `_canEdit` father-only | Law/UI mismatch |
| ST-GAP-008 | Time decide not append-only audit | Labels only | Trust gap |
| ST-GAP-009 | OS enforcement absent | No UsageStats/FamilyControls | XD-002 class |
| ST-GAP-010 | Multi-device semantics undefined | No code | Ambiguous product |
| ST-GAP-011 | Day rollover missing | No job | Cap never resets in app |
| ST-GAP-012 | Per-app daily limit not in TimeEngine | Doc 33 vs code | Precedence incomplete |
| ST-GAP-013 | Ruling C grant/mode dialog incomplete | Law without UI | Parent surprise |
| ST-GAP-014 | Temporary grant has no TTL field | `TimeGrant` model | Can’t expire grant |
| ST-GAP-015 | Constitution `PolicyEngine.earn` vs `WalletLedger.earn` | Naming | Agent/docs confusion |
| ST-GAP-016 | Registry “points” legacy copy | ADR-036 | Terminology debt |
| ST-GAP-017 | FAT-069 usage is fixture | Mock repo | Parent misled |
| ST-GAP-018 | Web filter unlock confused with time in UX risk | Separate systems | Need IA clarity |
| ST-GAP-019 | Offline queues exist but no durable cross-device | Buses in-process | Kill app = lose? (prefs vary) |
| ST-GAP-020 | Education earn may not show on child wallet | ST-GAP-003 | Motivation loop broken |

---

## Closed Stage-1 items (do not re-open as SET)

SET-001…003, 007…009, 016…019, 024 · UI-005, 006, 008, 011 — CLOSED in GAP_LOG for prefs/sync/expiry exempt — **still subject to ST-GAP platform/loop items above**.

---

## Severity rollup

| Severity | IDs |
|---|---|
| P0 loops | 001, 002, 003, 004, 005 |
| P1 law/UX | 006, 007, 012, 013 |
| P2 trust/platform | 008, 009, 010, 011, 014, 017 |
| P3 hygiene | 015, 016, 018, 019, 020 |

See: [18_SCREEN_TIME_OWNER_DECISIONS.md](18_SCREEN_TIME_OWNER_DECISIONS.md).
