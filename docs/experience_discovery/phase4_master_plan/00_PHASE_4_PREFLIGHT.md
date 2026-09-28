# PHASE 4 — Preflight / Master Plan Discovery (00)

**Date:** 2026-09-25  
**Mode:** READ-ONLY PLANNING  
**Production code:** NO  

```
CURRENT PHASE: PHASE 4
TASK PHASE: PHASE 4
STATUS: ALIGNED
REQUIRED GATE: Owner CHANGE PHASE (satisfied 2026-09-25)
WILL MODIFY PRODUCTION CODE: NO
```

## 1. Prior-phase evidence (required COMPLETE)

| Phase | Evidence | Status |
|-------|----------|--------|
| 1.75 Local runtime | `PHASE_1_75_LANE_ACCEPTANCE.md` + `.verify/PHASE-1.75-*` | COMPLETE |
| 2 FS-008→010 analysis | `PHASE_2_ACCEPTANCE.md` + `fs008_*`/`fs009_*`/`fs010_*` | COMPLETE |
| 3 Global reconciliation | `PHASE_3_ACCEPTANCE.md` + `phase3_reconciliation/00–10` | COMPLETE |

## 2. Inventory baseline (Phase 3 extract)

| Artifact | Count |
|----------|------:|
| Services | 240 |
| Systems | 42 |
| Journeys | 73 |
| Screen rows | 130 |

## 3. Authoritative inputs locked

- Roadmap: `PROJECT_EXECUTION_PLAN.md` § PHASE 4–5  
- Policy: `handoff/04_POLICY_REGISTER_EN.md`  
- Phase 3 maps 01–09 + gap register  
- Phase 1.75 runtime: `FsCompositionRuntime`, Identity, ST, Prefs-misc, Events, EDU local, SOS, Audit  
- Capability honesty: GPS/VPN/OS intercept/capture/wake/FCM = NOT_IMPLEMENTED or MOCK-REMOTE  

## 4. Readiness taxonomy (mandatory)

Every planned unit uses exactly one:

| Code | Meaning |
|------|---------|
| `READY FOR IMPLEMENTATION` | Dependency chain evidenced for a **future** Local (or clearly scoped) implementation wave — **not** authorization to code now |
| `BLOCKED BY POLICY` | Missing Owner policy / OPEN decision |
| `BLOCKED BY ARCHITECTURE` | Authority/architecture contradiction |
| `BLOCKED BY NATIVE` | Requires Native plane not yet authorized |
| `BLOCKED BY REMOTE` | Requires Remote/backend / AI Gateway |
| `OUT OF SCOPE` | Explicitly out of current product planning scope |
| `DEFERRED` | In product inventory but sequenced after prerequisites |

**No fake readiness:** screen UI, mock repo, or design doc alone ≠ READY.

## 5. OPEN carry-ins that constrain the Master Plan

| ID | Blocks | Effect on plan |
|----|--------|----------------|
| AUD-C1/C2/C3/C6/C7 | FS-008 | POLICY_GATE before any Audio Local/NAT |
| REP-C1/C2 | FS-009 PDF/retention | POLICY_GATE for PDF/export plane |
| CHAT-C1/C2 | FS-010 edit/delete audit | POLICY_GATE for those contracts; durable Local store may still be planned as gated slice |
| P3-G011 | 18 journey orphans | Inventory debt — track, do not invent journeys |
| P3-G012–G015 | NAT/REM | Wave 5–7 gates |
| S-COM-050 | — | CLOSED — must never reappear |

## 6. Architecture preserve law

- Keep approved Domain owners from Phase 3 map 02–03.  
- Do not redesign frozen UX to simplify sequencing.  
- Do not create duplicate authorities.  
- Work with `FsSessionKernel` / composition / Local event journal as foundation.  
- Phase 5 wave labels from roadmap are **strategy hints**, not a license to start Phase 5.

## 7. Explicit non-goals (this phase)

- No Flutter/Dart production changes  
- No NAT / REM / Backend / full codegen  
- No auto-advance to Phase 5  

## 8. Preflight acceptance

Prior phases COMPLETE · inventory locked · taxonomy locked · OPEN carry-ins visible · architecture preserve asserted → **ACCEPT** → discovery / readiness matrix.
