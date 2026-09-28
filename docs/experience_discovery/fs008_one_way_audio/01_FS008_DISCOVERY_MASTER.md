# FS-008 — One-Way Audio — Discovery Master

**Canonical ID:** `FS_008_One_Way_Audio`  
**Title:** One-Way Audio  
**Date:** 2026-09-25  
**Phase:** 2 (analysis only — no production code)  
**Service alias (Domain 1):** `S-PAR-030` الصوت باتجاه واحد  

---

## 1. Authority sources checked

| Source | Role |
|--------|------|
| Owner Phase 2 resolution | Named FS-008 = One-Way Audio |
| `family-os/06_DOMAIN_1_SECURITY.md` § المراقبة المتقدمة + ١٨ ضابطًا | **Primary product law** for ambient listen |
| `family-os/03_COMPETITIVE_PARITY.md` | FamiSafe parity correction |
| `family-os/02_DECISION_LOG.md` | Adoption / cancel of prior delete advice |
| `family-os/18_PLATFORM_GATES.md` Gate 7 | Platform / geo / legal gate |
| FS-004 L2 SC-OD-05 | Mic **OUT of FS-004** |
| FS-006 / SOS Final SC-OD-08 | **No SOS ambient audio** |
| `family-os/_REGISTRY/services.csv` | **No `S-PAR-030` row** (gap) |
| `screens.csv` / `journeys.csv` | **No dedicated SCR/JRN** (gap) |
| Flutter `app/lib` | **No ambient-listen feature module** |

Referenced but **missing:** `family-os/06_DOMAIN_1_AUDIO.md` (cited in FS-004 discovery; file absent).

---

## 2. Mission (from approved Domain 1)

Ambient microphone capture on the **child device**, initiated by the **father**, for **verification in a moment of concern** — **not** routine surveillance.

Marketing stance (Domain 1): full authority **with** full transparency (“أخبر ابنك بذلك”).

---

## 3. Current repository truth

| Layer | State |
|-------|--------|
| Product decision | **APPROVED** (Domain 1, 18 controls, P2 priority) |
| Registry service row | **MISSING** |
| Screen IDs | **MISSING** |
| Journeys | **MISSING** |
| Flutter Domain / Local store | **MISSING** |
| Native mic capture | **NOT IMPLEMENTED** |
| FS-004 ownership | Explicitly **excluded** (SC-OD-05) |
| SOS evidence pack | Ambient audio **forbidden** |

Classification: **DOCUMENTED PRODUCT LAW · ZERO IMPLEMENTATION · OUT OF FS-001…007 packs until this Phase 2 FS.**

---

## 4. Capability honesty (target)

| Capability | Honest state |
|------------|--------------|
| Local policy / audit / UI gates | REAL LOCAL (future) |
| Mic capture on Android | Native plane — **NOT IMPLEMENTED** today; contract only |
| Mic on iOS | Domain 1 comparison implies hard; Gate 7 says Android-only — treat as **UNRESOLVED** for iOS |
| Remote upload / E2E listen | REMOTE / crypto — **NOT IMPLEMENTED**; Domain requires E2E |
| Download / share / screenshot | **FORBIDDEN** by Domain controls 17 |
| EU/UK enablement | **UNSUPPORTED** (geo kill-switch) |

---

## 5. Documented contradictions (do not invent resolution)

| ID | Conflict | Classification |
|----|----------|----------------|
| **AUD-C1** | Domain 1 duration = **60 seconds**; Gate 7 / FamiSafe parity table header = **10 minutes** | **UNRESOLVED** — both Owner-facing docs |
| **AUD-C2** | Domain 1 triggers = reason list + manual; Gate 7 = **active SOS or safe-zone exit only** | **UNRESOLVED** |
| **AUD-C3** | Domain allows reason `بلاغ استغاثة`; SOS Final forbids SOS ambient audio evidence | **DEPENDENCY** — SOS may *not* attach audio; One-Way Audio may still run as separate Domain with reason “SOS-like worry” — needs Owner clarity |
| **AUD-C4** | P-4 historical “SOS audio broadcast” vs SC-OD-08 no SOS audio | Prefer SC-OD-08 / SOS Final for SOS; One-Way Audio is **not** SOS evidence |
| **AUD-C5** | `S-PAR-030` approved in Domain docs but absent from `services.csv` | **Registry debt** |

L2 may freeze the **18-control Domain model** as primary and mark Gate 7 deltas as **OPEN** rather than inventing a merge.

---

## 6. Inventory impact (traceability seed)

| Inventory | IDs | Note |
|-----------|-----|------|
| Systems (42) | SEC advanced monitoring cluster | No exact subsystem letter for S-PAR-030 in live CSV |
| Services (240) | Intended `S-PAR-030` | **Not present** in CSV — gap |
| Journeys (73) | None dedicated | Gap |
| Screens (130) | None dedicated | Gap — future FAT/CHD surfaces required |

---

## 7. Discovery acceptance

```text
FS-008 DISCOVERY: COMPLETE (evidence-bound)
IMPLEMENTATION: NOT AUTHORIZED
NATIVE MIC: NOT IMPLEMENTED
```

**Next:** Policy / Authority / L2.
