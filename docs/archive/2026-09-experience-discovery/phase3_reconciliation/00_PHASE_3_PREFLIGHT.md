# PHASE 3 — Preflight (00)

**Date:** 2026-09-25  
**Mode:** READ-ONLY  
**Production code:** NO  

```
CURRENT PHASE: PHASE 3
TASK PHASE: PHASE 3
STATUS: ALIGNED
REQUIRED GATE: Owner CHANGE PHASE (satisfied 2026-09-25)
WILL MODIFY PRODUCTION CODE: NO
```

## 1. Prior-phase evidence (must be COMPLETE)

| Phase | Evidence path | Status |
|-------|---------------|--------|
| 1.75 Local foundations | `docs/experience_discovery/PHASE_1_75_*` + `.verify/PHASE-1.75-COMPLETE.json` | COMPLETE |
| 2 FS-008→010 analysis | `PHASE_2_ACCEPTANCE.md`, `PHASE_2_CROSS_FS_RECONCILIATION.md`, `fs008_*` / `fs009_*` / `fs010_*` | COMPLETE |
| 3 (this) | `phase3_reconciliation/` | ACTIVE |

## 2. Inventory counts (read-only extract)

Source: `family-os/_REGISTRY/{services,journeys,screens}.csv` via `.verify/_p3_extract.py`.

| Artifact | Count | Expected |
|----------|------:|----------|
| Services | 240 | 240 |
| Systems `(domain, subsystem_letter)` | 42 | 42 |
| Journeys | 73 | 73 |
| Screen rows | 130 | 130 (129 live + SCR-FAT-039 tombstone) |

Integrity spot-checks (extract):

| Check | Result |
|-------|--------|
| Broken journey→service refs | 0 |
| Screen→unknown service | 0 |
| Screen→unknown journey | 0 |
| Screens with empty services | 0 |
| Screens with empty journey | 0 |
| `S-PAR-030` in CSV | False → **REGISTRY GAP** (AUD-C7) |
| `S-COM-050` in CSV | False → **CLOSED** (must not reappear) |
| Tombstone | ['SCR-FAT-039'] |

Registry scripts (`validate.py`, `check_consistency.py`) may be run as **reports only** — do not invent product law to silence findings.

## 3. FS pack locations

| FS | Title | Pack root |
|----|-------|-----------|
| FS-001 | Location | `*_l2` / location packs under `docs/experience_discovery/` |
| FS-002 | Web Filter | `web_filtering_discovery/` |
| FS-003 | App Control | `application_control_discovery/` |
| FS-004 | Screen/Camera | `screen_camera_discovery/` |
| FS-005 | Modes | `modes_discovery/` |
| FS-006 | SOS | `sos_discovery/` / `sos_final/` |
| FS-007 | Offline AI Safety | `offline_ai_safety_discovery/` |
| FS-008 | One-Way Audio | `fs008_one_way_audio/` |
| FS-009 | PDF Activity Reports | `fs009_pdf_activity_reports/` |
| FS-010 | Ephemeral Family Chat | `fs010_ephemeral_family_chat/` (or sibling fs010_*) |

## 4. OPEN carry-ins from Phase 2 (do not invent resolutions)

| ID | Class | Notes |
|----|-------|-------|
| AUD-C1 | POLICY DECISION REQUIRED | 60s vs 10 min clip |
| AUD-C2 | POLICY DECISION REQUIRED | Reason-anytime vs SOS/zone-only |
| AUD-C3 | POLICY DECISION REQUIRED | SOS interaction nuance |
| AUD-C6 | POLICY DECISION REQUIRED | iOS support |
| AUD-C7 | REGISTRY GAP | Insert S-PAR-030 + SCR/JRN |
| REP-C1 | POLICY DECISION REQUIRED | PDF export mandate |
| REP-C2 | POLICY DECISION REQUIRED | Retention edge cases |
| CHAT-C1 | POLICY DECISION REQUIRED | Edit revision depth |
| CHAT-C2 | POLICY DECISION REQUIRED | Audit on delete-for-all |
| CHAT-C3 | OUT OF SCOPE | Message SQLite schema (implementation) |
| S-COM-050 | CLOSED | Disappearing chat deleted; FS-010 must not revive |

## 5. Classification taxonomy (mandatory)

Every finding uses exactly one of:

`CLOSED` · `VERIFIED EXISTING` · `DESIGN GAP` · `POLICY DECISION REQUIRED` · `REGISTRY GAP` · `NATIVE DEPENDENCY` · `REMOTE DEPENDENCY` · `OUT OF SCOPE`

## 6. Map schemas (columns)

### 01 System Map
`system_key` · `subsystem_name` · `service_count` · `service_ids` · `fs_or_domain` · `owner_fact` · `class`

### 02 Domain/Policy Ownership
`fact` · `policy_register_ref` · `owning_domain_or_fs` · `must_not_own` · `class`

### 03 Data Ownership
`entity_or_store` · `namespace` · `runtime_honesty` · `owner` · `consumers` · `class`

### 04 Event/Contract
`channel_or_event` · `producer` · `consumer` · `delivery_claim` · `class`

### 05 Screen Map
`screen_id` · `journey` · `services` · `owner_system` · `notes` · `class`

### 06 Journey Integrity
`journey_id` · `services` · `screens_covering` · `integrity` · `class`

### 07 Native Capability
`capability` · `registry_id` · `honesty_state` · `fs_touch` · `class`

### 08 Backend Capability
`capability` · `honesty_state` · `rule_26_seam` · `class`

### 09 Dependency Graph
`edge_id` · `owner` · `fact` · `consumer` · `interpretation` · `class`

### 10 Gap Register
`gap_id` · `source_map` · `summary` · `class` · `blocks_phase4_planning` · `notes`

## 7. Explicit non-goals

- No Flutter/Dart production changes  
- No NAT / REM / Backend / codegen  
- No Phase 4 Master Implementation Plan  
- No “fixing” OPEN Phase 2 items without Owner answers  

## 8. Preflight acceptance

Inventory counts match expected · schemas locked · OPEN carry-ins listed · prior phases evidenced → **ACCEPT** → proceed to map 01.
