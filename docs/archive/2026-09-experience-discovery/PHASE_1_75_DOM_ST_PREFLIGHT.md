# PHASE 1.75 — DOM-ST PREFLIGHT (Screen Time Local Persistence)

**Date:** 2026-09-24  
**Task:** DOM-ST PREFLIGHT ONLY  
**Mode:** READ / ANALYZE — no production code modified  
**Slice 02-A:** CLOSED  
**DOM-ST implementation:** NOT AUTHORIZED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: DOM-ST PREFLIGHT
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: NO
```

---

## 1. Current architecture

### Production path (FAT-032 / SET-001 / SET-002)

```text
UI: ChildScreenTimeScreen (SCR-FAT-032)
  ├─ ScheduleWindowRepository
  │    └─ PrefsScheduleWindowRepository(stage1SchedulePrefsStore)
  │         └─ MemorySchedulePrefsStore  → process RAM Map
  │              key: schedule_windows:{childId}
  ├─ ScreenTimePolicyRepository
  │    └─ PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore)
  │         └─ MemoryScreenTimePolicyPrefsStore → process RAM Map
  │              key: screen_time_policy:{childId}
  └─ TimeRequestService
       └─ PrefsTimeRequestRepository(stage1TimeRequestPrefsStore)
            └─ MemoryTimeRequestPrefsStore → process RAM Map
                 keys: time_requests · time_grants
```

**No Stage1 Screen Time Runtime.** Unlike FS-001…007 Domain runtimes, ST has no `Stage1ScreenTimeRuntime`, no `LocalScreenTime*Store`, and **no SQLite tables** for ST policy / schedules / requests (`local_database.dart` schema through v10 has `mode_*`, `wf_*`, `ac_*`, `loc_*`, `sos_*`, `ai_*` — **zero `st_*`**).

### Adjacent ST / AC surfaces

| Surface | Path | Persistence |
|---------|------|-------------|
| SCR-FAT-034 Child Apps (Allow/Block + Unlimited) | `ChildAppsRepository` → `PrefsAppAccessRulesRepository(stage1AppAccessRulesStore)` + Domain AC for permanent block | Memory Prefs for ST axes; SQLite `ac_document` for AC dispositions |
| SCR-FAT-033 Request Inbox | `TimeRequestService` → Prefs time requests | Memory Prefs |
| SCR-CHD-020 Child time request | `stage1TimeRequestService` / `ServiceChildTimeRequestRepository` | Memory Prefs |
| SCR-CHD-021 Time expiry | reads TimeEngine / policy context | No dedicated store |
| Child time mirror | `PolicySyncBus` in-process mirror | Process memory |
| Usage report / apps list | mock / projection repos | Mock |
| Earn → wallet (Studio / Quran / child wallet) | `WalletLedger` / `PolicyEngine.earn` → `PrefsScreenTimePolicyRepository(stage1PolicyPrefsStore)` | Memory Prefs (same policy Map) |
| SCR-FAT-035 New app approval | `AppControlUxBridge` → FS-003 install tickets | AC Domain (not ST Prefs) |
| SCR-FAT-069 Usage report | `InMemoryChildUsageReportRepository` | **Mock fixture only** |
| SCR-CHD-019 Child wallet | Reads/writes ST policy prefs | Memory Prefs |
| SCR-FAT-037 Instant lock | Feeds `TimeContext.instantLock` | Adjacent lock store — **not** ST Prefs |
| SCR-FAT-039 | Tombstone → `/scr-fat-085` Modes | Not ST |
| `ChildTimeMirrorScreen` | Watches `PolicySyncBus` | Process memory |

### Evaluation / sync (not durable)

| Component | Role |
|-----------|------|
| `ScreenTimePolicyQuery` | Builds `TimeContext` from policy + Temporary Grant remaining |
| `ScheduleWindowQuery` | Maps sleep/prayer/study windows → `BuiltInModeId` + sets `modeActive` on `TimeContext` (**legacy bridge**; see §4) |
| `TimeEngine` | Precedence consumer of `TimeContext` |
| `TemporaryGrantQuery` | Pure grant expiry / remaining math |
| `PolicySyncBus` / `stage1PolicySyncBus` | Same-process parent→child schedule/policy events (SET-003) — **not** SQLite |
| `TimeRequestDecisionBus` | Same-process P12 child toast |

### Modes path (intact after AUTH-FS005) — not ST storage

```text
FAT-085 / CHD-004
  → Stage1ModesRuntime.ensureOpen()
  → ModesService → mode_document / mode_activation / mode_exception (SQLite)
  → ModesEngine (sole Mode modeActive authority)
```

Evidence: `smart_modes_screen.dart` Domain bind; `modes_engine.dart` comment: *“Sole Mode `modeActive` path — ScheduleWindow is not a second Mode authority.”*

---

## 2. Ownership matrix

Authorities used: Screen Time Final (`screen_time_final/`), FS-003 APP-OD-12, FS-005 MODE-OD-06, Owner **OD-D** (`QUESTIONS.md` Q-P175-SLICE01: *ScheduleWindow remains ST-only*), `PHASE_1_75_MOCK_TO_REAL_AUDIT.md` / migration graph.

| Data | Current Owner (code) | Current Storage | Consumers | Producers | Correct Owner | Target Storage | Migration State | Class |
|------|----------------------|-----------------|-----------|-----------|---------------|----------------|-----------------|-------|
| Daily cap / overflow / usedMinutesToday / AppWallet[] | Prefs ST policy repo | Memory Prefs JSON | FAT-032, TimeEngine via query, earn paths (Studio/Quran/wallet), PolicySyncBus | FAT-032 save; earn repos write wallets | **Screen Time Final** | Local SQLite (ST Domain TBD) | **CANDIDATE DOM-ST** | `SCREEN_TIME_OWNED` |
| TimeRequest pending/decided | Prefs TimeRequest repo | Memory Prefs JSON | FAT-033 inbox, CHD-020, CHD-004 day board request CTA, FAT-032 grant remaining | Child request; parent approve/deny | **Screen Time Final** (G-A) | Local SQLite | **CANDIDATE DOM-ST** | `SCREEN_TIME_OWNED` |
| TimeGrant active remaining | Same Prefs store (`time_grants`) | Memory Prefs JSON | TemporaryGrantQuery; FAT-032; TimeEngine path | Approve path in TimeRequestService | **Screen Time Final** | Local SQLite | **CANDIDATE DOM-ST** | `SCREEN_TIME_OWNED` |
| ScheduleWindow sleep/prayer/study | Prefs ScheduleWindow repo | Memory Prefs JSON | FAT-032 UI; PolicySyncBus; **ScheduleWindowQuery** (tests / legacy TimeContext) | FAT-032 editors | **ST-owned (OD-D)** — **not** Modes lifestyle | Local under ST; **must not** become Modes store | **CANDIDATE (sensitive)** | `SCHEDULE_WINDOW_OWNED` ⊂ ST product host |
| Modes lifestyle clock/location/manual | ModesService | SQLite `mode_*` | FAT-085, CHD-004, ModesEngine | FAT-085 | **Modes (FS-005)** | Already SQLite | **DO NOT MIGRATE INTO ST** | `MODES_OWNED` |
| AC Allow/Block/Exempt/Lock Now | Domain AC | SQLite `ac_*` | FAT-034 host | FAT-034 | **App Control** | Already SQLite | Untouched | `APP_CONTROL_OWNED` |
| Limit / Unlimited / Countable axes | Prefs AppAccessRules (+ Domain bridge `stAxes`) | Memory Prefs | FAT-034 Unlimited UI; TimeEngine via AppAccessRules | FAT-034 | **Screen Time** (APP-OD-12) hosted on AC rule seam | Local ST or shared kv — **separate sub-slice** | **DEBT / OUT OF SMALLEST** | `SCREEN_TIME_OWNED` on `SHARED_CONTRACT` seam |
| PolicySyncBus mirror | In-process bus | Process RAM | Child mirror UI | FAT-032 publish | Presentation / SET-003 honesty | Optional later EVT | Not DOM-ST core | `SHARED_CONTRACT` |
| Usage report / apps mock rows | Mock repos | Mock | FAT usage / apps screens | Mock seed | Mock until metering | N/A | Out of scope | Mock |
| OS usage metering / block | Absent / honesty badges | Missing native | — | — | Native later | Native | Out of Phase 1.75 DOM | Missing |
| WalletLedger / PolicyEngine earn | Policy economy | Separate policy paths | Earn flows | PolicyEngine | Economy law (minutes) | Existing | Do not redefine | `SHARED_CONTRACT` |

---

## 3. Storage matrix

| Datum | Memory-only | Prefs-backed RAM | SQLite | Mock | Missing | Duplicated? |
|-------|-------------|------------------|--------|------|---------|-------------|
| ScreenTimePolicy | — | **YES** (`MemoryScreenTimePolicyPrefsStore`) | **NO twin** | — | Durable | — |
| ScheduleWindow | — | **YES** | **NO twin** | — | Durable | Conceptual overlap with Modes **clock** (authority split by OD-D / MODE-OD-06) |
| TimeRequest / TimeGrant | — | **YES** | **NO twin** | — | Durable | — |
| AppAccess Limit/Unlimited/Countable | — | **YES** (`stage1AppAccessRulesStore`) | Partial: AC doc SQLite ≠ ST axes | — | Durable ST axes | ST axes ≠ AC disposition |
| Modes docs/activations | — | Prefs SmartModes **legacy only** | **YES** `mode_*` | — | — | Prefs fallback removed on FAT-085 (AUTH-FS005) |
| PolicySync child mirror | **YES** | — | — | — | Restart | — |
| Decision buses | **YES** | — | — | — | Restart | — |
| Usage stats OS | — | — | — | Mock UI | Real metering | — |

**Critical finding:** Unlike AUTH-FS002 (Domain `LocalWebFilterTempAllowStore` already existed), **Screen Time has no pre-built Domain/SQLite representation**. DOM-ST implementation must add local persistence (e.g. `kv_store` namespaces preserving existing JSON shapes, or dedicated `st_*` tables). Preflight does **not** create schema.

---

## 4. ScheduleWindow boundary

### What it owns (data)

Per-child triple of windows: `sleep` | `prayer` | `study` — enabled flag + same-day `start`/`end` (`ScheduleKind`, `ScheduleWindow`).

### Who writes

- **Producer:** `ChildScreenTimeScreen` → `PrefsScheduleWindowRepository.save`
- Tests inject `InMemoryScheduleWindowRepository` / shared Memory Map

### Who reads

- FAT-032 load/edit UI
- `PolicySyncBus` schedule events → child mirror
- `ScheduleWindowQuery` (unit tests + library API) → `activeBuiltInMode` / `timeContextFromSchedules` setting `modeActive: true`

### ST dependency

FAT-032 **hosts** ScheduleWindow UI as Screen Time Overview (SET-001). Product law (OD-D): ScheduleWindow remains **ST-only**, not Modes ownership.

### Modes relationship

| Fact | Evidence |
|------|----------|
| Modes does **not** read Prefs ScheduleWindow for FAT-085 | `Stage1ModesRuntime` / `ModesEngine` / `mode_document` |
| ScheduleWindow must **not** become Modes owner | MODE-OD-06; OD-D; `ModesEngine` doc comment |
| Legacy risk | `ScheduleWindowQuery.timeContextFromSchedules` still maps windows → `modeActive` — **legacy TimeEngine bridge**, not ModesService authority |
| Production Modes UI | Does not call `ScheduleWindowQuery` (grep: only query + tests) |

**Preflight verdict:** Boundary is **clear enough to migrate storage under ST** without changing ownership. Risk is **optical dual-authority** if implementers wire ScheduleWindow into Modes tables or reverse Modes→ScheduleWindow.  

**Not** `BLOCKED_BY_AUTHORITY` for ST Prefs→local under ST.  

**Would be** `BLOCKED_BY_AUTHORITY` if a slice tried to merge ScheduleWindow into Modes or make ST own `mode_*`.

**Do not modify ScheduleWindow product semantics in DOM-ST** — persist only.

---

## 5. Modes boundary

| Check | Status |
|-------|--------|
| FS-005 Domain SQLite intact | **YES** — `mode_document` / activation / exception |
| FAT-085 Domain bind (no Prefs production fallback) | **YES** (Slice 01 AUTH-FS005) |
| CHD-004 Modes disclosure Domain | **YES** (Slice 01) |
| Second Modes authority from DOM-ST? | **Must forbid** — ST persistence ≠ ModesService |
| Move mode scheduling into ST? | **Forbidden** |
| Reuse Modes tables for ST state? | **Forbidden** without new Owner contract |
| Alter CHD-004 / FAT-085 behavior | **Out of DOM-ST scope** |

DOM-ST must leave Modes files and `mode_*` schema untouched.

---

## 6. Cross-domain dependencies

| Domain | Dependency on ST storage | Impact if ST Prefs → SQLite |
|--------|--------------------------|------------------------------|
| **App Control** | ST Limit/Unlimited via `stAxes` Prefs; AC doc separate | Smallest DOM-ST can leave `AppAccessRules` Prefs; later sub-slice |
| **Modes** | Precedence consumer of time remaining; not ST Prefs reader | **None** if ScheduleWindow not merged into Modes |
| **Web Filter** | Independent; unlock ≠ Grant | **None** |
| **Day Board / CHD-004** | Time request CTA uses `stage1TimeRequestPrefsStore` | Must rebind request service to new repo |
| **Request Inbox FAT-033** | Same Prefs | Must rebind |
| **Reports / usage** | Mock | Low |
| **Notifications** | Contract-level request events; Prefs notification store separate | Event honesty later (EVT-01); not required for first persist |
| **Child views** (CHD-020/021, mirror) | Request + PolicySyncBus | Rebind request; mirror remains process bus unless EVT |
| **Education / Studio earn** | Writes wallets via `stage1PolicyPrefsStore` | **Must** share same durable policy store after migration |
| **SOS** | Exempt from expiry lock | Unchanged |
| **Family settings** | Deep links only | Unchanged |
| **Scheduling runtime** | ModesEngine vs ScheduleWindowQuery | Guardrails tests |

---

## 7. Restart / offline gaps

| Datum | Survives app restart? | Survives process death? | Offline usable? | Durable audit? | Outbox/event? | Init failure today |
|-------|----------------------|-------------------------|-----------------|----------------|---------------|--------------------|
| ScreenTimePolicy Prefs Map | **NO** (SharedPreferences adapter-shaped but **not wired** to device prefs or SQLite) | **NO** | Yes in-process | No ST audit table | PolicySyncBus only | N/A — always memory |
| ScheduleWindow Prefs | **NO** | **NO** | Yes in-process | No | PolicySyncBus | N/A |
| TimeRequest/Grant Prefs | **NO** | **NO** | Service has offline queue flag (in-memory) | No | Decision bus RAM | N/A |
| Modes Domain | **YES** (SQLite) | **YES** | Yes | Partial Modes | — | Fail-closed on FAT-085 |
| PolicySync mirror | **NO** | **NO** | Same process | No | Bus | Clears |
| OS enforcement | **Missing** | — | Honesty badges | — | — | MOCK-REMOTE / not claimed |

**Gap DOM-ST closes:** process-death durability for ST-owned Prefs Maps.  
**Gap DOM-ST does not close:** native metering/block; multi-device sync; FCM; EventBus.

---

## 8. Proposed smallest safe migration slice

### Recommendation: **DOM-ST-1 — ScreenTimePolicy durability only**

Smallest blast radius with clear ST ownership and no Modes entanglement.

| # | Item | Detail |
|---|------|--------|
| 1 | **Data to migrate** | `ScreenTimePolicy` blob only: `dailyCapMinutes`, `allowWalletOverflow`, `usedMinutesToday`, `wallets[]` |
| 2 | **Current authority** | `PrefsScreenTimePolicyRepository` + `stage1PolicyPrefsStore` (Memory Map) |
| 3 | **Target authority** | New `LocalScreenTimePolicyStore` (or kv_store-backed adapter) implementing `ScreenTimePolicyRepository`; single production bind from FAT-032 + earn consumers |
| 4 | **Likely files** | New store under `core/` (ST Domain); `child_screen_time_screen.dart` bootstrap; `child_wallet_repository.dart`, `attribution_reward_repository.dart`, `quran_progress_repository.dart`; optional `Stage1ScreenTimeRuntime`; tests |
| 5 | **Tests** | Existing `screen_time_policy_test` / FAT-032 widget tests; earn path smoke; **new** SQLite write→close→reopen→read |
| 6 | **Restart proof** | Cap + wallet survive reopen; defaults when missing |
| 7 | **Known blockers** | **No existing ST SQLite twin** — implement must add persistence mechanism (not product law). Fail-closed vs Prefs dual authority (follow AUTH-FS002 pattern). |
| 8 | **Must remain unchanged** | ScheduleWindow Prefs (defer); TimeRequest Prefs (defer or Phase 1b); Modes `mode_*`; AC `ac_*`; WF; SOS; UI copy/routes; TimeEngine precedence; ScheduleWindowQuery semantics; native |

### Optional tight follow-on (same Owner auth or DOM-ST-1b)

**TimeRequest + TimeGrant** → same Prefs→SQLite pattern; rebinds FAT-033 / CHD-020 / day board. Still no ScheduleWindow.

### Explicitly **not** in smallest slice

| Item | Why defer |
|------|-----------|
| ScheduleWindow → SQLite | ST-owned but Modes-boundary sensitive; separate auth **DOM-ST-2** with Modes non-authority regression tests |
| AppAccess Limit/Unlimited Prefs | Shared AC seam; separate **DOM-ST-3** / AC-ST axes card |
| PolicySyncBus → EventBus | EVT-01 |
| Native OS Screen Time APIs | Native gate |
| Schema invention beyond approved persistence adapter | Owner-authorized implement card |

### Storage mechanism options (implement-time choice — not decided here)

1. **`kv_store` namespace** preserving current JSON (smallest schema delta; STOR-01 already proves reopen).  
2. **Dedicated `st_policy` / `st_time_request` tables** (clearer Domain symmetry with FS-*).  

Either is local persistence under ST ownership; neither merges Modes.

---

## 9. Blockers and risks

| Risk | Severity | Mitigation for future implement |
|------|----------|----------------------------------|
| No Domain store exists yet | Medium | Expected; create on DOM-ST implement auth — do not invent product fields |
| Dual Prefs + SQLite authority | High | Single production bind; no silent Prefs fallback (AUTH-FS002 pattern) |
| ScheduleWindow → Modes confusion | High | Keep ScheduleWindow out of DOM-ST-1; never write `mode_*` from ST |
| Earn paths still on Prefs after FAT-032 migrates | High | Migrate all `stage1PolicyPrefsStore` producers in same slice |
| AppAccess Unlimited left on Prefs | Low for DOM-ST-1 | Document explicit debt |
| Claiming OS enforcement | High product | Keep honesty badges; no native in DOM-ST |
| Broad Prefs cleanup | Process | Isolate ST policy keys only |

**Authority blockers:** None for DOM-ST-1 (policy only). ScheduleWindow merge into Modes remains **blocked** (OD-D).

---

## 10. Scope confirmation

```text
DOM-ST PREFLIGHT ONLY
PRODUCTION CODE CHANGED: NO
SLICE 02-B / DOM-ST IMPLEMENTATION: NOT STARTED
PHASE 1.75 BROAD CODEGEN: NOT ARMED
```

### Evidence anchors (code)

- `app/lib/features/n03_screen_time/child_screen_time_screen.dart` — Prefs binds  
- `app/lib/core/policy/screen_time_policy_repository.dart`  
- `app/lib/core/policy/schedule_window_repository.dart`  
- `app/lib/core/policy/time_request_repository.dart` / `time_request_service.dart`  
- `app/lib/core/policy/schedule_window_query.dart` — legacy modeActive bridge  
- `app/lib/core/modes/modes_engine.dart` — Modes sole modeActive  
- `app/lib/core/fs_foundation/local_database.dart` — no `st_*` tables  
- `QUESTIONS.md` Q-P175-SLICE01 OD-D  
- `docs/experience_discovery/PHASE_1_75_MIGRATION_GRAPH.md` DOM-ST node  
- `docs/experience_discovery/screen_time_final/` — frozen ST law  
- `docs/project-plan/08-gap-closure-specs.md` — proposed D-1 / D-1b / D-2 / D-3 SQL (**docs only; not implemented**)  
- Explore cross-check: [Explore Screen Time domain](f760f31f-1fd8-48e9-9602-16a6da8d72d1) — confirms Prefs-only path, absent `Stage1ScreenTimeRuntime`, Modes separate; OD-D residual treated as **answered** in `QUESTIONS.md` (ST-only ScheduleWindow), not reopened  

### HARD STOP

Preflight complete. **Do not implement DOM-ST** until Owner issues a separate authorization naming the approved sub-slice (recommended: **DOM-ST-1 ScreenTimePolicy only**).
