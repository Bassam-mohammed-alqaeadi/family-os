# PHASE 1.75 — SLICE 01 ACCEPTANCE

**Date:** 2026-09-24  
**Mode:** READ/VERIFY (+ one minimal compile fix inside Slice 01)  
**Broad codegen:** NOT ARMED  
**Slice 02:** NOT STARTED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: SLICE 01 ACCEPTANCE GATE
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: MINIMAL FIX ONLY (const FamilyId → FamilyId)
```

---

## Result

### `PASS_WITH_EXPLICIT_DEBT`

Slice 01 host binds and STOR-01 restart proof are verified after a **minimal compile correction**. Explicit debts remain (Break-glass InMemory; FAT-017 Stage-1 save residual if Domain bootstrap fails). Broad Phase 1.75 codegen is **not** armed.

```text
SLICE 01 CLOSED: YES (with explicit debt)
PHASE 1.75 BROAD CODEGEN: NOT ARMED
SLICE 02: NOT STARTED
```

---

## Evidence — verification runs

Log: [`.verify/slice01_acceptance_run.txt`](../../.verify/slice01_acceptance_run.txt)

### First gate (before fix)

| Suite | Result | Exit | Detail |
|-------|--------|------|--------|
| STOR-01 `sqlite_restart_proof_test.dart` | **PASS** | 0 | 5/5 |
| n02_day FAT-015/016/017 widget tests | **FAIL** | 1 | Compile: `const FamilyId('fam_stage1')` — `const_with_non_const` in 3 screens |
| n09_smart_modes + fs005_ux_adapt | **PASS** | 0 | 6/6 |
| `test/features/n10_emergency/` | **PASS** | 0 | 27/27 |
| `dart analyze` (Slice 01 hosts) | **FAIL** | 3 | 3× `const_with_non_const` + 1× `unnecessary_import` |

**Failing cause (diagnosed):** `FamilyId` is a non-const factory; Slice 01 used `const FamilyId('fam_stage1')` in Domain bootstrap.

### Minimal correction (Slice 01 only)

- Removed invalid `const` on `FamilyId(...)` in:
  - `safe_zones_screen.dart`
  - `location_history_screen.dart`
  - `create_safe_zone_screen.dart`
- Removed unused `modes_runtime.dart` import from `child_day_board_screen.dart` (analyzer info)

No redesign, no route change, no authority invention.

### After minimal fix

| Suite | Result | Exit | Detail |
|-------|--------|------|--------|
| n02_day FAT-015/016/017 widget tests | **PASS** | 0 | **25/25** |
| `dart analyze` (4 n02 screens) | **PASS** | 0 | No issues found |

Combined with first-gate PASS suites (STOR-01, Modes, SOS emergency): **acceptance evidence green**.

**Runtime exceptions:** none reported in passing suites. STOR-01 logged expected Memory-fallback debug line when `preferSqlite: true` without binding (honesty path).

---

## Authority — OLD → NEW

### FS-001

| Host | OLD (production default) | NEW (production default) | Test inject |
|------|--------------------------|--------------------------|-------------|
| FAT-015 History | `stage1LocationHistoryRepository` | `DomainLocationHistoryRepository` ← `Stage1LocationRuntime.store` | `repository:` → InMemory |
| FAT-016 Safe Zones | `stage1SafeZonesRepository` | `DomainSafeZonesRepository` ← Domain store | `repository:` → InMemory |
| FAT-017 Create Zone | Stage-1 `_repo.add` | Domain `saveDefinition` after bootstrap | inject `repository` / `domainRepository` |
| FAT-014 Map pins | `stage1LocationMapRepository` | **Unchanged (intentional)** | — |
| FAT-014 Silent locate | Domain (pre-slice) | Domain (unchanged) | — |

**Duplicate production authority?** No second Domain store. Stage-1 singletons retained but **not** production defaults on FAT-015/016; FAT-017 uses Domain when bootstrap succeeds.

**Residual risk:** FAT-017 still initializes `_repo = stage1SafeZonesRepository` and, if `_domainRepo` is null (bootstrap failure / race before bootstrap), `else` branch still calls `_repo.add` → Stage-1. Classified as **DEBT** (not a second intentional authority).

### FS-005

| Host | OLD | NEW |
|------|-----|-----|
| FAT-085 production | Modes then **Prefs catch fallback** | Modes only (`Stage1ModesRuntime`); catch → fail closed, **no Prefs** |
| FAT-085 tests | `repository:` Prefs | Unchanged (explicit inject) |
| CHD-004 | Modes only if injected | Auto `Stage1ModesRuntime.ensureOpen` → evaluate |
| ScheduleWindow | ST Prefs on Screen Time | **Separate — untouched** (`PrefsScheduleWindowRepository` on FAT-039 path) |

**Second Modes authority?** Prefs reachable only via explicit `widget.repository` (TEST-ONLY / LEGACY). Production path does not open Prefs.

### FS-006

| Host | OLD | NEW |
|------|-----|-----|
| FAT-018 | `stage1SosAlertRepository` | `DomainSosAlertRepository(Stage1SosFinalRuntime.service)` |
| CHD-006 | Stage-1 alert repo | Domain adapter → sos_final |
| CHD-005 fire | `fireAndSeedSosAlert` → InMemory | Production: `crossSystem.fireChildHold`; inject keeps `fireAndSeedSosAlert` |
| FAT-028 ladder/settings | Prefs / Stage-1 settings | **Unchanged** |
| Break-glass sheet | `stage1SosBreakGlassStore` | **Unchanged — DEBT** |

**Fire semantics:** CHD-005 still calls `sosFire.fire` for P-4 parity after durable fire; no subscription/billing gate found on SOS screens. Location honesty empties in adapter (no invented GPS). Remote delivery remains mock/honest (capability MOCK-REMOTE; adapter does not claim FCM/SMS).

---

## Persistence — STOR-01

| Check | Evidence |
|-------|----------|
| Real SQLite? | Yes — `SqliteLocalDatabase.openAt(tempPath)` + `sqflite_common_ffi` |
| Sequence | `saveZone` → `db1.close()` → **new** `openAt(same path)` → `getZone` assert |
| Product assert | Zone name/family/assignment/geometry radius |
| Also | `kv_store` reopen; Memory intentional; preferSqlite honesty; override no false fallback |
| Memory-only tests counted as proof? | **No** — product reopen uses disk file |

Result: **PASS** (5/5, exit 0).

---

## Blast radius

### Inspected

- Host bootstraps: FAT-015/016/017, FAT-085, CHD-004, FAT-018, CHD-005/006  
- FAT-014 pin path (unchanged Stage-1)  
- ScheduleWindow host (ST, unchanged)  
- SOS break-glass default  
- `.verify/slice01_acceptance_run.txt`  
- `git status` scoped to Slice 01 areas  

### Suspicious / residual (not outside-slice implementation)

| Item | Risk | Verdict |
|------|------|---------|
| FAT-017 Stage-1 `_repo.add` if Domain null | Dual write residual | **DEBT** — document; do not expand slice |
| CHD-005 still calls `fire.fire` after sos_final | Extra Stage-1 fire audit path | Acceptable P-4 parity; not a second incident store |
| Git status shows only 5 modified Dart files vs HEAD | Other Slice 01 files already matching tree / prior land | Inspected on disk; markers present |
| Initial compile break | Gate failed until minimal fix | Fixed inside Slice 01 |

### Not found

- UI redesign / route restructuring  
- Native GPS/VPN/OS/FCM implementation  
- Backend / cloud AI  
- ScheduleWindow merged into Modes  
- Screenshot moved into DesiredMonitoring  
- DOM-ST / DOM-IDENTITY / EVT-01 / HOST-ROUTER sweep  

---

## Legacy-path audit

| Path | Class | Production-reachable? |
|------|-------|------------------------|
| `stage1SafeZonesRepository` singleton | **RETAINED / LEGACY** | FAT-016/015 defaults: **no**. FAT-017 `_repo` init + failed-bootstrap save: **yes (residual)** |
| `stage1LocationHistoryRepository` | **RETAINED / TEST-ONLY** default | Production default: **no** (inject only) |
| `stage1LocationMapRepository` | **PRODUCTION** (FAT-014 pins KEEP) | **yes** (intentional) |
| `PrefsSmartModePrefsRepository` / `stage1SmartModePrefsStore` | **TEST-ONLY / LEGACY** | Production FAT-085: **no**. Explicit `repository:`: **yes** |
| `stage1SosAlertRepository` | **RETAINED / LEGACY** | Production FAT-018/CHD-006: **no**. CHD-005 inject / helper: **yes** |
| `fireAndSeedSosAlert` | **TEST-ONLY / LEGACY** helper | Production CHD-005: **no** (sos_final path) |
| `stage1SosBreakGlassStore` | **PRODUCTION / DEBT** | FAT-018 sheet: **yes** |
| FAT-028 ladder/settings Prefs | **PRODUCTION** (out of migrate scope) | **yes** |
| Stage1 Location/Modes/SOS Final runtimes | **PRODUCTION** composition roots | **yes** |

**Nothing deleted** (per Slice 01 non-destructive rule).

---

## Remaining debt

1. **Break-glass UI store remains InMemory** (`stage1SosBreakGlassStore`) while sos_final has SQLite break-glass rows — dual surface; sheet not migrated.  
2. **FAT-017 residual Stage-1 save** when Domain bootstrap has not completed / failed.  
3. **CHD-005** dual fire call (`fireChildHold` + `SosFireService.fire`) — Stage-1 fire log parity, not second incident authority.  
4. **Restart proof** is automated on FFI temp DB — not yet a device-document-path APK soak (out of Slice 01).  

---

## Regression check

| Concern | Status |
|---------|--------|
| UI redesign | Not done |
| Routes restructured | Not done |
| UX structure rewrite | Not done |
| Native capabilities | Unchanged |
| Remote/backend | Unchanged |
| Cloud AI | Unchanged |
| Unrelated domains (ST ScheduleWindow, etc.) | Untouched |

---

## Scope confirmation

```text
SLICE 01 CLOSED: YES (PASS_WITH_EXPLICIT_DEBT)
PHASE 1.75 BROAD CODEGEN: NOT ARMED
SLICE 02: NOT STARTED
```

**HARD STOP** — do not begin Slice 02 until Owner accepts this gate (and optionally prioritizes Break-glass / FAT-017 residual DEBT).
