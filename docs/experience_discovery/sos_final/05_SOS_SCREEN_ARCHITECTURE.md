# 05 — SOS Screen Architecture

**Status:** FROZEN SCREEN ENGINEERING CONTRACT  
**SOS PRODUCT CONTRACT STATUS: FROZEN**  
**No implementation in this task.**  
**Screens in scope:** SCR-FAT-018, SCR-FAT-028, SCR-CHD-005, SCR-CHD-006  
**Decision vocabulary:** KEEP / EXTEND / MODIFY / SPLIT / REPLACE

---

## Overview map

| Screen | Decision | Rationale |
|---|---|---|
| SCR-CHD-005 | **MODIFY** | Keep 3s hold; wire incident create; OD-14 reachability; no audio |
| SCR-CHD-006 | **EXTEND** | Keep coral board; RD-01 critical-only when Panic Quiet; receipts; cancel; location honesty |
| SCR-FAT-018 | **EXTEND** | Role variants; ACK≠RESOLVE; Break-glass parent override affordance (RD-02); trusted escalate |
| SCR-FAT-028 | **EXTEND** | Max 5 backups + priority + verification (RD-04/05); Panic Quiet config; no national number |

Supporting (out of SOS folder but referenced): FAT-014 map (reuse), FAT-058 quiet hours honesty (keep), shell FAB (keep), CHD-021 SOS CTA (keep).

**No new screen IDs** required for freeze. Break-glass mounts on FAT-018 (and optionally lock-response surfaces) as parent override — **not** a child trigger ID.

---

## SCR-CHD-005 — زر الاستغاثة (Child SOS Button)

| Field | Spec |
|---|---|
| **Purpose** | Accidental-protected activation of SOS incident |
| **User** | Child only (parent lean) |
| **Entry** | Shell SOS FAB; CHD-021 CTA; deep link; break-glass may land here or fire directly |
| **Navigation out** | On successful local create → CHD-006 with `alertId`+`childId` |
| **Controls** | Hold button (3s); no mute; no audio |
| **Information hierarchy** | Hint → hold control → status → always-on banner (no non-critical clutter) |
| **States** | idle, holding, cancelled-early, firing, parent-lean |
| **Loading** | Brief while persisting local incident |
| **Empty** | N/A (always show control) |
| **Error** | Persist failure with retry; still attempt local create |
| **Degraded/offline** | Allow fire; status “will sync when online” |
| **Permission restrictions** | Parent lean only; location permission not required to fire |
| **Success feedback** | Navigate CHD-006 |
| **Failure feedback** | Inline/error state + retry |
| **Role-specific** | Child body; parent lean |
| **Events** | SosTriggered / IncidentCreated (triggerSource=HOLD) |
| **Data consumed** | childId, readiness |
| **Data produced** | New incident (local) |
| **Child-device effect** | Enter SOS active UX (Panic Quiet shapes CHD-006, not trigger removal) |
| **Backend** | Eventually `POST /sos` from outbox |
| **Notifications** | Triggers guardian fan-out (after/at sync) |
| **Audit** | Trigger audited |
| **Decision** | **MODIFY** |

---

## SCR-CHD-006 — الاستغاثة جارية (Child SOS In Progress)

| Field | Spec |
|---|---|
| **Purpose** | Child-facing active incident board with honest status and safe cancel |
| **User** | Child (parent lean) |
| **Entry** | From CHD-005; resume if ACTIVE incident exists |
| **Navigation** | Contact parent → family chat or call fallback UX; cancel success → CHD-004; empty → CHD-005 |
| **Controls** | Contact parent; Cancel (confirm sheet); confirm safe; dismiss sheet. Under Panic Quiet (RD-01): **only** these + status/location — no entertainment chrome. |
| **Information hierarchy** | Lifecycle → location honesty → delivery honesty → device strip → contact → cancel → P-4 banner |
| **States** | loading, active, empty, error, parent-lean; lifecycle chips; transport chips |
| **Loading** | While loading incident |
| **Empty** | No active incident → CTA to CHD-005 |
| **Error** | Load failure + retry |
| **Degraded/offline** | Sync pending; delivery pending; location unavailable |
| **Permission restrictions** | Parent lean; child cannot configure |
| **Success feedback** | Cancel toast; parents informed |
| **Failure feedback** | Cancel failure keeps ACTIVE |
| **Role-specific** | Child only actions |
| **Events** | SosChildContactParent, SosCancelled/FalseAlarm |
| **Data consumed** | Incident, deliveries, location state, battery, connection |
| **Data produced** | Cancel event; optional call attempt |
| **Child-device effect** | Continues until resolve/cancel |
| **Backend** | Patch cancel; read receipts |
| **Notifications** | Cancel notifies parents |
| **Audit** | Cancel/false-alarm immutable |
| **Decision** | **EXTEND** |

**Cancel confirmation (OD-06):** Title + body + confirm “I am safe” + back. No one-tap cancel.

---

## SCR-FAT-018 — بلاغ استغاثة (Parent SOS Incident Board)

| Field | Spec |
|---|---|
| **Purpose** | Parent incident console for ACTIVE→RESOLVED |
| **User** | Primary, Mother Full, Partner, Observer (variant) |
| **Entry** | Push deep link; shell shortcut; alerts hub; after fire sync |
| **Navigation** | Live map → FAT-014; setup → FAT-028 (Primary/Full only); resolve exit → day board |
| **Controls (role-filtered)** | | 
| | **All receiving roles:** Contact child, open map (if location not UNAVAILABLE without last-known), view evidence |
| | **Partner/Full/Primary:** Acknowledge, Escalate (trusted), Resolve |
| | **Observer:** Contact child only among mutating actions; **no** Ack/Escalate/Resolve/Setup |
| | **Primary/Full:** Setup CTA; **Break-glass** (RBAC) when allowlisted bypass needed for SOS response |
| | **Partner:** Ack/Escalate/Resolve/Contact — **no** Break-glass |
| **Information hierarchy** | See UX contract §2; delivery ≠ lifecycle chips |
| **States** | loading, empty, error, active (by lifecycle), child-lean, Observer variant, degraded overlays |
| **Loading** | Fetch incident |
| **Empty** | No active incident → setup CTA (if allowed) / calm empty |
| **Error** | Network error + retry |
| **Degraded/offline** | Delivery/location/device chips |
| **Permission restrictions** | OD-01…04 enforced in UI + server |
| **Success feedback** | Ack/Escalate/Resolve toasts; state chips update |
| **Failure feedback** | Action error; state unchanged; channel failures listed |
| **Role-specific differences** | Observer read+contact; Partner act no config; Full/Primary act+config |
| **Events** | SosAcknowledged, SosEscalated, SosResolved, SosCallAttempted, SosBreakGlassInvoked/Ended |
| **Data consumed** | Incident, evidence, deliveries, ladder (read), role, MotherLevel |
| **Data produced** | Ack/escalate/resolve mutations |
| **Child-device effect** | Receipt updates on CHD-006; resolve ends active child board |
| **Backend** | ack/escalate/resolve APIs; enforce roles |
| **Notifications** | Fan-out state changes to other guardians |
| **Audit** | Every action |
| **Decision** | **EXTEND** |

**UI corrections vs Stage-1:** Split Acknowledge vs Resolve; Observer must lose resolve/escalate; escalate copy = trusted contacts only; remove implication of national emergency auto-call; auto-call = family/trusted only.

---

## SCR-FAT-028 — إعداد الطوارئ (Emergency / SOS Setup)

| Field | Spec |
|---|---|
| **Purpose** | Configure ladder, trusted contacts (max 5, priority, verification), escalation delays, Panic Quiet Mode, channel readiness |
| **User** | Primary + Mother Full (edit). Partner/Observer: blocked. Child: blocked. |
| **Entry** | Settings hub; FAT-018 setup CTA; onboarding wizard step |
| **Navigation** | Back to settings / FAT-018 |
| **Controls** | Add/edit/remove backup (cap 5); set priority 1…5; start verification; toggle enabled **only if VERIFIED** (or allow enable but escalation engine ignores non-verified — prefer disable escalate until verified); set delaySeconds; Panic Quiet Mode toggle; channel readiness. Rung-1 locked. **No** SOS mute. **No** national emergency number. **No** child Break-glass trigger config. |
| **Information hierarchy** | Protocol → receipt-cannot-disable → readiness → rung-1 → backups (priority + verify badge) → Panic Quiet → channels |
| **States** | loading, ready, inline validation error, forbidden (wrong role), degraded channel list |
| **Loading** | Load ladder + readiness |
| **Empty** | Defaults with both parents; zero backups OK |
| **Error** | Save/load failure |
| **Degraded/offline** | Local edit queued if policy allows; honesty on sync |
| **Permission restrictions** | OD-02 Partner cannot edit; OD-01 Observer cannot; Primary+Full can |
| **Success feedback** | Saved; audit |
| **Failure feedback** | Immovable parent errors; role forbidden |
| **Role-specific** | Edit vs lean/read-only |
| **Events** | SosLadderUpdated, PanicQuietModeChanged, ContactUpserted/Removed, ContactVerificationAttempted/Succeeded/Failed/Revoked |
| **Data consumed** | Ladder, verification states, readiness, role |
| **Data produced** | Ladder + mode config + verification state machine |
| **Child-device effect** | Panic Quiet shapes **active** CHD-006 critical-only UI |
| **Backend** | Ladder CRUD; verification port (abstract); rung-1 validation; max-5 enforcement |
| **Notifications** | Optional non-critical config-change notice |
| **Audit** | All config + verification mutations |
| **Decision** | **EXTEND** |

---

## Cross-cutting screen rules

1. **KEEP** coral language and 3s hold.  
2. **MODIFY** Stage-1 conflicts with OD/RD (Observer powers, ACK/RESOLVE, static seen, national escalate implication, unlimited unverified backups).  
3. **Do not REPLACE** Screen IDs.  
4. Break-glass = parent override on response surfaces — **not** child FAB.  
5. Evidence embeds in FAT-018; 90-day sample retention is backend policy (RD-03).
