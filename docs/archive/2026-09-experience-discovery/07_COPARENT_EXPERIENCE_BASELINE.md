# 07 — Co-Parent / Mother Experience Baseline (Family OS)

**Role in code:** `AppRole.mother`  
**Permission model:** `MotherLevel` = observer | partner | full (`core/domain/mother_level.dart`)  
**Date:** 2026-09-23  

---

## How mother enters (FACT)

1. Father invites via `InviteMotherScreen` (SCR-FAT-008) — mock email + proposed level.  
2. Mother accepts via `AcceptMotherInviteScreen` (SCR-FAT-009) — parametric inviter/family; accept sets mother role and navigates (e.g. emergency setup).  
3. Device mode screen is **age-neutral parent vs child** — mother is **not** chosen by the user as a third card (`DeviceModeScreen` / SHR-007 notes).

**No real invite email/token service** (status F).

---

## What mother can do (coded)

| Area | Behavior | Status | Evidence |
|---|---|---|---|
| Navigate parent surfaces | Many father routes open to mother unless RoleGuard blocks | B | `role_guard.dart` |
| Web unlock approve | Allowed if partner or full; observer cannot | A in-process | `WebUnlockActor.canApproveUnlock` |
| Time request grants | Partner/full; chips respect ADR-039 ceiling (UI-006) | B | Request inbox tests |
| Instant lock | Mother FULL can lock; father unlock supersedes | A in-process | DeviceLockService / SET-009 |
| Anti-tamper UI | **Omitted** for mother (not greyed owner leak) | A | SET-007 InstantLockScreen |
| SOS mute | **Never shown** to any role | A | `canShowSosMuteControl` always false |
| SOS receipt | Always on; quiet hours cannot silence | A rules | SET-010/011/021 |
| Notification prefs | Per-memberId independence from father | B | NotificationPrefs repos |
| Brain control | **Blocked** → gallery | A | fatherOnlyScreenIds FAT-029 |
| Set mother permission level | **Blocked** (father-only FAT-031) | A | RoleGuard |
| Billing | **Blocked** | A | FAT-056/057 |
| Advisor approve→rules | Father-only approve; mother read-only lean | B | `canApproveAdvisorRules` |
| Privacy / audit | Open to mother per RoleGuard comments (not in fatherOnly) | B | ownerOnly applies to child |
| AI mother feed | Screen/repo exist (FAT-076 area) — verify route wiring | F/G UNKNOWN if placeholder | `mother_ai_feed_*` |

---

## Where mother differs from father (FACT)

1. Cannot open brain control or billing.  
2. Cannot edit her own permission ceiling (father owns FAT-031).  
3. Observer cannot approve unlocks.  
4. Anti-tamper controls hidden.  
5. Lock can be overridden by father unlock + audit supersession.  
6. Analyses may be visible via R-3 paths; control stays father (SET-015 notes).

---

## Incomplete / weak mother experience (gaps)

- Many domains share father UI without deep mother-specific empty/permission copy.  
- Invite/accept is mock — no real membership row in a server `member` table.  
- Mother “FULL” does not equal Device Owner powers — there is no device enforcement layer.  
- Co-parent multi-device session identity is **RoleController switch**, not separate authenticated sessions.  
- Depth of mother access on education, location, outer circle, etc. is **partially UNKNOWN** without per-screen RoleGuard beyond the small fatherOnly/ownerOnly sets (most screens rely on soft UI rules).

---

## Journey sketch

`Login/accept invite (mock) → Emergency setup → Day board → Request inbox / filter unlock (if level allows) → Notification prefs → (blocked) billing/brain`

**Child device effect of mother actions:** same as father — **in-process buses only**, no OS enforcement.
