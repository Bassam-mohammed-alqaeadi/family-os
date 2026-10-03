# 05 — Geo-Fence Contract (FROZEN)

**System:** #4 Location & Safe Zones  
**Status:** FROZEN — 2026-09-23  
**Authority:** Q-LOC-11 · LOC-OD-11/14/15/19 · Event lifecycle brief  
**Slices:** L-S3 Geofence Library · L-S4 Geofence Rules · (feeds L-S9 Offline Engine)

---

## 1. Geometry types (LOC-OD-11)

| Type | Status | Authoring intent |
|---|---|---|
| **Circle** | First-class; simple/common default | Center + radius |
| **Polygon** | First-class; fully supported | Ordered vertices / ring |

**Migration law:** Schema, API, and Domain **must** support both. Circle support is **never destructively removed**. Legacy circle-only `geofence` table / FAT-017 circle UI are **evidence of gap**, not a ban on polygon.

---

## 2. Library vs rules vs evaluation

| Layer | Owner | Contents |
|---|---|---|
| **Definition** | Location Domain | Name, icon/metadata, active/archived |
| **Geometry** | Location Domain | Circle **or** Polygon payload; validation |
| **Assignment** | Location Domain | Which child(ren) / family-default binding |
| **Local Policy Context** | Synced snapshot on child device | Rules + geometry needed for offline eval (bounded) |
| **Local Evaluation** | Offline Geofence Engine (Domain) | Inside/outside candidates |
| **Dwell / Hysteresis** | Engine + **Policy parameters** | Suppress flap; confirm dwell — **kinds frozen**; **numeric thresholds remain Technical (Q-LOC-06 numbers)** |
| **Canonical Event** | Domain emits | ENTER / EXIT / NO_SHOW only (Q-LOC-18=A · Q-LOC-06=A) — **not** driving/movement kinds |
| **Interpretation / Action** | Policy Kernel | Notify? escalate suggest? ignore? |

---

## 3. Event kinds (schema-aligned floor)

Minimum canonical kinds (frozen — Q-LOC-18=A · Q-LOC-06=A · LOC-OD-21/24):

- `ENTER`  
- `EXIT`  
- `NO_SHOW`

**Do not** add movement/driving alert kinds into Location. **FAT-077 Road Safety** remains a **separate** product/system boundary.

---

## 4. Authoring & RBAC

- Create/edit/delete geometry & assignments: **Primary** and **Mother Full** ([03_LOCATION_ROLE_ACCESS_CONTRACT.md](03_LOCATION_ROLE_ACCESS_CONTRACT.md)).  
- Lower MotherLevels: view live/history reassurance; **no** zone configure.  
- Child: **no** geofence UI.

---

## 5. Assignment (Q-LOC-12 = B · LOC-OD-20)

| Topic | Status |
|---|---|
| Schema idea `child_id NULL = all children` | Evidence only — **not** a silent create default |
| Create/save default | **FROZEN:** explicit child **multi-select required** before save |
| Silent family-all default | **Forbidden** |

L3 must reflect multi-select before save. Domain persists an explicit assignment list (≥1 child). Expanding a zone to additional children later is an **explicit edit**, not an implied create default.

---

## 6. Alert enablement

- Per-zone arrival/departure/no-show **intent** exists in prototype/UI evidence.  
- Enablement is a **Domain-synced rule flag**; Kernel decides notification emission.  
- Toggle that changes nothing in Kernel = **policy violation** (Gap-Closing Mandate).

---

## 7. Radius / vertex constraints

- Legacy UI used 50–500 m; schema 50–5000 m — **not re-frozen numerically here**.  
- Polygon vertex limits, max area, self-intersection rejection → **technical feasibility** before implementation (not Owner product numbers in this package).

---

## 8. Non-goals

- Claiming real GPS geofencing in Stage-1 mocks.  
- Child-visible geofence list as a “destination picker” that exposes map/geometry (Check-In may use **named** places without exposing geometry).  
- Merging Road Safety crash/speed product (FAT-077) into Location geofence alerts (forbidden by Q-LOC-18=A).
