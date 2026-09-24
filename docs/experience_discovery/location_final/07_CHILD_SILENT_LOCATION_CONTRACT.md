# 07 — Child Silent Location Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** Q-LOC-08 · Q-LOC-09 · Q-LOC-14 · Q-LOC-16 · LOC-OD-08/09/12/13

---

## 1. Global law — fully silent child location UI

The child experience **must not** expose:

| Forbidden on child | Examples |
|---|---|
| Map | Live map, mini-map, pin canvas |
| Coordinates | Lat/lon, plus-codes presented as location tooling |
| Location history | Trail, day thread, frequent-places UI |
| Geofence UI | Zone list as map editor, radius, polygon, alert-rule visibility |
| Location diagnostics | Accuracy meters, provider debug, spoof scores as child tools |
| Weaken/disable controls | Toggle off tracking, reduce safety sampling, “pause location” |

**Operational silence** means location may still be collected/evaluated on-device for safety — without becoming a child location product.

---

## 2. Check-In (Child Safety) — Q-LOC-16 / LOC-OD-13

| Allowed | Forbidden |
|---|---|
| Acknowledgement “I arrived” at a **named** Safety place | Opening a map to pick coordinates |
| Simple confirmation feedback (toast/celebration without coords) | Showing live location card / “your location is…” tooling |
| Silent evidence attach in Domain | Child review of evidence trail |

**IA:** Check-In belongs under **Child Safety** in child UX (not a location-map family).  
Legacy registry title «أنا وصلت + موقعي» / Stage-1 live card = **non-authoritative**; L3 must reshape to Safety ack-only.

---

## 3. Silent Location Request — Q-LOC-08 / LOC-OD-08

| Rule | Frozen |
|---|---|
| Child accept/reject UI | **Forbidden** |
| Child interactive response flow | **Forbidden** |
| Child map / coordinates / history | **Forbidden** |
| Device behavior | Execute authorized request |
| Parent outcome | Honest result state (success / stale / unavailable / queued / failed / platform-denied) |

Dignity-framed “ask child to share” COM model in older Wave-2 docs is **superseded** for L-S6 by this silent law.

---

## 4. SOS exception — Q-LOC-09 / LOC-OD-09

**Only while SOS incident is ACTIVE** (and related emergency-critical board per SOS Final / Panic Quiet):

Child may see **LOCATION STATUS** only:

| Status | Meaning (child-facing concept) |
|---|---|
| **acquiring** | Trying to get a fix |
| **located** | Fix available (no coordinates shown) |
| **stale / last known** | Old fix; honesty about age class — **no map** |
| **unavailable** | No fix |

**Still forbidden during SOS:** map, coordinates, history, geofence UI, diagnostics, disable/weaken controls.

Align label vocabulary with SOS `SosLocationClass` honesty (READY≈located, ACQUIRING, STALE, UNAVAILABLE) without expanding child surfaces.

---

## 5. Disclosure — Q-LOC-14 / LOC-OD-12

| Allowed | Forbidden |
|---|---|
| Non-interactive safety disclosure required by platform/compliance | Disclosure that shows location data |
| Static “family safety cares for you” style notice | Controls to disable/weaken location safety |
| Transparency/consent screens that state **categories** collected (existing privacy pattern) | Child tooling to pause Domain collection |

Disclosure ≠ location product.

---

## 6. Legacy conflicts (reported, not followed)

| Legacy evidence | Freeze stance |
|---|---|
| Prototype: child sees own location + mandatory tracking icon as map-like awareness | **Superseded** by silent UI + optional non-interactive disclosure |
| CHD-024 live location card | **Non-goal** for L3; reshape |
| S-COM-039 child “respond to location request” | **Superseded** by silent request |
| Master audit: CHD-024 shows zones as destinations with map energy | Named Safety ack only; no geometry exposure |

---

## 7. Engineering implication (handoff only — no L3 yet)

- Child routes must RoleGuard-omit parent location screens.  
- Check-In repository may list **named** Safety targets without geometry payloads in UI models.  
- No child-facing Location Domain debug screens.
