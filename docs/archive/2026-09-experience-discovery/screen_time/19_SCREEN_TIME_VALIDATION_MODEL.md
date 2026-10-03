# 19 — Screen Time Validation Model

**Date:** 2026-09-23  
**Purpose:** How we will know System #2 is true — without claiming OS enforcement prematurely.

---

## Validation layers

| Layer | Proves | Method |
|---|---|---|
| L0 Domain | Minutes non-negative; PolicyEngine assignee rules | Unit tests (exist) |
| L1 Engine | TimeEngine ladder order | `time_engine_test` (exist) |
| L2 Persistence | Policy/schedules round-trip | Prefs/InMemory tests |
| L3 Sync | Parent save → child mirror remaining | `policy_sync_bus_test` / UI-005 |
| L4 Request loop | CHD-020 create → FAT-033 decide → child feedback → balance effect | **Missing end-to-end today** |
| L5 Economy | Attribution earn → CHD-019 reflects | Partial (earn test; wallet UI gap) |
| L6 Roles | Observer/Partner/Full matrices | Actor unit + widget role tests |
| L7 Exemptions | Expiry/lock keep chat/Quran/SOS | UI-011 / device lock tests |
| L8 Honesty | UI never claims OS enforce when simulated | Widget copy assertions + Policy Health |
| L9 Device | Real block/meter on Android/iOS | Stage-3 instrumented device lab |
| L10 Multi-device | Shared/per-device semantics | Stage-3 after ST-OD-001 |

---

## Acceptance scenarios (TARGET)

1. **Father sets cap 60 → child mirror shows 60−used.**  
2. **Child requests 15 → Partner approves 15 → remaining increases per ST-OD-004.**  
3. **Observer cannot approve.**  
4. **Mother grant 45 with ceiling 30 → rejected.**  
5. **Father grant 45 → allowed.**  
6. **Cap exhausted + overflow off + wallet 20 → deniedCap.**  
7. **Overflow on → allowed; consume wallet.**  
8. **Permanent block + wallet → still denied.**  
9. **Instant lock → deniedLock; SOS still open.**  
10. **Mode active without app → deniedMode unless exception.**  
11. **S-3 warning fires at 5 minutes remaining.**  
12. **CHD-021 offers chat/Quran/SOS/request.**  
13. **FAT-034 block persists into engine.**  
14. **Education attribution +10 YouTube → CHD-019 YouTube wallet +10.**  
15. **Offline approve queues → flush applies once (idempotent).**  

---

## Anti-goals for validation

- Green widget tests with fixture Minutes ≠ proof of economy.
- Passing analyze ≠ OS enforcement.
- GAP_LOG CLOSED ≠ Stage-3 complete (XD-008 lesson from SOS).

---

## Traceability template

Every major requirement test must cite:

`Requirement → Policy → Role → State → Screen → Event → Data → Device/Backend`

Example:

`Child request approved → ADR-039/UF-05 → Partner → REQUEST_APPROVED+TEMPORARY_GRANT → FAT-033/CHD-020 → time_request.approved → TimeGrant+ledger → future FCM+UsageStats`
