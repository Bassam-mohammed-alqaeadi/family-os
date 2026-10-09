# 09 — L3 Gap & Contradiction Report

**Date:** 2026-09-23  
**Cross-check:** Full `location_final/` L2 package ↔ this `location_l3/` package  
**Result:** No L2 law changed. Gaps below are design/implementation follow-ups — not reopened Owner product forks.

---

## 1. Contradictions vs L2

| Check | Result |
|---|---|
| Silent family-all zone default | **None** — L3 requires multi-select |
| Movement alerts inside Location | **None** — FAT-077 excluded |
| Child map / SLR respond | **None** — omitted |
| Spoof-proof / Kernel punish | **None** — soft parent warning only |
| Invented numeric cadence/thresholds | **None** |
| Break-glass → Find | **None** |
| Mother Full = Primary export | **None** — Primary-only export/archive |
| Subscription gating | **None** |

**Accidental L2 law changes in L3:** **NONE detected.**

---

## 2. Missing capabilities (vs frozen L2 — need L4/impl, not new OD)

| Gap | Notes |
|---|---|
| Real GPS / background permission OS flows | Platform — Q-LOC-15 related |
| Offline geofence engine | L-S9 — lifecycle required; not coded |
| Polygon editor interaction detail | L3 states circle/polygon; pixel UX refine in visual design |
| Notifications channel tiers for zone events | Depends Notifications system |
| Audit event schema field list | Design says audit; exact schema = technical |
| Frequent places algorithm | S-SEC-023 product exists in legacy; Domain may supply — no new Owner Q |
| “Select all children” copy vs Q-LOC-12 | Allowed as **explicit user action**; must not pre-check all on empty create — clarified in F06 |

---

## 3. Duplicated ownership risks

| Overlap | Resolution in L3 |
|---|---|
| SOS Live CTA vs Location Live | SOS owns incident; Location owns LOC-P-LIVE; F13 handoff |
| Device Health vs Live battery chip | Health owns permission posture; Live may show honesty only |
| Check-In vs Comms “care reply” | Location owns ack+evidence; care reply is Comms if present |
| FAT-077 vs zone NO_SHOW | **Separated** by Q-LOC-18=A |
| Privacy disclosure vs Check-In | Disclosure ≠ Check-In; both child-safe |

---

## 4. Unresolved Technical/Platform only (do not block L3 docs)

From L2 Master §4 — still open, L3 marks as TBD parameters:

- Q-LOC-03 refresh intervals  
- Q-LOC-04 sampling seconds  
- Q-LOC-05 cloud density  
- Q-LOC-06 dwell/hysteresis/NO_SHOW grace numbers  
- Q-LOC-07 signal engineering scores (internal)  
- Q-LOC-15 map SDK  
- Q-LOC-17 cache size/TTL  

L3 wireframes **must not** fill these with invented values.

---

## 5. Legacy Stage-1 app gaps (evidence)

| Legacy | L3 gap to close in future impl |
|---|---|
| FAT-017 no child multi-select | Required by Q-LOC-12=B |
| FAT-017 circle-only | Add polygon path |
| SafeZone model lacks geometry | Domain model later |
| CHD-024 live card | Remove; Safety Check-In only |
| No SLR surface | Add LOC-P-SLR |
| No integrity soft warning | Add on Live |
| No Standard/Elevated control | Add on Live |
| No Export/Archive IA | Add Primary on History |
| Decorative map fractions | Replace with provider-agnostic real map later |

---

## 6. L3 package completeness

| Deliverable | Status |
|---|---|
| 01 IA | Done |
| 02 Role matrix | Done |
| 03 State matrix | Done |
| 04 User flows | Done |
| 05 Wireflow matrix | Done |
| 06 Screen inventory | Done |
| 07 Wireframes | Done |
| 08 Traceability | Done |
| 09 Gap report | this file |
| 10 L3 Master | Done |

---

## 7. Recommendation

**L3 documentation: COMPLETE / VALIDATED against L2.**  
Next authorized step (separate commission): visual design polish and/or L4 domain/API engineering — **not** app UI coding until Owner commissions implementation.
