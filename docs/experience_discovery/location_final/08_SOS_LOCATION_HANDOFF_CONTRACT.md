# 08 — SOS Location Handoff Contract (FROZEN)

**System:** #4 Location & Safe Zones ↔ **System #1 SOS**  
**Status:** FROZEN — 2026-09-23  
**Authority:** Q-LOC-09 · Q-LOC-10 · LOC-OD-09/10/14 · SOS Final (supreme for incident law)

---

## 1. Boundary

| Concern | Authoritative package |
|---|---|
| SOS incident lifecycle, ACK≠RESOLVE, delivery≠incident, Break-glass allowlist, Panic Quiet, SOS evidence retention | **`sos_final/`** |
| Location Domain facts, silent child law, trail retention, geofence engine, silent request | **`location_final/`** (this package) |
| Overlap: location samples during SOS; child status words; parent live map handoff | **This handoff contract** |

**Conflict rule:** On SOS incident semantics, **SOS Final wins**. On child global location silence and Domain ownership, **Location Final wins**. Neither may invent Find-My-Child from Break-glass.

---

## 2. L-S12 — Panic/SOS location attachment

| Rule | Frozen |
|---|---|
| Fire without location | **Allowed** (SOS OD-16) — never block SOS on GPS failure |
| Domain role | Attempt acquire; attach evidence; emit honesty class |
| Kernel/SOS role | Bind samples to incident; present parent board |
| Audio/video | **Excluded** (SOS OD-11) — location facts only |

Honesty classes (shared vocabulary):

- acquiring  
- located / ready  
- stale / last known  
- unavailable  

---

## 3. Child presentation during ACTIVE SOS (Q-LOC-09)

See [07_CHILD_SILENT_LOCATION_CONTRACT.md](07_CHILD_SILENT_LOCATION_CONTRACT.md) §4.

SOS Final RD-01 (emergency-critical-only child UI) **remains**; this package **narrows** location to **status words** — no map/coords.

---

## 4. Parent presentation

- Parent SOS board may show location honesty + open **parent** live map (FAT-014 family) when not pure unavailable-without-last-known (per SOS screen engineering evidence).  
- Live map is a **parent Location Domain consumer**, not a child surface.

---

## 5. Break-glass ≠ Find (Q-LOC-10 / LOC-OD-10)

| Allowed (SOS Final) | Forbidden (this freeze) |
|---|---|
| Temporary response override (lock/shell, screen-time blockers, emergency comms, etc.) | Using Break-glass as general **Find My Child** |
| Primary + Mother Full RBAC invoke | Standalone Find product spawned from override |
| Auto-revoke + audit | Permanent locate elevation without separate Owner OD |

**Future Emergency Find** (if ever desired) requires a **new Owner decision** outside SOS Break-glass and outside silent redefinition of L-S1.

---

## 6. Retention handoff

| Data | Retention authority |
|---|---|
| SOS-bound location samples | SOS Final Class — operational **90 days** |
| Normal trail outside incidents | Location Final Class A — **90 days** |
| Incident lifecycle audit | SOS indefinite |

Stores must remain distinguishable ([04_LOCATION_RETENTION_CONTRACT.md](04_LOCATION_RETENTION_CONTRACT.md)).

---

## 7. Identity

SOS location evidence must carry family + child + device/enrollment context (LOC-OD-18), consistent with SOS identity refs.

---

## 8. Non-goals

- Redefining Break-glass allowlist here.  
- Adding national emergency dial.  
- Claiming continuous live stream on child UI.  
- Subscription gating SOS or SOS location attach.
