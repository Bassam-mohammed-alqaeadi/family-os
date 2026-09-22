# 06 — SOS Screen Engineering

**Do not implement here.** Engineering contract only.

---

## SCR-FAT-018 — بلاغ استغاثة

| Field | Content |
|---|---|
| Screen ID | SCR-FAT-018 |
| Route | `/scr-fat-018` (`alertId`, `childId` query) |
| Widget | `SosAlertScreen` |
| Repository / service | `SosAlertRepository` / `stage1SosAlertRepository`; `SosFireService` param unused for fire |
| Current states | loading, error, empty, active coral board, child lean |
| Current actions | call-now, live map → FAT-014, resolve, escalate, setup → FAT-028 |
| Current limitations | No GPS, dialer, push, ACK; decorative map; motherLevel unused for gating; Stage-1 toasts |
| Who can access | Father + mother (any level in practice); child lean |
| SHOULD become | Critical-alert board + live location + real call/SMS + delivery receipts + ACK ≠ RESOLVE |
| Decision | **Modify / extend** (keep coral board) |
| New components | Delivery status chips, degraded banners, ack CTA, real map bind |
| Backend data | `sos_alert` + location stream + delivery attempts |
| Events | ack, resolve, escalate, call_attempted |
| Navigation | Deep-link from push; FAT-014; FAT-028 |
| Error/recovery | Channel failure, stale location, offline parent retry |

---

## SCR-FAT-028 — إعداد الطوارئ

| Field | Content |
|---|---|
| Screen ID | SCR-FAT-028 |
| Route | `/scr-fat-028` |
| Widget | `EmergencySetupScreen` |
| Repository | `SosLadderRepository` (`Prefs` / `InMemory`) |
| Current states | loading, ladder list, inline validation error |
| Current actions | add backup, toggle/remove backup; parents locked ON |
| Current limitations | No phone/email; delays not scheduled; no national number UI; no MotherLevel RoleGuard; mute toggle correctly absent |
| Who can access | Any role that navigates (no lean) — **OWNER** who should |
| SHOULD become | Verified contacts + delay editor + national number + role-gated edit |
| Decision | **Extend** (keep rung-1 law) |
| New components | Contact picker, delay stepper, national number field, verify status |
| Backend data | Ladder document; contact MSISDNs; verification tokens |
| Events | ladder_updated (audit) |
| Navigation | From FAT-018 empty, settings hub, setup wizard |
| Error/recovery | Validation inline (already); persist failure states needed |

---

## SCR-CHD-005 — زر الاستغاثة

| Field | Content |
|---|---|
| Screen ID | SCR-CHD-005 |
| Route | `/scr-chd-005` |
| Widget | `ChildSosButtonScreen` |
| Repository / service | `SosFireService`, `InMemorySosAlertRepository` via `fireAndSeedSosAlert` |
| Current states | idle, holding countdown, cancelled early, firing; parent lean |
| Current actions | 3s hold → fire → navigate CHD-006 |
| Current limitations | Default `childId = child_local`; no permission preflight; no offline queue; no mic/location |
| Who can access | Child body; parent lean |
| SHOULD become | Same hold UX + real fire pipeline + offline local ACTIVE |
| Decision | **Modify** |
| New components | Permission honesty sheet (non-blocking), offline badge |
| Backend data | `POST /sos` ungated |
| Events | SosTriggered |
| Navigation | → CHD-006 with alertId; FAB from shell |
| Error/recovery | Fire failure honest; still show local ACTIVE if required by P-4 |

---

## SCR-CHD-006 — الاستغاثة جارية

| Field | Content |
|---|---|
| Screen ID | SCR-CHD-006 |
| Route | `/scr-chd-006` |
| Widget | `ChildSosInProgressScreen` |
| Repository | `SosAlertRepository` |
| Current states | loading, error, empty, active body, parent lean |
| Current actions | call father → CHD-007; cancel sheet → resolve → CHD-004 |
| Current limitations | Static “seen” ARB; no live location UI; resolve may desync multi-device |
| Who can access | Child; parent lean |
| SHOULD become | Live receipt-driven status; location honesty; distinct false-alarm if OWNER requires |
| Decision | **Extend** |
| New components | Receipt rows, location/battery live strip, degraded chips |
| Backend data | Delivery receipts; location pings |
| Events | SosResolved / SosFalseAlarm |
| Navigation | CHD-007, CHD-004, CHD-005 from empty |
| Error/recovery | Network error state exists; needs retry + offline |

---

## Supporting screens (reuse)

| Screen | Role in SOS | Decision |
|---|---|---|
| SCR-FAT-014 | Live map target from FAT-018 | Reuse / bind SOS session location |
| SCR-FAT-058 | Quiet hours + SOS pierce banner | Keep; never add mute |
| SCR-CHD-021 | SOS CTA at time expiry | Keep |
| SCR-CHD-007 | “Call father” today | May split later to dialer — OWNER |
| Audit log | SOS kind + demo fire CTA | Extend lifecycle entries |

## Possible new screens (not in 129 unless OWNER expands)

- SOS history / evidence viewer  
- Delivery failure detail  
- National escalate confirm  

Any new screen ID requires registry authority — **OWNER DECISION** / QUESTIONS.md.
