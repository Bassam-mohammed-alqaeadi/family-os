# 08 — FS-004 L3 Capture Monitoring Flows

**Authority:** SC-OD-04 · SC-OD-05 · SC-OD-06 · P-7 owned by FS-004  
**Law:** Capture prevention ≠ capture monitoring · Child-transparent · No silent full-device surveillance  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## M1 — Configure monitoring + scope

| Field | Spec |
|---|---|
| Actor | Primary, Full |
| Entry | SC-P-MONITOR (Smart Alerts may deep-link here only) |
| Preconditions | Configure role |
| Policy | `mon_on` + scope document (**T-SC-05** storage shape deferred) |
| UI | Toggle; app/scope picker; child-transparency preview; honesty for observation plane |
| Enabled | Save; select scope |
| Forbidden | Silent enable; default “all apps forever” without explicit parent choice; FAT-065 second store; mic |
| Success | Versioned; pending until ack; child transparency **required** once active+acked |
| Pending / Offline | Same as policy delivery |
| Degraded / Unsupported | Monitoring intent may save; **no fake observation events**; empty OBS with honesty |
| Audit | `sc_monitor.configured` / `activated` |
| Notify | Monitoring activated (parents); child sees transparency |
| Nav | Stay / hub |

---

## M2 — Deactivate monitoring

| Field | Spec |
|---|---|
| Transition | mon_on → mon_off |
| Child | Transparency removed/updated after ack |
| Audit | `sc_monitor.deactivated` |
| Notify | Deactivated |

---

## M3 — Observation event (real only)

| Field | Spec |
|---|---|
| Preconditions | mon_on + acked + observation capability allows |
| UI | SC-P-OBS row; optional Smart Alert presentation |
| Forbidden | Invented/demo captures as live; continuous open-app video feed as default product |
| Unsupported | No event; honesty only |
| Audit | `sc_capture.observed` (append-only when real) |
| Notify | Capture observed (when product emits) |
| Child | Transparency already on; no “secret” mode |

---

## M4 — Prevention-only (no monitor)

| Field | Spec |
|---|---|
| Policy | prevent on, mon off |
| UI | Prevention honesty; **no** monitoring transparency banner required for monitoring |
| Forbidden | Calling prevention “monitoring” |

---

## M5 — Monitor-only (no prevention)

| Field | Spec |
|---|---|
| UI | Transparency on; prevention status separate |
| Forbidden | Implying captures are blocked when only monitored |

---

## M6 — Protect surfaces + monitor distinction

| Field | Spec |
|---|---|
| Protect | Family OS sensitive UI capture protection |
| Monitor | Observation of configured capture attempts |
| UI | Separate cards — never one “screen lock” blob |

---

## M7 — Partner / Observer

| Role | Monitoring |
|---|---|
| Partner | View status + decide related tickets; no scope config |
| Observer | View OBS/AUDIT/status only |

---

## M8 — Multi-device

| Field | Spec |
|---|---|
| Policy | Child-scoped mon_on + scope |
| Devices | Per-device observation capability + ack |
| UI | Device mix: “Active on Device A · Unsupported on Device B” |

---

## Transitions

```
mon_off ──configure+save──► mon_pending ──ack──► mon_on + child_transparency
mon_on ──deactivate+ack──► mon_off + transparency_cleared
mon_on + observable ──real capture──► sc_capture.observed
mon_on + unsupported ──╳──► no observation events
```

**No** invented observation TTLs or retention numbers in L3.
