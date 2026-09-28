# PHASE 3 — Gap Register (10)

**Date:** 2026-09-25  
**Rule:** Classify — do not invent product law to close POLICY / REGISTRY gaps.  

## Schema

`gap_id` · `source_map` · `summary` · `class` · `blocks_phase4_planning` · `notes`

## Register

| gap_id | source_map | summary | class | blocks_phase4_planning | notes |
|--------|------------|---------|-------|------------------------|-------|
| P3-G001 | 01/02 | S-PAR-030 approved Domain missing from services.csv | REGISTRY GAP | No — planning may note inventory debt | AUD-C7 |
| P3-G002 | 05/06 | FS-008 has zero SCR and zero JRN | DESIGN GAP | No — do not invent ScreenBuild | Phase 2 |
| P3-G003 | 02 | AUD-C1 clip duration unresolved | POLICY DECISION REQUIRED | Yes for FS-008 codegen | Owner |
| P3-G004 | 02 | AUD-C2 trigger scope unresolved | POLICY DECISION REQUIRED | Yes for FS-008 codegen | Owner |
| P3-G005 | 02 | AUD-C3 SOS interaction unresolved | POLICY DECISION REQUIRED | Yes for FS-008 codegen | Owner |
| P3-G006 | 07 | AUD-C6 iOS mic support unresolved | POLICY DECISION REQUIRED | Yes for iOS NAT | Owner |
| P3-G007 | 08/02 | REP-C1 PDF export mandate unresolved | POLICY DECISION REQUIRED | Yes for FS-009 PDF plane | Owner |
| P3-G008 | 02 | REP-C2 retention edge cases unresolved | POLICY DECISION REQUIRED | Partial | Owner |
| P3-G009 | 02 | CHAT-C1 edit revision depth unresolved | POLICY DECISION REQUIRED | Yes for FS-010 edit UX | Owner |
| P3-G010 | 02/04 | CHAT-C2 audit on delete-for-all unresolved | POLICY DECISION REQUIRED | Yes for audit contract | Owner |
| P3-G011 | 06 | 18 services never on any journey | REGISTRY GAP | No | Inventory coverage |
| P3-G012 | 07 | GPS NOT_IMPLEMENTED while location UI exists | NATIVE DEPENDENCY | Yes for live locate claims | fs001.native_gps |
| P3-G013 | 07 | VPN/DNS / OS intercept / capture / wake MOCK-REMOTE | NATIVE DEPENDENCY | Yes for enforcement claims | FS-002…005 |
| P3-G014 | 08 | AI Gateway / Advisor cloud MOCK | REMOTE DEPENDENCY | Yes for live AI | Rule 26 |
| P3-G015 | 08 | SOS remote delivery MOCK-REMOTE | REMOTE DEPENDENCY | Yes for delivered SOS | FS-006 |
| P3-G016 | 01 | S-COM-050 must not reappear | CLOSED | N/A | FS-010 law |
| P3-G017 | 05 | SCR-FAT-039 tombstone retained | CLOSED | N/A | ADR-034 |
| P3-G018 | 03 | FS-010 durable message store not production-wired | DESIGN GAP | Yes for chat Local plane | Phase 2 analysis |
| P3-G019 | 03 | FS-009 report aggregation store not production-wired | DESIGN GAP | Yes for reports Local plane | Phase 2 |
| P3-G020 | 01 | Prior audit §11 copy-paste drift on some SEC Current-form labels | OUT OF SCOPE | No | Docs debt; registry names authoritative |

## Counts by class

| class | count |
|-------|------:|
| POLICY DECISION REQUIRED | 8 |
| REGISTRY GAP | 2 |
| DESIGN GAP | 3 |
| NATIVE DEPENDENCY | 2 |
| REMOTE DEPENDENCY | 2 |
| CLOSED | 2 |
| OUT OF SCOPE | 1 |

## Carry-in freeze

Phase 2 OPEN items AUD-C* / REP-C1 / CHAT-C* remain OPEN unless Owner answers mid-phase. Phase 3 **documents**; it does not resolve.
