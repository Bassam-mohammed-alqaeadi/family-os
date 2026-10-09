# 02 — FS-005 L3 Role Matrix

**Authority:** MODE-OD-02 · MODE-OD-10 · MODE-OD-13 · MODE-OD-14 · MODE-SF-01…03  
**Master:** [13_FS005_L3_MASTER_CONTRACT.md](13_FS005_L3_MASTER_CONTRACT.md)

---

## 1. Action × role

| Action | Primary | Full | Partner | Observer | Child |
|---|---|---|---|---|---|
| Open Modes hub | ✓ | ✓ | ✓ | ✓ | ✗ (see status card only) |
| View catalog / active stack / honesty | ✓ | ✓ | ✓ | ✓ | Active disclosure only |
| Create built-in customization / custom Mode | ✓ | ✓ | ✗ | ✗ | ✗ |
| Edit identity / scope / overlays / schedule / grace | ✓ | ✓ | ✗ | ✗ | ✗ |
| Delete Mode | ✓ | ✓ | ✗ | ✗ | ✗ |
| Preview-before-apply | ✓ | ✓ | view preview if shared | view | ✗ |
| Manual activate / deactivate (config authority) | ✓ | ✓ | ✗* | ✗ | ✗ |
| Ticket-authorized activate / deactivate | ✓ | ✓ | ✓ if ticket grants | ✗ | ✗ |
| Author / revoke ModeException | ✓ | ✓ | ✗ | ✗ | ✗ |
| Decide ST Temporary Grant | ST AuthZ | ST AuthZ | ST AuthZ | — | request only |
| Decide FS-003 App Access Exception | FS-003 AuthZ | — | — | — | request |
| Edit geofences | FS-001 AuthZ | — | — | — | ✗ |
| Cancel Mode via grace | ✗ (parent deactivates Mode) | same | ✗ | ✗ | **✗** |
| Permanently disable Mode | ✓ / Full only via deactivate/delete | ✓ | ✗ | ✗ | **✗** |
| View audit | ✓ | ✓ | limited view | limited | ✗ |
| Approve AI Mode suggestion | ✓ | ✓ | ✗ | ✗ | ✗ |
| Reach SOS / Chat / Quran | always | always | always | always | **always** |

\* Partner default: **not** Mode policy editor (**MODE-OD-13**).

---

## 2. Surface visibility

| Surface | Primary | Full | Partner | Observer | Child |
|---|---|---|---|---|---|
| OVERVIEW | R/W | R/W | R | R | — |
| BUILDER | R/W | R/W | — | — | — |
| SCHEDULER | R/W | R/W | R | R | — |
| ACTIVE STACK | R/W | R/W | R | R | Card subset |
| EXCEPTIONS (ModeException) | R/W | R/W | R | R | — |
| DEVICES / ACK | R | R | R | R | — |
| AUDIT | R | R | R− | R− | — |
| Child Mode card | — | — | — | — | R |

---

## 3. Confirmation policy (who must confirm)

| Action | Confirm? | Who |
|---|---|---|
| Delete Mode | Yes | Primary / Full |
| Deactivate while others remain | Soft confirm if stack changes | Primary / Full |
| Activate with multi-mode stricter impact | Preview recommended | Primary / Full |
| Scope change all→selected or reverse | Explicit confirm; no silent expand | Primary / Full |
| ModeException | Confirm scope + that it is Mode-only | Primary / Full |
| Partner ticket activate | Ticket UI confirm | Partner (if granted) |

---

## 4. Forbidden for all roles (UX)

- Expose ScheduleWindow as Modes scheduler twin  
- Widen/loosen Vacation overlays  
- Edit URL lists / package stores / geofence geometry / ST wallets inside Modes  
- Gate SOS from Mode UI  
- Claim enforced from parent toggle alone  
