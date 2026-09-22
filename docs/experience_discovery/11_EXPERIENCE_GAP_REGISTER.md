# 11 — Experience Gap Register (Family OS)

**Date:** 2026-09-23  
**Rule:** Evidence-first. Separates **in-app mock gaps** from **real-world product gaps**.

IDs are discovery IDs (XD-*); not harness card IDs.

---

## Critical (real-world)

| ID | Gap | Type | Evidence | Roles hit |
|---|---|---|---|---|
| XD-001 | No runtime backend / auth / multi-device sync | Capability missing | pubspec; no server; empty API_CONTRACT | All |
| XD-002 | No OS enforcement (screen time, web, lock) | Screen exists, capability incomplete | Bare `MainActivity.kt`; no VPN/Usage/Accessibility code | Parent→Child |
| XD-003 | No GPS / maps / LiveKit / FCM dependencies | UI without capability | pubspec deps | Location, calls, push |
| XD-004 | Persistence is process memory only | Settings appear real but die on kill | Memory Prefs stores; no SharedPreferences pkg | All |
| XD-005 | SOS cannot actually call/SMS/stream location | Safety UI incomplete for real emergency | MockSosFire | All |

---

## High (product honesty / wiring)

| ID | Gap | Type | Evidence | Roles hit |
|---|---|---|---|---|
| XD-006 | **43 routes still PlaceholderScreen** while many screens exist | Disconnected / misleading | `router.dart` vs `n17_child_learn/*` | Child, Parent education/AI |
| XD-007 | Education child submit ↛ FAT-050; materials toast-only | Unclosed loop | `GAP_LOG.md` P15-EDU-006/007 **OPEN** | Parent, Child |
| XD-008 | GAP_LOG “CLOSED” SET/UI items ≠ real-device complete | Misleading if read as production done | GAP_LOG + mock policy | Architects |
| XD-009 | Transparency / monitoring UI describes collection not implemented | Settings without collectors | Privacy screens + no sensors | Child, Parent |
| XD-010 | Chat never locks (policy) but chat isn’t real messaging | Incomplete experience | ChatAvailability + mock store | All |

---

## Medium (role / journey)

| ID | Gap | Type | Evidence | Roles hit |
|---|---|---|---|---|
| XD-011 | Mother experience mostly shared father UI + few hard gates | Co-parent incomplete | Small fatherOnly set | Mother |
| XD-012 | Invite/accept mother has no server membership | Dead-end persistence | Mock invite screens | Mother, Father |
| XD-013 | Device health “repair” is Fake seam | Fake round-trip | `device_health_seam.dart` | Father |
| XD-014 | Billing looks like plans but MockEntitlement | Prototype billing | `n11_billing` | Father |
| XD-015 | Advisor looks intelligent but MockAdvisor + flags | Prototype AI | `advisor_repository.dart` | Father, Mother |
| XD-016 | Constitution aspirational stack (Riverpod/freezed) ≠ code | Inconsistency | pubspec vs constitution text | Engineers |
| XD-017 | Registry CSV still mentions نقاط in places; Rule 4 forbids points/XP | Terminology inconsistency | screens.csv CHD-012/019 notes | Child |
| XD-018 | StatefulShellRoute deferred — navigation chrome vs deep history | Navigation partial | `family_shell.dart` comment | All |

---

## Patterns observed

1. **Screen without capability** — location, calls, filter, lock.  
2. **Capability without route** — screen dart files behind placeholders.  
3. **Setting without durable effect** — memory prefs.  
4. **Parent action without child device effect** — buses only.  
5. **Closed gap log ≠ production** — mock loop closure.  
6. **Duplicate surfaces** — multiple advisor/education entry points (hub, brain, my advisor, coming soon) overlapping mock content.

---

## Linked open harness gap (FACT)

- `GAP_LOG.md`: Phase 1.5 Education **P15-EDU-006…007 OPEN** (as of 2026-09-22 note).

---

## Not gaps (intentional Stage-1)

- Mock family names confined to `mock/` (Rule 13/23).  
- AI suggest-only (no execute) — structural.  
- SOS never subscription-gated — structural and tested.
