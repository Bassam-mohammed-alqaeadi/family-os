# 02 — Location Policy Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** [01_LOCATION_OWNER_DECISIONS.md](01_LOCATION_OWNER_DECISIONS.md)  
**Scope:** Product/policy law for Location Domain vs Policy Kernel — **not** screen engineering.

---

## 1. Domain ownership (LOC-OD-14 / 15)

| Owner | Owns | Must not own |
|---|---|---|
| **Location Domain** | Fixes/pings; geometry (circle/polygon); geofence definitions & assignments; integrity/anti-spoof **signals** (facts); history trail; evidence packs; honest acquisition/result states | Interpreting “what parent should do”; permanent policy mutation; subscription checks |
| **Policy Kernel** | Interpretation of canonical location/geofence/movement events; notification/action decisions; dwell/hysteresis **policy parameters** once frozen; alert enablement outcomes | Inventing coordinates; rewriting history; claiming cloud success without sync proof |

**Rule:** UI never writes balances or policy outcomes by bypassing Domain → Event → Kernel.

---

## 2. Core availability (LOC-OD-02)

- Core **Live Location existence**, **SOS location attachment capability**, and **family chat** remain available regardless of subscription state.  
- Entitlement modules **must not** gate location fire/sync/display paths for core safety location.  
- Optional **depth monetization** (if ever desired) is **out of scope** for this freeze and **must not** redefine the 90-day trail baseline or core availability (Q-LOC-01 closed: 90 days; not 24h baseline).

---

## 3. Identity context (LOC-OD-18)

Every location-related event and persisted fact **must** carry:

- `familyId`  
- `childId`  
- `deviceId` and/or `enrollmentId` (as available from System #3)

Missing identity context → event is **invalid** for Policy Kernel interpretation (fail closed for action; may still queue for repair if Domain marks incomplete).

---

## 4. Silent vs visible surfaces

| Surface | Law |
|---|---|
| Child global location UX | **Fully silent** (LOC-OD-09) |
| Child Check-In | Ack only; evidence silent (LOC-OD-13) |
| Silent Location Request | No child interactive UX (LOC-OD-08) |
| Child SOS (ACTIVE only) | Status words only (LOC-OD-09) |
| Parent/guardian | Live map/history/zones per Role Access Contract |

---

## 5. Geometry policy (LOC-OD-11 / 19)

- **Circle** and **Polygon** are both first-class.  
- Authoring UX may prefer circle for speed; domain must accept polygon.  
- Legacy circle-only schema/mocks are **non-authoritative**; migration is **additive** (keep circle).

---

## 6. Lifecycle obligation (see Event Lifecycle Contract)

Canonical pipeline (frozen):

`Definition → Geometry → Assignment → Local Policy Context → Local Evaluation → Dwell/Hysteresis → Canonical Event → Policy Interpretation → Notification/Action → Audit → Offline Queue → Sync`

No stage may claim later-stage success early (especially Sync).

---

## 7. Integrity (Q-LOC-07 = C · LOC-OD-22)

- Location Domain may emit **integrity/anti-spoof signals** as facts.  
- **Soft Parent-facing warning** allowed (e.g. low location confidence).  
- **No** child integrity UI.  
- **No** automatic Kernel lock, punishment, or punitive action.  
- **Do not** invent distrust scores or numeric thresholds in contracts or UI copy.  
- **Do not** claim spoof-proof behavior.  
- Signal engineering quality remains **Technical** (not a product re-open).

---

## 8. Honesty law

- Never claim live/cloud/GPS success without proof.  
- Offline = queue + honest pending/failed states ([09_OFFLINE_LOCATION_CONTRACT.md](09_OFFLINE_LOCATION_CONTRACT.md)).  
- Stage-1 decorative maps / InMemory repos = **prototype rendering only**.

---

## 9. Cross-policy non-interference

| Other system | Location law |
|---|---|
| Screen Time expiry / modes | Must **not** disable location collection or SOS attach |
| Device lock / Kill Switch | Must **not** disable SOS; location for SOS still attempts honest acquire |
| Quiet hours / notification prefs | Must **not** silence SOS; geofence/check-in notification tiers TBD with Notifications (not invented here) |
| Web filter / app rules | Independent of Location Domain |

---

## 10. Authority when docs conflict

1. This `location_final/` package (Owner freezes)  
2. Policy Register / Constitution (forever-free safety)  
3. SOS Final (SOS-specific)  
4. Prototype / schema / app mocks — **evidence only**
