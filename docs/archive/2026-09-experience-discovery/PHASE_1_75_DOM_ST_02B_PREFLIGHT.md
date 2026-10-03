# PHASE 1.75 — DOM-ST-02B PREFLIGHT (ScheduleWindow Production Binding)

**Date:** 2026-09-24  
**Task:** DOM-ST-02B — ScheduleWindow Production Binding  
**Status:** PREFLIGHT ONLY — implementation **NOT AUTHORIZED**  
**Broad codegen:** NOT ARMED  

**Closed behind this card:** Slice 01 · Slice 01.1 · Slice 02-A · DOM-ST-01 · DOM-ST-02A · DOM-ST-02A.1  

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST-02B PREFLIGHT
STATUS: ALIGNED
REQUIRED GATE: separate implementation authorization after this preflight
WILL MODIFY PRODUCTION CODE: NO (this document only)
```

---

## 1. Current production path

### End-to-end (today)

```text
SCR-FAT-032 ChildScreenTimeScreen
  repository == null
    → PrefsScheduleWindowRepository(stage1SchedulePrefsStore)   // initState, sync
         → MemorySchedulePrefsStore (process RAM Map)
              key: schedule_windows:{childId}
              value: JSON array of ScheduleWindow.toJson()

  policyRepository == null
    → FsSessionKernel.ensureOpen()
    → refuse if sqliteFallbackToMemory (DOM-ST-02A.1)
    → ScreenTimeLocalPersistence.policyRepository(FsSessionKernel.db)
         → LocalScreenTimeKvPrefsStore(ns=st_policy) → kv_store
```

**ScheduleWindow is still Memory Prefs in production.** Policy is already Local KV / SQLite.

### Contract stack (already exists — unused by FAT-032 production)

```text
ScheduleWindowRepository (abstract)
  └─ PrefsScheduleWindowRepository(SchedulePrefsStore)
       ├─ MemorySchedulePrefsStore          ← PRODUCTION today (stage1SchedulePrefsStore)
       └─ LocalScreenTimeKvPrefsStore       ← DOM-ST-01 foundation (ready, not bound)
            namespace: ScreenTimeKvNamespaces.schedule == 'st_schedule'
            → FamilyLocalDatabase.kv_store
```

Factory already present:

`ScreenTimeLocalPersistence.scheduleRepository(FamilyLocalDatabase db)`  
→ `PrefsScheduleWindowRepository(LocalScreenTimeKvPrefsStore(db, namespace: st_schedule))`

There is **no** `openScheduleRepository()` yet (policy has `openPolicyRepository()` with honesty guard).

### Producers (write ScheduleWindow)

| Producer | Path today |
|----------|------------|
| FAT-032 `_save()` | `_repository.save` → Memory Prefs |
| FAT-032 toggle/pick | In-widget state only until save |

No other production writers of `ScheduleWindowRepository` found. Earn / wallet / Quran / attribution write **policy** only.

### Consumers (read / observe)

| Consumer | Relationship |
|----------|----------------|
| FAT-032 `_load()` | Reads `_repository` (Memory Prefs) |
| `PolicySyncBus` | Receives schedule list from FAT-032 after save — **in-process only**, not durable |
| `ChildScreenTimeMirror` | Watches bus mirror (schedules in mirror payload) — **not** repo |
| `ScheduleWindowQuery` | Pure helpers over `ScheduleSnapshot` — **no store**; used in unit tests → TimeEngine |
| `TimeEngine` | Consumes `TimeContext.modeActive` if a caller builds context via Query — **no production FAT-085 / Modes wiring** |
| `ScreenTimePolicyQuery` | Passes through `base.modeActive` — does not load ScheduleWindow |

### Injection / bootstrap seams

| Seam | Role |
|------|------|
| `ChildScreenTimeScreen.repository` | Explicit inject → skip Memory default (tests) |
| `stage1SchedulePrefsStore` | Process-global Memory Map |
| `InMemoryScheduleWindowRepository` | TEST-ONLY pure map |
| `MemorySchedulePrefsStore(shared map)` | TEST “restart” across repo instances (not SQLite) |
| `ScreenTimeLocalPersistence.scheduleRepository(db)` | Foundation seam — tests prove SQLite reopen |

### Modes path (separate — must stay untouched)

```text
SCR-FAT-085 / CHD-004
  → Stage1ModesRuntime / ModesService
  → mode_document / mode_activation / mode_exception
  → ModesEngine (sole Modes modeActive authority)
```

`n09_smart_modes/*` has **zero** imports of `ScheduleWindow` / `schedule_window*`.

---

## 2. ScheduleWindow ownership

| Claim | Evidence |
|-------|----------|
| **ScheduleWindow = Screen Time-owned** | FAT-032 SET-001 host; `ScreenTimeKvNamespaces.schedule`; OD-D / AUTH-FS005 / MODE-OD-06 |
| Kinds | `sleep` · `prayer` · `study` only (`ScheduleKind`) |
| Semantics | Same-day window; `end > start` when enabled; seed defaults on first enable |
| **Not Modes-owned** | Must not persist via `mode_document` / `mode_activation` / `mode_exception` |
| Minutes stay ST | Caps / wallets / grants = policy path (already DOM-ST-02A) |

**No ownership conflict for this persistence migration.** Binding ScheduleWindow into `st_schedule` / `kv_store` preserves ST ownership and does **not** move lifestyle Mode scheduling to Modes tables.

---

## 3. Serialization / storage audit

### Current (Memory Prefs)

| Aspect | Behavior |
|--------|----------|
| Key | `schedule_windows:{childId.value}` |
| Value | `jsonEncode(windows.map(toJson))` — one blob per child |
| Shape per window | `{ kind, enabled, startMinutes, endMinutes }` |
| Missing key / empty | `_emptySet()` → three kinds, all `enabled: false` |
| Malformed (non-List JSON) | `_emptySet()` |
| Bad item (non-Map) | Skipped |
| Unknown `kind` string | `fromJson` → `ScheduleKind.sleep` (`orElse`) |
| Missing kinds in list | Filled with disabled stubs for all `ScheduleKind.values` |
| Enabled + unset times | UI seeds via `ScheduleWindowDefaults.seedOnEnable` before save |
| Same-day rule | `isValid` / `contains` — no overnight wrap in Stage-1 |

### Target (Local KV — already proven at foundation)

| Aspect | Behavior |
|--------|----------|
| Namespace | `st_schedule` |
| Key | **Same** `schedule_windows:{childId}` |
| Value | **Same** JSON string (Prefs shape preserved) |
| Store | `LocalScreenTimeKvPrefsStore` → `kv_store` rows |
| Schema DDL | **None** — `kv_store` already in FamilyLocalSchema v10 |
| Data migration | **None** — Memory Prefs was process-RAM only; fresh SQLite starts empty → defaults |

**Do not invent a new ScheduleWindow schema.** Reuse `PrefsScheduleWindowRepository` + existing JSON.

DOM-ST-01 already proved SQLite write→close→reopen for ScheduleWindow (`screen_time_local_persistence_restart_proof_test`).

---

## 4. Modes boundary proof

### `ScheduleWindowQuery.timeContextFromSchedules`

```text
ScheduleSnapshot + now
  → activeBuiltInMode (sleep > prayer > study priority)
  → TimeContext(modeActive: true) when a window is active
  → TimeEngine may denyMode
```

**Classification:** Legacy Stage-1 **TimeContext / evaluation bridge** for ST windows → TimeEngine.  
**Not** Modes persistence. **Not** FAT-085 production path.

| Check | Result |
|-------|--------|
| Production FAT-085 depends on ScheduleWindow? | **No** — zero feature imports |
| ModesEngine sole Modes `modeActive` authority? | **Yes** — explicit comment + Modes tables |
| DOM-ST-02B creates second Modes authority? | **No** — storage bind only; Query untouched |
| Screen Time storage change alters Modes behavior? | **No** — Modes reads `mode_*`, not `st_schedule` |

**Open implementation debt (out of scope for 02B):** Stage-1 Query can still set `TimeContext.modeActive` for callers that use it (unit tests). Owner law (MODE-OD-06 / T-MODE-01) treats this as **non-authority residual**, not a reason to merge ScheduleWindow into Modes storage. **Do not modify this bridge in DOM-ST-02B.**

**Authority verdict for Modes boundary:** **CLEAR** — not `BLOCKED_BY_AUTHORITY`.

---

## 5. Failure / fallback behavior

### Kernel path (unchanged — do not redesign)

```text
FsSessionKernel.ensureOpen(preferSqlite: true)
  → SqliteLocalDatabase.openDefault() throws
  → MemoryLocalDatabase + sqliteFallbackToMemory = true
  → ensureOpen still succeeds (does not throw)
```

### Policy precedent (DOM-ST-02A.1) — **must mirror for ScheduleWindow**

Screen Time Policy **refuses** production bind when `FsSessionKernel.sqliteFallbackToMemory`.

**Equivalent required for ScheduleWindow:**

| Session | ScheduleWindow bind |
|---------|---------------------|
| Healthy SQLite (`usingSqlite`, flag false) | Bind `scheduleRepository(FsSessionKernel.db)` — restart-safe |
| SQLite→Memory fallback (`sqliteFallbackToMemory`) | **Refuse** — do **not** treat as production-persistent |
| Intentional test Memory (`preferSqlite: false`, flag false) | Allowed for FLUTTER_TEST / explicit inject |
| Explicit `repository:` inject | Unchanged test seam |

**Forbidden:** Silent bind of ScheduleWindow to `MemoryLocalDatabase` when the session is degraded, then present as durable.  
**Forbidden:** Fall back to `stage1SchedulePrefsStore` / `MemorySchedulePrefsStore` on open failure.  
**Allowed globally:** Kernel Memory fallback for other FS domains (Modes, WF, …) — do **not** remove `MemoryLocalDatabase`.

### FAT-032 coupling note

Today `_canSave` already requires `_canSavePolicy` (policy repo present + not unavailable). Schedule save is already gated with policy. After 02B, both should open from the **same** honesty-checked session so they fail closed together. Prefer extending the existing bootstrap / BannerNote path rather than inventing a second UX authority.

---

## 6. Cross-domain blast radius

| Domain | Impact of ScheduleWindow Local KV bind |
|--------|----------------------------------------|
| **FAT-032** | **In scope** — production default repository swap + honesty |
| **TimeEngine** | No change if Query / callers unchanged |
| **ScreenTimePolicyQuery** | No change (policy path already 02A) |
| **PolicySyncBus** | Unchanged — still process-memory events after save |
| **ChildTimeMirror** | Unchanged — bus only; **not** durable schedule store |
| **Modes / FAT-085** | Untouched |
| **App Control** | Untouched |
| **Wallet / Earn** | Untouched (policy `openPolicyRepository` only) |
| **Reports / Focus** | Untouched (`FocusScheduleItem` ≠ ST ScheduleWindow) |
| **TimeRequest / Grant** | **Out of scope** (DOM-ST-02C) |
| **AppAccess ST axes** | Out of scope |
| **Native / Backend / Remote** | Out of scope |

---

## 7. Exact proposed binding

### Smallest safe bind (implementation plan — **not authorized yet**)

1. **Add** `ScreenTimeLocalPersistence.openScheduleRepository()`  
   - Mirror `openPolicyRepository()`: `ensureOpen` → refuse if `sqliteFallbackToMemory` → `scheduleRepository(FsSessionKernel.db)`.

2. **FAT-032** (`child_screen_time_screen.dart`):  
   - When `widget.repository == null`, **stop** sync-constructing `PrefsScheduleWindowRepository(stage1SchedulePrefsStore)`.  
   - Async bootstrap (same session as policy): after honesty check, set schedule repo from `ScreenTimeLocalPersistence.scheduleRepository(FsSessionKernel.db)`.  
   - On failure / fallback refuse: fail-closed (no Memory Prefs); reuse or extend existing unavailable banner / save disable.  
   - When `widget.repository != null`: keep explicit inject (tests).

3. **Do not** rebind: TimeRequest, PolicySyncBus durability, child mirror persistence, Modes, earn writers.

4. **Do not** change: `ScheduleWindow` model, JSON shape, `ScheduleWindowQuery`, TimeEngine, ModesEngine.

5. **Files expected (implementation):**

| File | Change |
|------|--------|
| `app/lib/core/screen_time/screen_time_local_persistence.dart` | `openScheduleRepository()` + honesty |
| `app/lib/features/n03_screen_time/child_screen_time_screen.dart` | Production default bind + fail-closed |
| New/focused tests under `app/test/core/screen_time/` | Bind + restart + honesty |

### Consumers that remain Memory (temporary / intentional)

| Symbol | After 02B |
|--------|-----------|
| `stage1SchedulePrefsStore` / `MemorySchedulePrefsStore` | LEGACY / RETAINED — not production FAT-032 |
| Explicit `repository:` | TEST-ONLY |
| `InMemoryScheduleWindowRepository` | TEST-ONLY |
| PolicySyncBus schedule payloads | Process memory (unchanged; not this card’s durability) |
| TimeRequest Prefs | Memory until DOM-ST-02C |

### FAT-032 fail-closed

Yes — same pattern as policy: if Local KV / honesty fails, schedules must **not** silently persist to process Memory while UI implies durable save. Existing `_canSave` ↔ policy coupling is a useful gate; schedule unavailability must not leave a Memory production path alive.

---

## 8. Tests and restart proof required

### Must count as persistence proof

```text
write ScheduleWindow set
  → close DB / reset session
  → reopen DB / ensureOpen
  → read
  → exact assertions
```

Required assertions:

| Assertion | Required |
|-----------|----------|
| Child identity | Yes |
| Sleep enabled + start/end | Yes |
| Prayer enabled/disabled + times if set | Yes |
| Study enabled + start/end | Yes |
| Disabled kinds remain disabled | Yes |

**Memory-map “restart”** (`schedule_window_test` shared Map) is **not** sufficient for production bind proof.

### Suites to add / extend at implementation

| Proof | Notes |
|-------|--------|
| `openScheduleRepository` write→close→reopen | Parallel to `dom_st02a_policy_bind_restart_proof_test` |
| Honesty: refuse `sqliteFallbackToMemory` | Parallel to `dom_st02a1_persistence_honesty_test` |
| Intentional test Memory still allowed | `preferSqlite: false`, flag false |
| FAT-032 widget tests | Explicit inject unchanged; default path if testable |
| Existing DOM-ST-01 schedule reopen | Still green (foundation) |

Analyzer on touched files; scoped verify_ship when implementation is authorized.

---

## 9. Legacy retirement conditions

| Symbol | After 02B ship (when authorized) | Retire when |
|--------|----------------------------------|-------------|
| `MemorySchedulePrefsStore` | **RETAINED** (do not delete) | All intended producers proven off Memory **and** owner authorizes delete |
| `stage1SchedulePrefsStore` | **LEGACY / RETAINED** — not FAT-032 production | Same |
| `PrefsScheduleWindowRepository` | **PRODUCTION** (adapter reused on Local KV) | Never retire for this card |
| `InMemoryScheduleWindowRepository` | **TEST-ONLY** | Keep |
| `ScheduleWindowQuery` | **LEGACY evaluation bridge** (DEBT vs Modes law) | Separate Modes/TimeEngine reconciliation card — **not** 02B |
| `LocalScreenTimeKvPrefsStore` + `st_schedule` | **PRODUCTION** foundation | — |

**Do not delete** `MemorySchedulePrefsStore` or `stage1SchedulePrefsStore` in DOM-ST-02B.

Reachability after successful bind:

| Path | Class |
|------|--------|
| FAT-032 null → Local KV / SQLite | **PRODUCTION** |
| Explicit inject / InMemory | **TEST-ONLY** |
| `stage1SchedulePrefsStore` if no longer referenced by production default | **LEGACY** / **RETAINED** / residual **DEBT** until deleted under a later card |

---

## 10. Final verdict

### `READY_WITH_EXPLICIT_HONESTY_GUARD`

| Gate | Status |
|------|--------|
| Ownership (ST vs Modes) | Clear — ST owns ScheduleWindow persistence |
| Architecture (FsSessionKernel + Local KV) | Clear — foundation exists; no schema bump |
| Modes second-authority risk from this bind | Clear — storage only; Query/Modes untouched |
| Silent Memory misrepresentation | **Guard required** — mirror DOM-ST-02A.1 using `sqliteFallbackToMemory` |
| Scope creep | Bound — ScheduleWindow only; not 02C / Modes / TimeEngine redesign |

**Not** `BLOCKED_BY_AUTHORITY` — FAT-085 / ModesEngine evidence is clean for a persistence-only bind.  
**Not** `BLOCKED_BY_ARCHITECTURE` — `scheduleRepository(db)` + `kv_store` / `st_schedule` already ship from DOM-ST-01.  
**Not** bare `READY_FOR_IMPLEMENTATION` without honesty — degraded Memory session must fail closed for ScheduleWindow exactly as for Policy.

---

## HARD STOP

```text
PREFLIGHT COMPLETE
DOM-ST-02B IMPLEMENTATION: NOT AUTHORIZED
DOM-ST-02C: NOT STARTED
PHASE 1.75 BROAD CODEGEN: NOT ARMED
```

Do **not** modify production code, SQLite schema, Modes, TimeEngine semantics, or ScheduleWindowQuery until a **separate** implementation authorization is issued.
