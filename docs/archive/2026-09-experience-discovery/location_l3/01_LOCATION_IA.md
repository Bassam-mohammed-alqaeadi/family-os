# 01 — Location Information Architecture (L3.1)

**System:** #4 Location & Safe Zones — **L3 UX Design**  
**Status:** L3 AUTHORIZED (docs only — no app code)  
**Authority:** [`../location_final/11_LOCATION_FINAL_MASTER_CONTRACT.md`](../location_final/11_LOCATION_FINAL_MASTER_CONTRACT.md)  
**Entry:** [10_LOCATION_L3_MASTER.md](10_LOCATION_L3_MASTER.md)

**Hard rules:** Explicit child multi-select (Q-LOC-12=B) · L-S7 = ENTER/EXIT/NO_SHOW only · soft parent integrity warning only · Standard watch / Elevated live · child silent · no Find-from-Break-glass · provider-agnostic map · no invented numbers.

---

## 1. UX principle

Location is a **parent reassurance + safety evidence** system.  
The child experience is **operationally silent** except Check-In acknowledgement and SOS status words.

IA places capabilities by **role job**, not by legacy Stage-1 screen filenames (evidence only).

---

## 2. Role-level mental models

| Role | Job-to-be-done | Location product shape |
|---|---|---|
| **Primary** | See kids now; review trail; author zones; export/archive; act on events | Full parent Location suite |
| **Co-Parent** | Reassurance (live + operational history); Full may configure zones; Partner may Silent-Request; never Primary-equivalent export/archive | Same live/history view; config gated by MotherLevel |
| **Child** | Safety Check-In ack; optional non-interactive disclosure; SOS status exception | **No** location map product |

Co-Parent levels (from L2): Observer / Partner / Full — Live does not grade; zone configure = Full; Silent Request initiate = Primary + Partner + Full.

---

## 3. Parent Information Architecture

### 3.1 Placement (logical nav — not final chrome)

```
Parent shell
 └─ أبنائي / Kids (child-context hub)
     ├─ Child profile summary → Live entry
     ├─ LIVE LOCATION ………… L-S1
     ├─ LOCATION HISTORY …… L-S2
     ├─ SAFE ZONES
     │    ├─ Library …………… L-S3
     │    └─ Author / Edit …… L-S3 + L-S4 (+ assignment)
     ├─ SILENT LOCATE ……… L-S6 (action + result)
     └─ (from notifications) ZONE EVENTS …… L-S7 kinds

Cross-links (not Location-owned):
 ├─ Device Health / Monitoring …… posture inputs (L-S8/L-S11 bands)
 ├─ SOS Incident Center ………… L-S12 handoff → Live
 └─ Audit log …………………… sensitive opens / export / zone edits
```

### 3.2 Capability → IA home

| Capability | Lives in | Notes |
|---|---|---|
| **Live Location** | Parent Live Map family | Standard watch / Elevated live states |
| **Location History** | Parent History family | 90d trail; Primary Export/Archive |
| **Geofence Library** | Zones list | Named zones; open edit |
| **Geofence Rules** | Zone author/edit + per-zone alert toggles | ENTER/EXIT/NO_SHOW enablement |
| **Assign children** | Zone author/edit (**required on create**) | Q-LOC-12=B multi-select |
| **Check-In (parent receive)** | Day board / notification card + History stop | Not a child map |
| **Silent Location Request** | Action from Live/Profile → result sheet/card | No child UI |
| **Zone events ENTER/EXIT/NO_SHOW** | Notification → Event detail → Live/History | L-S7 = these kinds only |
| **Integrity / low confidence** | Soft banner/chip on Live (and optionally History) | Parent only; Q-LOC-07=C |
| **Offline / sync states** | Inline chips on Live/History/Zones/Silent result | Honest pending/synced/failed |
| **SOS location handoff** | SOS board → open Parent Live (focus child) | SOS Final owns incident UX |
| **Sampling bands** | Not a child surface; parent may see honesty (“updating…”) | Names only: normal / low_battery / sos_active |
| **Road Safety FAT-077** | **Out of Location IA** | Separate system |

### 3.3 Parent surface stack (composition)

| Layer | Content |
|---|---|
| **App bar** | Title · child context · SOS ungated entry |
| **Honesty / integrity** | Life360-style peace-of-mind banner; low-confidence soft warning |
| **Watch mode control** | Standard watch \| Elevated live (no ms labels) |
| **Map canvas** | Provider-agnostic; pins + zone overlays (geometry from Domain) |
| **Freshness strip** | ready / acquiring / last seen / stale / unavailable + offline/syncing |
| **Primary actions** | Silent locate · History · Zones · (Primary) Export from History |
| **Sheets** | Silent result · Zone event · Offline explain |

---

## 4. Child Information Architecture

```
Child shell
 └─ Child Safety
     └─ CHECK-IN (named places only) …… L-S5

 └─ Transparency / compliance (existing privacy pattern)
     └─ Non-interactive disclosure (categories) …… Q-LOC-14

 └─ SOS (System #1 surfaces)
     └─ LOCATION STATUS words only while ACTIVE …… Q-LOC-09
```

**Forbidden child IA branches:** Live map · History · Zones library/rules · Silent-request respond · Integrity diagnostics · sampling controls · coordinates.

---

## 5. Notification IA (parent)

| Event | Opens |
|---|---|
| ENTER / EXIT / NO_SHOW | Zone event surface → optional Live focus |
| Check-In received | Reassurance card → History / Live |
| Silent Request result | Result surface on initiator + viewers |
| Integrity soft warning | Does **not** require push by default (inline on Live); optional notify TBD with Notifications system — **not invented as mandatory here** |
| SOS | SOS Incident (not Location-owned) |

---

## 6. Explicit non-placements

| Must not live in Location IA | Why |
|---|---|
| Driving / crash / speed alerts | Q-LOC-18=A · FAT-077 |
| Find My Child from Break-glass | Q-LOC-10 |
| Child map or “موقعي” tooling | Silent child law |
| Map SDK brand chrome as product requirement | Q-LOC-15 open |
| Numeric refresh / dwell / sampling copy | No invention |

---

## 7. Legacy registry mapping (evidence only)

| Legacy evidence ID | L3 stance |
|---|---|
| SCR-FAT-014 | Candidate shell for **Live Map** — reshape to L3 states |
| SCR-FAT-015 | Candidate shell for **History** — add Primary export/archive IA |
| SCR-FAT-016 / 017 | Candidate **Library / Author** — force multi-select; polygon+circle |
| SCR-CHD-024 | **Reshape** to Child Safety Check-In only |
| SCR-FAT-013 location card | Entry to Live |
| SCR-FAT-018 live map CTA | SOS → Live handoff |

New logical surface IDs for L3 inventory use `LOC-*` (see Screen Inventory). Legacy IDs are mapping hints, not completeness proof.
