# FS-010 — Durable Family Chat — Discovery Master

**Canonical ID:** `FS_010_Ephemeral_Family_Chat`  
**Date:** 2026-09-25  
**Phase:** 2 analysis only  

---

## 1. Sources

| Source | Role |
|--------|------|
| Owner Q-PHASE2-FS010-VS-SCOM050 (A) | Title interpretation |
| `family-os/07_DOMAIN_2_COMMUNICATION.md` § أ | Chat product law |
| Policy Register C-1, C-2, C-3 | Untouchable / E2E / edit+delete |
| Constitution R9 / Modes / AC exemptions | Chat never time/subscription gated |
| Registry S-COM-001…009; SCR-FAT-021/022; CHD-007/008 | Inventory |
| Phase 1.75 `DOM-COM-LOCAL` | Live COM deferred; Local drafts only if prioritized |
| Flutter InMemory chat repos | Stage-1 mock |

---

## 2. Mission

Provide **durable, accountable family messaging** (group, direct, subgroups) that remains reachable under time expiry and device lock, with visible E2E, WhatsApp-parity edit (15m) + delete-for-all, father-gated outer contacts model (Domain “walled garden”), without disappearing messages.

---

## 3. Current truth

| Layer | State |
|-------|--------|
| Product law | Domain 2 frozen + C-1…C-3 |
| Screens | Built Stage-1 mock |
| Local durable message store | **MISSING** (InMemory) |
| Sync / outbox for chat | NOT IMPLEMENTED (REM later) |
| LiveKit calls | Adjacent COM § ب — **out of FS-010 core** (calls separate) |
| S-COM-050 | Deleted |

---

## 4. Capability honesty

| Capability | State |
|------------|--------|
| UI list/thread | REAL LOCAL UI shell; data MOCK |
| Durable Local message journal | Target REAL LOCAL — missing |
| Relay / push delivery | MOCK-REMOTE / NOT CONFIGURED |
| E2E crypto | NOT IMPLEMENTED (C-2 requires visible E2E) |
| Disappearing messages | **UNSUPPORTED / FORBIDDEN** |

---

## 5. Discovery acceptance

```text
FS-010 DISCOVERY: COMPLETE (interpretation A)
S-COM-050: STILL DELETED
IMPLEMENTATION: NOT AUTHORIZED
```
