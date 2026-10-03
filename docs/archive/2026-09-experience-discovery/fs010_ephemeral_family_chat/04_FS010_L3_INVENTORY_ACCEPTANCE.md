# FS-010 — L3 / UI / Inventory / Acceptance

**Canonical ID:** `FS_010_Ephemeral_Family_Chat`  
**Date:** 2026-09-25  

---

## 1. Entities (target)

`ChatThread` · `ChatMessage` · `ChatMembership` · `ChatEditWindow` · `ChatDeliveryStatus` · `ChatLockState`

No `EphemeralTtl` / `DisappearAt` fields.

## 2. Repository boundaries

```
FamilyChatRepository (FS-010)
  ├─ LocalMessageStore (durable) — MISSING today
  ├─ OutboxPort (ephemeral relay enqueue) — Phase 1.75 pattern reusable
  ├─ IdentityPort
  ├─ NotificationRequestPort
  └─ AuditAppendPort (optional CHAT-C2)
```

## 3. UI / journey impact (KEEP hosts — no redesign)

| Screen | Journey | Notes |
|--------|---------|-------|
| SCR-FAT-021 list | JRN-FAT-11 · JRN-MOT-04 | Pinned threads |
| SCR-FAT-022 thread | same | Edit 15m + delete-for-all |
| SCR-CHD-007 list | JRN-CHD-04 | Never locked |
| SCR-CHD-008 thread | JRN-CHD-04 | Same |

Required future states: empty, offline, sync-pending, encrypted badge, send-failed — honesty, not new chrome redesign.

**Forbidden UX:** disappear timers, “view once”, auto-wipe banners.

## 4. Native / Remote

| Plane | Boundary |
|-------|----------|
| Text chat Local | REAL LOCAL target |
| Push / relay | REMOTE later |
| E2E crypto | Device crypto / REMOTErelay — not NAT OS enforcement |
| Calls | Separate; LiveKit = REMOTE media |

## 5. Traceability

```
FS-010 (durable Family Chat; ephemeral transport semantic)
  → System: COM أ المحادثات
  → Services: S-COM-001…009 (not 050)
  → Journeys: JRN-FAT-11, JRN-MOT-04, JRN-CHD-04
  → Screens: SCR-FAT-021/022, SCR-CHD-007/008
  → Policies: C-1, C-2, C-3 · Domain 2 § أ
```

## 6. Acceptance

```text
FS-010 ANALYSIS UNIT: ACCEPTED FOR PHASE 2
INTERPRETATION: A (durable product / ephemeral transport)
S-COM-050: REMAINS DELETED
NEXT: Cross-FS reconciliation
```
