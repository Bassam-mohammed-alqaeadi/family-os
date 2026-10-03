# PHASE 1.75 — SLICE 01 PREFLIGHT

**Date:** 2026-09-24  
**Authority:** Owner Slice 01 authorization (controlled execution)  
**WILL MODIFY PRODUCTION CODE:** YES (scoped)  
**Broad Phase 1.75 codegen:** NOT ARMED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: PHASE 1.75 — SLICE 01
STATUS: ALIGNED
REQUIRED GATE: This preflight
WILL MODIFY PRODUCTION CODE: YES
```

---

## Owner decision resolution (this slice)

Integrity OD-B / OD-C were open. **Owner Slice 01 authorization** resolves them for scoped hosts only:

| OD | Resolution via Slice 01 |
|----|-------------------------|
| **OD-B** | Mandate Domain default on FAT-015/016/017 (trail + zones). FAT-014 decorative pins remain Stage-1 (KEEP); Domain silent locate already wired. |
| **OD-C** | ModesService is production Modes authority on FAT-085; Prefs fallback removed from production path; Prefs remains via explicit `repository:` inject (tests). |
| **OD-D** | **Not changed** — ScheduleWindow stays Screen Time; no merge into Modes. |
| Screenshot / DesiredMonitoring | **Not touched** (C-08). |
| SOS entitlement / Location→SOS | **Not altered** — bind host to existing `sos_final` only. |

Recorded in `QUESTIONS.md` as `Q-P175-SLICE01`.

---

## Workstream impact matrix

### STOR-01 — SQLite restart proof

| Field | Detail |
|-------|--------|
| Current authority | `SqliteLocalDatabase` + `FsSessionKernel` |
| Target | Evidence only — no redesign |
| Consumers | All Local*Stores |
| Producers | Schema v10 migrations |
| Fallback | `sqliteFallbackToMemory` on open failure |
| Tests | New `sqlite_restart_proof_test.dart` (FFI temp file) |
| Routes | None |
| Cross-domain | None |
| Native/remote | None |
| Outside-slice break risk | **LOW** — tests only + optional honesty asserts |

### AUTH-FS001 — Domain zones/history hosts

| Screen | Current | Target | Consumers | Producers | Fallback after change |
|--------|---------|--------|-----------|-----------|------------------------|
| FAT-016 | `stage1SafeZonesRepository` | `DomainSafeZonesRepository` after `Stage1LocationRuntime.ensureOpen` | Router, Create CTA | Domain `saveZone` / list | Injected `repository:` for tests; Stage-1 singleton **kept** (legacy, not production default) |
| FAT-017 | Stage-1 `add` | Domain `saveDefinition` via state-held Domain repo | Router, FAT-016 | Domain geometry | Injected repos for tests |
| FAT-015 | `stage1LocationHistoryRepository` | `DomainLocationHistoryRepository` | Router, Map CTA | Domain trail | Injected `repository:` |
| FAT-014 | Hybrid | **No pin authority change** | — | Silent locate already Domain | Pins Stage-1 KEEP |

| Risk | Mitigation |
|------|------------|
| Partial bind (create Domain / list Stage-1) | Bind 016+017+015 together |
| Empty Domain list after bind | Expected until zones saved; KEEP empty UI |
| History `null` vs empty | Domain never returns null — empty days UI (document behavior) |
| Tests | All inject InMemory — **low risk** if inject seam preserved |
| Child roster | Not required for Domain open; assignment uses route `childId` |

**BLOCKED_BY_AUTHORITY residual:** None for scoped hosts after Owner OD-B resolution. FAT-014 pin Domain migration **out of slice**.

### AUTH-FS005 — Modes production authority

| Surface | Current | Target |
|---------|---------|--------|
| FAT-085 production | Modes then Prefs catch fallback | Modes only; catch → fail closed (no Prefs) |
| FAT-085 tests | `repository:` forces Prefs | **Unchanged** |
| CHD-004 | `modes == null` → no disclosure | Auto `Stage1ModesRuntime.ensureOpen` when modes unset |
| ScheduleWindow | ST Prefs | **Untouched** |

| Risk | Mitigation |
|------|------------|
| ensureOpen failure | No Prefs masquerade; Modes UI idle / guards on null service |
| SET-018 Prefs tests | Explicit `repository:` still forces Prefs branch |
| ST `modeActive` overlap | Documented residual; OD-D not in slice |

**BLOCKED_BY_AUTHORITY residual:** None for Modes-only after Owner OD-C. ScheduleWindow merge **blocked** (not attempted).

### AUTH-FS006 — SOS → sos_final

| Surface | Current | Target |
|---------|---------|--------|
| FAT-018 / CHD-006 | `stage1SosAlertRepository` | `DomainSosAlertRepository` → `SosFinalService` |
| CHD-005 fire | `fireAndSeedSosAlert` → InMemory | `crossSystem.fireChildHold` when no inject |
| FAT-028 | Ladder/settings Prefs | **Unchanged** |
| Break-glass sheet | InMemory store | **Unchanged** this slice (lifecycle BG stays UI store; sos_final BG rows exist but sheet not migrated — document DEBT) |

| Risk | Mitigation |
|------|------------|
| API mismatch SosAlert vs SosIncident | Adapter maps with honest empty movement/accuracy; no fake GPS |
| Tests | Inject InMemory — keep seam |
| Claiming FCM/SMS | Capability MOCK-REMOTE unchanged |
| fireAndSeed typed to InMemory | Production path bypasses helper; helper kept for tests |

**BLOCKED_BY_AUTHORITY residual:** None for local lifecycle bind. Break-glass sheet dual path = **documented debt**, not invented policy.

---

## Explicitly out of slice (do not touch)

DOM-ST · DOM-IDENTITY · EVT-01 · HOST-ROUTER sweep · mass CONVERT · Native · Remote · Backend · Cloud AI · FS-008→010 · Blueprint recreate · ScheduleWindow→Modes · screenshot→DesiredMonitoring · demo seed

---

## Outside-slice break checklist

| Area | Could break? | Why / guard |
|------|--------------|-------------|
| Widget tests with inject | No | Seams retained |
| Router type checks | No | Same screen types |
| Prefs Smart Modes unit tests | No | Explicit repository |
| SOS ladder/setup tests | No | Untouched |
| Phase15 Memory kernel tests | No | STOR-01 uses separate FFI files |
| Capability honesty | No | Statuses unchanged or stricter messaging only |
| GPS / VPN / FCM claims | No | Not implemented |

---

## Proceed / stop rules

| Workstream | Proceed? |
|------------|----------|
| STOR-01 | YES |
| AUTH-FS001 | YES (Owner OD-B) |
| AUTH-FS005 | YES (Owner OD-C); ScheduleWindow NO |
| AUTH-FS006 | YES (adapter + host bind); BG sheet dual DEBT |
| Any new ambiguous OD | STOP that sub-change as `BLOCKED_BY_AUTHORITY` |

**PREFLIGHT COMPLETE — implementation may proceed under these constraints.**
