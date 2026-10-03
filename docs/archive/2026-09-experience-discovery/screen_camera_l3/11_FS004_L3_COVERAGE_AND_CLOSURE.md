# 11 — FS-004 L3 Coverage and Closure

**Purpose:** Prove L3 covers SC-OD-01…12, frozen laws, and required UX lifecycle without contradicting L2.  
**Master:** [12_FS004_L3_MASTER_CONTRACT.md](12_FS004_L3_MASTER_CONTRACT.md)

---

## A. SC-OD coverage (exact L2 themes)

| ID | Frozen theme (from L2) | L3 representation |
|---|---|---|
| SC-OD-01 | Prevent + Monitor + Protect; transparent monitoring; no silent surveillance | IA pillars; hub; F02–F08; M1–M3; W-C01 |
| SC-OD-02 | OS/device camera ≠ FS-003 package | C1/C6; W-P04; five-way SOD; F19 |
| SC-OD-03 | Prevention + monitoring; no universal third-party claim | F05–F06; M4/M5; W-P05/P06; honesty |
| SC-OD-04 | Hybrid honesty states; ack + capability for claims | F15; file 09; state matrix |
| SC-OD-05 | Microphone OUT of FS-004 | Forbidden in F01/F04/F24; cross-system; child wireframes |
| SC-OD-06 | iOS capability honesty; no fake Android parity | F23; file 09 unsupported path |
| SC-OD-07 | Explicit protected matrix (QR/Studio/call); SOS Final; Quran ordinary path | C4–C5; F11–F12; F24; W-P08 |
| SC-OD-08 | No SOS audio in FS-004 | F24; cross-system SOS/mic table |
| SC-OD-09 | P-7 owned by FS-004; Smart Alerts presentation-only | F06; F20; M1; W-P06 |
| SC-OD-10 | Child transparency mandatory; no child admin | W-C01–C03; M1; F09 |
| SC-OD-11 | Primary+Full configure; Partner+ decide tickets; Observer view; Child no configure | Role matrix; F10; F22 |
| SC-OD-12 | Family baseline + child override (override wins); multi-device | F02–F03; M8; honesty multi-device |

*(L3 maps behavior only — does not re-litigate L2.)*

---

## B. Lifecycle checklist

| Lifecycle item | Covered |
|---|---|
| Overview hub | F01 · W-P01 |
| Family baseline | F02 · W-P02 |
| Per-child override | F03 · W-P03 |
| Camera restriction | F04 · C1–C3 · W-P04 |
| Capture prevention | F05 · W-P05 |
| Screenshot monitoring | F06–F07 · M1–M3 · W-P06 |
| Scope/app selection | M1 · W-P06 (T-SC-05 deferred) |
| Activation/deactivation | M1–M2 |
| Child transparency | W-C01 · M1 |
| Protected Family OS camera | C4–C5 · F11–F12 |
| QR/enrollment exception | C4 · F11 |
| Studio/call exception | C5 · F12 |
| Explicit exception lifecycle | F09–F10 · W-P08 · W-C04 |
| Parent configuration | Role matrix + parent wireframes |
| Parent decision surfaces | F10 · Partner allowed |
| Observer read-only | F22 |
| Child status / transparency | W-C01–C03 |
| All honesty states | File 09 · state matrix |
| Offline / pending / ack | F16–F17 |
| Multi-device divergence | File 09 · M8 |
| Audit history | F21 · W-P10 |
| Monitoring/capture notifications | M3 · F20 |
| Observation only when observable | M3 |
| Source-of-deny / restriction | F14 · five-way |
| FS-003 / ST / FS-002 / Modes / SOS / Quran / Chat | File 10 · F18 · F24 |

---

## C. Frozen laws consistency pass

| Law | L3 status |
|---|---|
| Prevent + Monitor + Protect | Consistent |
| FS-003 package ≠ FS-004 OS camera | Consistent — five-way |
| Prevention ≠ monitoring | Consistent |
| Child-transparent monitoring | Consistent |
| No silent surveillance | Consistent |
| Mic OUT / SOS audio OUT | Consistent — explicit forbidden |
| SOS Final governs SOS | Consistent |
| Protected/exception non-erasing | Consistent |
| Baseline + override; override wins | Consistent |
| Primary+Full configure | Consistent |
| Primary+Partner+Full decide tickets | Consistent |
| Observer view-only | Consistent |
| Child no configure | Consistent |
| Modes schedule + tighten-only | Consistent |
| ST / WF ownership | Consistent |
| No silent cross mutation | Consistent |
| Ack + capability for claims | Consistent |
| iOS honesty | Consistent |
| Offline last-acked | Consistent |
| Multi-device child-scoped | Consistent |
| Audit append-only | Consistent |
| AI no unilateral policy change | Consistent |

---

## D. Open technical (not L3 defects)

| ID | Deferred to implementation / T-SC |
|---|---|
| T-SC-01…12 | Platform APIs, mechanisms — **not selected** |
| T-SC-05 | Scope storage schema |
| T-SC-11 | Exception duration numbers |
| Exact notification copy strings | ARB at build time |
| Exact shell placement of transparency chrome | Composition at ScreenBuild |

These are **marked TBD**, not invented.

---

## E. Ambiguous / residual UX notes (non-blocking)

1. Exact visual weight of persistent child transparency (banner vs dedicated card) — composition choice at ScreenBuild; **requirement** to show when `mon_on` is frozen.  
2. Whether Partner may *request* exception on behalf of child — L2 decide-on-ticket is clear; initiate-on-behalf not expanded — default: child initiates unless L2 says otherwise.  
3. Observation retention UI filters — browse/audit only; no invented retention TTL.

**No L2 contradiction found** in this L3 package.

---

## F. Explicit non-goals (reaffirmed)

- No Android/iOS API selection  
- No schema invention  
- No app code  
- No mic/SOS audio productization  
- No FAT-065 second policy store  
