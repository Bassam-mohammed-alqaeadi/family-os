# FS-008 — One-Way Audio — L3 / UX & Contracts

**Canonical ID:** `FS_008_One_Way_Audio`  
**Date:** 2026-09-25  
**Status:** L3 BEHAVIORAL DRAFT from Domain 1 — **no screens yet in registry**  
**Implementation:** NOT AUTHORIZED  

---

## 1. Entities / value objects (target)

| Type | Fields (conceptual) |
|------|---------------------|
| `AmbientListenPolicy` | enabledMarket, fatherAckAt, childAck13Plus |
| `AmbientListenSession` | id, childId, actorFatherId, reason, reasonText?, startedAt, endedAt, durationSec, phase, geoMarket |
| `AmbientListenBlobRef` | sessionId, sealedUri, expiresAt, purgeAt |
| `AmbientListenReason` | distressReport · childUnreachable · unfamiliarLocation · suspectedDanger · other |

## 2. Repository / service boundaries

```
AmbientListenService (FS-008)
  ├─ PolicyRepository (Local)
  ├─ SessionRepository (Local append + purge)
  ├─ NativeMicPort (NOT IMPLEMENTED)
  ├─ SealPort / E2E (REMOTE later)
  ├─ NotificationPort (mother/child)
  └─ AuditAppendPort (append-only)
```

No writes into FS-004 SC stores or FS-006 evidence audio tables.

## 3. Decision flows (father)

1. Open One-Way Audio (future host — **screen ID TBD**).  
2. Legal warning if first enable.  
3. Select child → re-auth → pick reason → Confirm.  
4. Device shows recording ≤60s with visible indicator.  
5. End → child notify + mother notify + audit.  
6. Father listens in-app only.  
7. Auto-purge at 7 days.

## 4. Role matrix

| Role | Can start | Can listen | Can delete audit | Notes |
|------|-----------|------------|------------------|-------|
| Father (Primary) | Yes | Yes | No | Only starter |
| Mother Full/Partner/Observer | No start | No (Domain) | No | Mother **notified** only |
| Child | No | Own history metadata; not raw abuse path | No | Post-notify + log |

## 5. Failure behavior

| Failure | UX honesty |
|---------|------------|
| Geo market OFF | Unsupported / unavailable |
| Quota / cooldown | Blocked with next-allowed time |
| In call | Auto deny / stop |
| Native mic missing | NOT IMPLEMENTED |
| Auth fail | Deny |

## 6. UI / journey impact

| Impact | Status |
|--------|--------|
| New father control surface | Required — **no SCR today** |
| Child history / transparency | Required — CHD surface TBD |
| Settings legal ack | Required |
| Deep link from Day Board / SOS worry | Optional — must not imply SOS audio evidence |
| Registry journeys | **None** — create when Owner commissions ScreenBuild |

**Do not redesign existing FS-004/006 screens to host ambient mic.**

## 7. Native / Remote boundary

| Plane | Boundary |
|-------|----------|
| Android mic + foreground disclosure | NAT-* (future) |
| iOS | OPEN AUD-C6 |
| E2E transport / cloud seal | REM-* (future) |
| Local session + audit | Phase 1.75 foundations reusable |

## 8. Testability (future)

- Unit: quota, cooldown, reason required, role deny.  
- Widget: honesty NOT IMPLEMENTED when Native absent.  
- Never fake successful capture in tests as production capability.

## 9. L3 acceptance

```text
FS-008 L3: DRAFT COMPLETE (behavioral; no SCR IDs yet)
SCREENBUILD: NOT COMMISSIONED
IMPLEMENTATION: NOT AUTHORIZED
```
