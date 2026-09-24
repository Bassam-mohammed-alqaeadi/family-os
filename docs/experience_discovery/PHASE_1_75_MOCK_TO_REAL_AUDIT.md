# PHASE 1.75 — MOCK TO REAL LOCAL MIGRATION AUDIT

**Mode:** READ-ONLY documentation  
**Date:** 2026-09-24  
**Governance:** `PROJECT_EXECUTION_PLAN.md` · `AGENTS.md` · `.cursor/rules/00-project-execution-governance.mdc`

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: PHASE 1.75 — MIGRATION AUDIT
STATUS: ALIGNED
REQUIRED GATE: MIGRATION AUDIT
WILL MODIFY PRODUCTION CODE: NO
```

**Inventories used:** `family-os/_REGISTRY/services.csv` (240 services → **42** subsystems), `journeys.csv` (**73**), `screens.csv` (**130** rows; active product law often cites **129** + tombstone `SCR-FAT-039`).  
**Evidence rule:** live code path > filename > registry status `موجودة`.  
**Classification key:** A KEEP_REAL · B CONVERT_TO_REAL_LOCAL · C KEEP_AS_HONEST_MOCK · D BLOCKED_BY_AUTHORITY · E BLOCKED_BY_NATIVE · F BLOCKED_BY_REMOTE · G LEGACY_REMOVE_AFTER_MIGRATION · H CONFLICTING · I DEFERRED

---

## 1. Executive Summary

Family OS began as a complete web prototype (42 systems / 240 services / 73 journeys / 130 screens) and was converted into Flutter primarily as a **UI / mock / simulation**. Phase 1.5 reconciled FS-001→FS-007 UX and honesty. Phase 1.75 must convert the simulation into a **real local Flutter runtime** — not rebuild the product, not implement native/OS planes, and not integrate Backend.

**Architecture reality in one sentence:** a **SQLite island** (`FsSessionKernel` → `family_os_fs.db` schema v10) already hosts seven FS domain stores, while the **majority of screens** still bind to process-global `stage1*` InMemory repositories and `Memory*PrefsStore` maps.

**Critical distinctions (never collapse):**

`UI implemented` ≠ `Domain implemented` ≠ `SQLite persisted` ≠ `Offline resilient` ≠ `Native OS enforced` ≠ `Backend synchronized`

**Highest-priority findings:**

| Finding | Class | Impact |
|---------|-------|--------|
| SQLite kernel is APK runtime default (`preferSqlite: true`) | A (foundation) | Real local path exists |
| Restart persistence not proven by disk reopen tests | B / risk | STOR-01 gate |
| FS-001 hosts default to Stage-1 zones/history | D | Domain under-bind |
| FS-005 Modes → Prefs fallback still live | D | Dual authority |
| FS-006 SOS hosts not bound to `sos_final` | D | Parallel SOS stores |
| No Drift; no SharedPreferences package; "Prefs" = RAM Maps | B | Naming trap |
| No Family EventBus; outbox = `sync_outbox` MOCK-REMOTE only | B / C | Events gap |
| GPS / VPN / OS intercept / FCM / cloud AI remain NOT_IMPLEMENTED or MOCK-REMOTE | E / F / C | Outside 1.75 |

**This audit does not arm codegen.** Exit criteria in §18 must pass Owner review first.

---

## 2. Phase 1.75 Scope

### In scope (Real Local Flutter Runtime)

- Shared foundation honesty (kernel, schema, capability registry, Memory fallback visibility)
- Binding hosts to already-real Domain stores (authority dedup)
- Converting Memory Prefs / InMemory domain state to approved local persistence **where ownership + policy are known**
- Local policy evaluation, audit rows, outbox **records** (still MOCK-REMOTE transport)
- Preserving KEEP + REFINE UX, routes, and composition

### Out of scope (explicit)

- Native GPS, VPN/DNS, OS app intercept, MediaProjection, OS camera kill, OS wake, FCM, SMS, telephony
- Live Backend / multi-device sync / cloud AI
- Mass PlaceholderScreen conversion for completion %
- Redesign of frozen screens
- Inventing policies for FS-008→FS-010 before analysis gates
- Creating second authorities beside approved domain owners

### Guideline migration direction (not a license to invent architecture)

```text
Shared Foundation → Storage/Persistence → Core Domain State → Repositories
→ Policy Evaluation → Events/Audit/Outbox → Cross-System Seams → Host Screens
→ Native Boundaries → Remote Transport
```

---

## 3. Architecture Reality

| Claim | Evidence |
|-------|----------|
| Boot opens FS session | `app/lib/main.dart` → `FsSessionKernel.ensureOpen(preferSqlite: true)` |
| DI style | Constructor injection + `stage1*` globals; **no Riverpod provider graph** for FS domains |
| FS runtimes | `Stage1LocationRuntime`, `Stage1WebFilterRuntime`, `Stage1AppControlRuntime`, `Stage1ScreenCameraRuntime`, `Stage1ModesRuntime`, `Stage1SosFinalRuntime`, `Stage1OfflineAiSafetyRuntime` |
| Capability honesty | `CapabilityRegistry` + `CapabilityStatus` (IMPLEMENTED / MOCK-REMOTE / DEGRADED / UNSUPPORTED / NOT_IMPLEMENTED) |
| Identity | `stage1IdentityRuntime` fixture in RAM — not SQLite |
| Router | `app/lib/app/router.dart` (+ `sys3_routes.dart`); builders usually pass IDs only, not Domain repos |
| Schema | Custom **sqflite** `FamilyLocalSchema.currentVersion = 10` — **not Drift** |
| Remote adapter | `MockRemoteAdapter` → table `sync_outbox` only |

---

## 4. Storage Reality

Answers to the mandatory storage investigation:

| # | Question | Answer |
|---|----------|--------|
| 1 | Real SQLite? | Yes — `SqliteLocalDatabase` → `family_os_fs.db` under app documents. Tables: foundation (`schema_meta`, `kv_store`, `capability_entry`, `sync_outbox`, `policy_delivery`) + loc_* + wf_* + ac_* + sc_* + mode_* + sos_* + ai_* (v1–v10). |
| 2 | Still memory/Map? | Yes — dominant for feature `stage1*` InMemory repos; all `Memory*PrefsStore`; in-process sync buses. |
| 3 | Prefs repositories? | Yes — naming only. Implementations are **in-RAM Maps**, not `shared_preferences`. |
| 4 | Both old and new? | Yes — Web Filter Domain vs Prefs unlock; Safe Zones Domain vs Stage-1; App Access Domain vs Prefs ST axes; Modes vs Prefs Smart Modes; SOS Final vs Stage-1 SOS alert/ladder. |
| 5 | Runtime default? | **SQLite preferred** at boot. |
| 6 | Domain ownership? | FS Domain stores own durable FS-001…007 policy docs; Screen Time schedules/time-requests remain Prefs-owned; identity RAM-owned. |
| 7 | Restart proven? | **Implemented, not proven** — schema migrate tested; no product write→close→reopen assertions found. "Survives restart" tests often share the same Map instance. |
| 8 | Used in production APK? | Intended yes via `preferSqlite: true`. If open fails → Memory fallback. |
| 9 | Memory fallback? | On SQLite open failure (`sqliteFallbackToMemory=true`); also lazy `MemoryLocalDatabase` if `db` accessed before `ensureOpen`; tests force Memory. |
| 10 | Migrate or retire? | **Migrate/bind:** Stage-1 hosts for domains that already have SQLite; Prefs-only domains with clear ownership (ST, time requests, identity). **Retire after proof (G):** Prefs Smart Modes fallback, Stage-1 zone/history defaults, Stage-1 SOS alert path once hosts bind `sos_final`. **Keep as honest mock (C):** remote/native planes. |

### Storage class map

| Store class | Path pattern | Persistence |
|-------------|--------------|-------------|
| `Local*Store` on kernel | `core/location|web_filter|app_control|screen_camera|modes|sos_final|offline_ai_safety/*_store.dart` | SQLite (or Memory DB twin) |
| `Memory*PrefsStore` | `core/policy/*_repository.dart` + feature stage1 stores | Process RAM |
| `InMemory*` / `stage1*` | `features/**` | Process RAM |
| `sync_outbox` | `mock_remote_adapter.dart` | SQLite rows; transport MOCK |

---

## 5. UI → State → Domain → Repository → Persistence Audit

### Chain templates (evidence-based)

#### FS-001 Location

```text
SCR-FAT-014 LocationMap
  → Stage1 map pins (InMemory) + Domain silent locate (LocalLocationStore)
  → BREAK: decorative map ≠ GPS; pins not Domain trail

SCR-FAT-015 LocationHistory
  → stage1LocationHistoryRepository (default)
  → DomainLocationHistoryRepository EXISTS but NOT router-bound
  → BREAK: SCREEN → Stage1 Map

SCR-FAT-016/017 SafeZones / Create
  → stage1SafeZonesRepository (default)
  → DomainSafeZonesRepository EXISTS but NOT default-bound
  → BREAK: SCREEN → Stage1; Domain→SQLite unused by production route
```

#### FS-002 Web Filter

```text
SCR-FAT-036 WebFilter
  → Stage1WebFilterRuntime.ensureOpen → DomainWebFilterPolicyRepository → LocalWebFilterStore (SQLite)
  → Unlock requests still PrefsWebUnlockRequestRepository (RAM)
  → CHAIN: SCREEN → Domain → SQLite (policy); SCREEN → Prefs (unlock residual)
```

#### FS-003 App Control + Screen Time axes

```text
SCR-FAT-034 ChildApps
  → bootstrap DomainAppAccessRulesRepository / AppControlService → SQLite ac_*
  → ST limit axes via PrefsAppAccessRulesRepository (intentional split)
  → Pre-bootstrap: stage1ChildApps Prefs-only window
  → CHAIN: SCREEN → Domain → SQLite (+ Prefs ST axes)
```

#### FS-004 Screen Camera

```text
SCR-FAT-065 SmartAlerts / SC hosts
  → Stage1ScreenCameraRuntime → ScreenCameraDocument → LocalScreenCameraStore (SQLite)
  → DesiredMonitoringPrefs: web/app/notification/location ONLY (no screenshot) — ownership clean
  → Capture pipeline CapabilityStatus.mockRemote
  → CHAIN: SCREEN → Domain → SQLite (policy); native capture MOCK
```

#### FS-005 Modes

```text
SCR-FAT-085 SmartModes
  → try ModesService / Stage1ModesRuntime → SQLite mode_*
  → catch/fallback PrefsSmartModePrefsRepository → Memory Prefs
  → CHD-004 ModeDisclosureCard only if modes injected (router does not)
  → BREAK: dual authority path
```

#### FS-006 SOS

```text
SCR-FAT-018 / FAT-028 / CHD SOS
  → stage1SosAlertRepository + ladder/settings Memory stores
  → LocalSosFinalStore / Stage1SosFinalRuntime EXISTS but n10 hosts do not default-bind
  → BREAK: SCREEN → Stage1; Domain SQLite parallel
```

#### FS-007 Offline AI Safety

```text
Smart alerts / AI hosts that open Stage1OfflineAiSafetyRuntime
  → LocalOfflineAiSafetyStore (SQLite ai_*)
  → Advisor chat screens still InMemory AdvisorRepository (Rule 26 seam)
  → CHAIN: partial Domain→SQLite; Advisor UI → mock
```

#### Screen Time schedules (SEC:أ)

```text
SCR-FAT-039 ChildScreenTime (and related)
  → PrefsScheduleWindowRepository / PrefsScreenTimePolicy / PrefsTimeRequest (RAM Maps)
  → No SQLite twin today
  → CHAIN: SCREEN → Prefs → RAM
```

#### Identity / ADM

```text
Login / family select / children list
  → stage1IdentityRuntime + stage1ChildrenListRepository (often empty)
  → CHAIN: SCREEN → RAM fixture; Day board may use RegisterMockFamily on some paths only
```

#### COM / EDU / most ADM settings

```text
SCREEN → stage1* InMemory repository → RAM
(no Domain twin; CONVERT only after ownership gate)
```

---

## 6. Event / Outbox Audit

| Mechanism | Status | Classification |
|-----------|--------|----------------|
| Family EventBus / typed FamilyEvents | **Not found** under `app/lib` | Missing link — B (local bus design) / not invent in audit |
| SOS lifecycle audit rows | Present in `sos_lifecycle_audit` via sos_final | A (local audit) when host bound |
| In-process sync buses (`stage1PolicySyncBus`, decision buses, etc.) | RAM only, process lifetime | B → durable events later |
| `sync_outbox` + `MockRemoteAdapter` | Local queue; no live cloud | C KEEP_AS_HONEST_MOCK transport |
| Notifications as product events | UI / Prefs / InMemory hubs | B local emit; F push delivery |
| Downstream policy updates from AI | FS-007 suggest-only (no silent mutate) | A law; host wiring partial |

**Missing links to classify (do not implement here):** domain event emission on zone save, mode activate, AC disposition change, time-request approve; durable audit for Prefs-only ST; outbox enqueue honesty when remote absent.

---

## 7. Offline Audit

| Domain | Works offline? | Survives restart? | Writes locally? | Queues outbound? | Recovery? | Silent Memory fallback? |
|--------|----------------|-------------------|-----------------|------------------|-----------|-------------------------|
| FS SQLite domains (bound) | Yes (local) | Intended yes; **unproven** | Yes | Outbox MOCK | Schema migrate yes | Yes if SQLite open fails |
| Stage-1 InMemory hosts | Yes (empty/sim) | **No** (process only) | RAM | No | N/A | N/A (already memory) |
| Memory Prefs | Yes | **No** (unless shared Map test trick) | RAM | No | N/A | Always memory |
| Identity fixture | Yes | No across process | RAM | No | Session flags only | N/A |
| Chat/calls mocks | Simulated offline UI | No | RAM | No real queue | No | N/A |
| Native GPS/VPN/OS | N/A | N/A | No | N/A | N/A | Honesty badges required |

---

## 8. Authority / Duplicate Store Audit

### FS-001 (special)

| Surface | Lawful | Residual | Router default | Class |
|---------|--------|----------|----------------|-------|
| Safe zones FAT-016/017 | `DomainSafeZonesRepository` → `LocalLocationStore` | `stage1SafeZonesRepository` | Stage-1 | **D** |
| History FAT-015 | `DomainLocationHistoryRepository` | `stage1LocationHistoryRepository` | Stage-1 | **D** |
| Map FAT-014 | Domain silent locate | Stage-1 pins | Hybrid | **D** partial |

### FS-003 (special)

| Concern | Verdict |
|---------|---------|
| Allow/Block/Exception/Lock/Install | AppControl Domain — coherent on FAT-034 bootstrap |
| Limit/Unlimited/Temporary Grant | Screen Time Prefs axes — intentional split via `DomainAppAccessRulesRepository` |
| Protected packages | `ProtectedPackageIds` — clean |
| Risk | Brief Prefs-only window pre-bootstrap; OS intercept MOCK-REMOTE (not dual policy) |

### FS-004 (special)

| Concern | Verdict |
|---------|---------|
| Screenshot monitoring | `ScreenCameraDocument.monitorScreenshots` owns it |
| DesiredMonitoringPrefs | Four features only — **no screenshot** (C-08 mitigated) |
| Class | **A** ownership; capture plane **C/E** MOCK-REMOTE |

### FS-005 (special)

| Path | Verdict |
|------|---------|
| ModesService / Stage1ModesRuntime | Lawful SQLite modes |
| Prefs Smart Modes fallback | Still live on FAT-085 | **D** |
| ScheduleWindow on ST | Adjacent; engine asserts ≠ Mode | OD-D affirm ST-only |
| CHD-004 disclosure | Absent without modes inject | **D** partial |

### Repo-wide dual / fallback (beyond four)

| ID | Side A | Side B | Class |
|----|--------|--------|-------|
| FS-002 unlock | Domain temp-allow SQLite | Prefs unlock requests | **G** after bind |
| FS-006 SOS | `sos_final` SQLite | Stage-1 alert/ladder/settings | **D** |
| FS-002 policy Prefs | Domain WF production | Prefs still in tests/legacy symbols | **G** |
| Generic stage1 feature repos | — | Dozens of InMemory | **B** or **C** (not dual unless Domain twin exists) |

Prior recon: `FS_001_007_AUTHORITY_INTEGRITY_REPORT.md` (C-02, C-03, C-08). Closure report over-claims “no duplicate stores” vs live host defaults — Integrity + code win.

---

## 9. Native Boundary Audit

| Capability | CapabilityRegistry / code | Must stay outside Phase 1.75 codegen | False-complete risk |
|------------|----------------------------|--------------------------------------|---------------------|
| Native GPS | `fs001.native_gps` NOT_IMPLEMENTED | Yes **E** | Map UI must not imply live fix |
| VPN/DNS web block | `fs002.native_block` MOCK-REMOTE | Yes **E/C** | Honesty badge required |
| OS app intercept | `fs003.os_intercept` MOCK-REMOTE | Yes | Never claim Device Admin block |
| MediaProjection / screenshot agent | `fs004.capture_pipeline` MOCK-REMOTE | Yes | Policy ≠ capture |
| OS camera disable | `fs004.camera_os_plane` MOCK-REMOTE | Yes | |
| OS wake / AlarmManager | `fs005.os_wake` MOCK-REMOTE | Yes | Evaluate-on-open only |
| FCM / SMS / telephony | `fs006.remote_delivery` MOCK-REMOTE | Yes **F/E** | SOS fire local ≠ delivered |
| Cloud AI classify | `fs007.cloud_classify` UNSUPPORTED | Yes **F/C** | |

**Verdict:** Existing capability seeds are generally honest. Migration must **not** strengthen UI copy to imply these planes are live.

---

## 10. Remote Boundary Audit

| Capability | Status | Class |
|------------|--------|-------|
| Backend APIs / auth cloud | Absent (mock identity) | **F** |
| Multi-device sync | Outbox local only | **C** then **F** |
| Live Advisor / Insights gateway | Mock repositories | **C** |
| Push notifications | Not live FCM | **F** |
| Licensed Quran remote source | Boundary | **C** until licensed path |
| Router-level parental web (S-SEC-018) | Catalog remote appliance | **F** |

---

## 11. 42-System Migration Matrix

Systems = unique `(domain, subsystem_letter)` from `services.csv` (**42**). Registry `status=موجودة` is **not** proof of real local implementation.

| System | Services | Current form | Real Local | Simulation | Primary storage | Domain readiness | Authority risk | Native | Remote | Migration | Priority | Blocking |
|---|---:|---|---|---|---|---|---|---|---|---|---|---|
| `ADM:أ` الإعداد الأول | 7 (S-ADM-001…S-ADM-007) | Identity / onboarding | 0–30% (UI/sim dominant) | 70–100% | stage1IdentityRuntime + MemoryFamilyContext | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P0 | CONVERT identity+roster to SQLite |
| `ADM:ب` العائلة والأعضاء | 6 (S-ADM-008…S-ADM-013) | Identity / onboarding | 0–30% (UI/sim dominant) | 70–100% | stage1IdentityRuntime + MemoryFamilyContext | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P0 | CONVERT identity+roster to SQLite |
| `ADM:ج` الأجهزة | 5 (S-ADM-014…S-ADM-018) | Admin / settings | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs / InMemory | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local prefs→SQLite kv |
| `ADM:ح` الإعدادات والدعم | 3 (S-ADM-040…S-ADM-042) | Admin / settings | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs / InMemory | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local prefs→SQLite kv |
| `ADM:د` الاشتراك والفوترة | 6 (S-ADM-019…S-ADM-024) | Admin / settings | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs / InMemory | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local prefs→SQLite kv |
| `ADM:ز` لوحة اليوم | 4 (S-ADM-036…S-ADM-039) | Day board / family overview | 0–30% (UI/sim dominant) | 70–100% | InMemory + RegisterMock on some paths | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P1 | Children list Stage1 empty |
| `ADM:هـ` الإشعارات | 5 (S-ADM-025…S-ADM-029) | Admin / settings | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs / InMemory | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local prefs→SQLite kv |
| `ADM:و` الخصوصية والبيانات | 6 (S-ADM-030…S-ADM-035) | Day board / family overview | 0–30% (UI/sim dominant) | 70–100% | InMemory + RegisterMock on some paths | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P1 | Children list Stage1 empty |
| `AIC:أ` محرك الرصد | 6 (S-AIC-001…S-AIC-006) | Advisor / insights UI | 0% (honest mock) | 100% mock boundary | InMemory AdvisorRepository mocks | Policy Register / catalog | LOW | partial/no | YES | **C** | P2 | Rule 26 AI Gateway remote later |
| `AIC:ب` محرك الأنماط والشذوذ | 5 (S-AIC-007…S-AIC-011) | Advisor / insights UI | 0% (honest mock) | 100% mock boundary | InMemory AdvisorRepository mocks | Policy Register / catalog | LOW | partial/no | YES | **C** | P2 | Rule 26 AI Gateway remote later |
| `AIC:ج` مخزن المعرفة العائلية | 6 (S-AIC-012…S-AIC-017) | Advisor / insights UI | 0% (honest mock) | 100% mock boundary | InMemory AdvisorRepository mocks | Policy Register / catalog | LOW | partial/no | YES | **C** | P2 | Rule 26 AI Gateway remote later |
| `AIC:د` المستشار والتقارير | 6 (S-AIC-018…S-AIC-023) | Advisor / insights UI | 0% (honest mock) | 100% mock boundary | InMemory AdvisorRepository mocks | Policy Register / catalog | LOW | partial/no | YES | **C** | P2 | Rule 26 AI Gateway remote later |
| `AIC:هـ` المساعد التفاعلي | 6 (S-AIC-024…S-AIC-029) | Advisor / insights UI | 0% (honest mock) | 100% mock boundary | InMemory AdvisorRepository mocks | Policy Register / catalog | LOW | partial/no | YES | **C** | P2 | Rule 26 AI Gateway remote later |
| `AIC:و` الوكيل المفوَّض | 5 (S-AIC-030…S-AIC-034) | Advisor / insights UI | 0% (honest mock) | 100% mock boundary | InMemory AdvisorRepository mocks | Policy Register / catalog | LOW | partial/no | YES | **C** | P2 | Rule 26 AI Gateway remote later |
| `COM:أ` المحادثات | 9 (S-COM-001…S-COM-009) | Communications | 0% (honest mock) | 100% mock boundary | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P2 | Honest mock until transport |
| `COM:ب` المكالمات | 6 (S-COM-010…S-COM-015) | Calls | 0% native | UI only | InMemory active/history call repos | Policy Register / catalog | LOW | YES | YES | **E** | P2 | NATIVE/REMOTE telephony |
| `COM:ج` الوسائط والملفات | 5 (S-COM-016…S-COM-020) | Communications | 0% (honest mock) | 100% mock boundary | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P2 | Honest mock until transport |
| `COM:د` دائرة الاتصال الآمنة | 5 (S-COM-021…S-COM-025) | Communications | 0% (honest mock) | 100% mock boundary | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P2 | Honest mock until transport |
| `COM:ز` الموقع في التواصل | 3 (S-COM-037…S-COM-039) | Communications | 0% (honest mock) | 100% mock boundary | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P2 | Honest mock until transport |
| `COM:هـ` التقويم العائلي | 6 (S-COM-026…S-COM-031) | Communications | 0% (honest mock) | 100% mock boundary | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P2 | Honest mock until transport |
| `COM:و` المهام والمسؤوليات | 5 (S-COM-032…S-COM-036) | Communications | 0% (honest mock) | 100% mock boundary | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P2 | Honest mock until transport |
| `EDU:أ` المواد والدروس | 6 (S-EDU-001…S-EDU-006) | Quran / licensed source | 0% (honest mock) | 100% mock boundary | InMemory + asset path TBD | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P1 | Licensed source / remote content boundary |
| `EDU:ب` الواجبات | 6 (S-EDU-007…S-EDU-012) | Education subsystem | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local assignment/result persist candidate |
| `EDU:ج` الاختبارات والتقييم | 6 (S-EDU-013…S-EDU-018) | Education subsystem | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local assignment/result persist candidate |
| `EDU:ح` التركيز وبيئة الدراسة | 6 (S-EDU-042…S-EDU-047) | Education subsystem | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local assignment/result persist candidate |
| `EDU:د` المعلم الذكي | 6 (S-EDU-019…S-EDU-024) | Tutor / learning | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 education repos | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | TutorRepository seam; no on-device LLM |
| `EDU:ز` القرآن والتربية الإسلامية | 5 (S-EDU-037…S-EDU-041) | Quran / licensed source | 0% (honest mock) | 100% mock boundary | InMemory + asset path TBD | Policy Register / catalog | LOW | partial/no | partial/no | **C** | P1 | Licensed source / remote content boundary |
| `EDU:ط` استوديو الأب | 18 (S-EDU-048…S-EDU-065) | Education subsystem | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local assignment/result persist candidate |
| `EDU:هـ` التعلّم التكيفي | 5 (S-EDU-025…S-EDU-029) | Education subsystem | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local assignment/result persist candidate |
| `EDU:و` التحفيز والمكافآت | 7 (S-EDU-030…S-EDU-036) | Education subsystem | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | Policy Register / catalog | LOW | partial/no | partial/no | **B** | P2 | Local assignment/result persist candidate |
| `SEC:أ` إدارة وقت الشاشة | 7 (S-SEC-001…S-SEC-007) | Screen Time / ST | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs (ScheduleWindow, ST policy, time requests) | L2/L3 known | LOW | partial/no | partial/no | **B** | P1 | ST Prefs→local persist; ScheduleWindow≠Modes |
| `SEC:ب` التحكم بالتطبيقات | 6 (S-SEC-008…S-SEC-013) | FS-003 App Control | 0–30% (UI/sim dominant) | 70–100% | SQLite ac_* via Stage1AppControlRuntime + Prefs ST axes | L2/L3 known | MED | partial/no | partial/no | **B** | P0 | AUTH residual Prefs until Domain bootstrap |
| `SEC:ج` فلترة الإنترنت | 5 (S-SEC-014…S-SEC-018) | FS-002 Web Filter | 0–30% (UI/sim dominant) | 70–100% | SQLite wf_* Domain + Prefs unlock residual | L2/L3 known | MED | partial/no | YES | **B** | P0 | AUTH unlock Prefs; native VPN MOCK-REMOTE |
| `SEC:ح` مقاومة التحايل | 5 (S-SEC-042…S-SEC-046) | Notifications / alerts hub | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 + Prefs notification | L2/L3 known | LOW | partial/no | partial/no | **B** | P2 | Local persist possible |
| `SEC:د` الموقع والمناطق الآمنة | 7 (S-SEC-019…S-SEC-025) | FS-001 Location | 40–70% domain / 0% host-bind | host Stage1 residual | SQLite loc_* Domain + Stage1 host under-bind | L2/L3 known | HIGH | partial/no | partial/no | **D** | P0 | AUTHORITY: Stage1 zones/history defaults |
| `SEC:ز` مراقبة منصات التواصل | 4 (S-SEC-038…S-SEC-041) | Anti-tamper / device lock | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs only | L2/L3 known | LOW | partial/no | partial/no | **B** | P2 | No Domain twin yet |
| `SEC:ط` القفل الفوري | 3 (S-SEC-047…S-SEC-049) | Privacy / what is collected | 0–30% (UI/sim dominant) | 70–100% | Memory Prefs privacy collection | L2/L3 known | LOW | partial/no | partial/no | **B** | P2 | Local persist |
| `SEC:ك` السلامة الحركية والقيادة | 3 (S-SEC-055…S-SEC-057) | Road safety / arrival | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | L2/L3 known | LOW | partial/no | partial/no | **B** | P3 | May need location facts |
| `SEC:ل` وضع المدرسة | 3 (S-SEC-058…S-SEC-060) | Silent locate / find | 0% native | UI only | Domain locate partial + Stage1 map | L2/L3 known | LOW | YES | partial/no | **E** | P1 | NATIVE GPS NOT_IMPLEMENTED |
| `SEC:هـ` الطوارئ والاستغاثة | 6 (S-SEC-026…S-SEC-031) | FS-006 SOS | 40–70% domain / 0% host-bind | host Stage1 residual | SQLite sos_* sos_final + Stage1 alert hosts | L2/L3 known | HIGH | partial/no | partial/no | **D** | P0 | AUTHORITY: n10 hosts not sos_final-bound |
| `SEC:و` مراقبة المحتوى الذكية | 6 (S-SEC-032…S-SEC-037) | FS-004 Screen/Camera | 70–90% local domain | 10–30% UI/host | SQLite sc_* + DesiredMonitoring Prefs | L2/L3 known | LOW | partial/no | YES | **A** | P1 | Screenshot ownership mitigated; capture MOCK-REMOTE |
| `SEC:ي` التقارير والتحليلات | 5 (S-SEC-050…S-SEC-054) | Trusted contacts / outer circle | 0–30% (UI/sim dominant) | 70–100% | InMemory stage1 | L2/L3 known | LOW | partial/no | partial/no | **B** | P2 | Local persist |

### Legend note

- **A** rows: Domain SQLite + coherent host bind (or FS-007 local classifier).  
- **B** rows: CONVERT candidates when ownership known.  
- **C** rows: honest mock / remote-or-licensed boundary.  
- **D** rows: authority under-bind or dual path — fix authority before broad CONVERT.  
- **E/F** rows: native/remote blockers — not Phase 1.75 implementation targets.

---

## 12. 73-Journey Migration Matrix

| Journey | Name | Core path | Migration | Notes |
|---|---|---|---|---|
| `JRN-FAT-01` | التسجيل وإنشاء العائلة | simulated | **B** | Identity/onboarding RAM — local persist candidate |
| `JRN-FAT-02` | ربط جهاز الابن الأول | simulated | **B** | Identity/onboarding RAM — local persist candidate |
| `JRN-FAT-03` | تجربة التطبيق قبل الربط | simulated | **B** | Identity/onboarding RAM — local persist candidate |
| `JRN-FAT-04` | دعوة الأم وتحديد صلاحيتها | simulated | **B** | Identity/onboarding RAM — local persist candidate |
| `JRN-FAT-05` | نظرة الصباح على العائلة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-06` | متابعة ابن بعينه | partially real | **D** | Domain location SQLite; map/history Stage1; GPS NOT_IMPLEMENTED |
| `JRN-FAT-07` | معرفة موقع ابنه الآن | partially real | **D** | Domain location SQLite; map/history Stage1; GPS NOT_IMPLEMENTED |
| `JRN-FAT-08` | ضبط منطقة آمنة | partially real | **D** | Domain zones under-bound on FAT-016/017 |
| `JRN-FAT-09` | استقبال بلاغ استغاثة | partially real | **D** | sos_final SQLite exists; host Stage1; remote delivery MOCK |
| `JRN-FAT-10` | استقبال تنبيه أمني | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-11` | محادثة العائلة | simulated | **F** | InMemory chat; remote sync later |
| `JRN-FAT-12` | مكالمة بابنه | blocked | **E** | Telephony/native not in Phase 1.75 |
| `JRN-FAT-13` | إدارة أجهزة العائلة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-14` | معالجة انقطاع جهاز | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-MOT-01` | الانضمام بدعوة الأب | simulated | **B** | Identity/onboarding RAM — local persist candidate |
| `JRN-MOT-02` | نظرة الصباح | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-MOT-03` | متابعة ابن بعينه | partially real | **D** | Domain location SQLite; map/history Stage1; GPS NOT_IMPLEMENTED |
| `JRN-MOT-04` | التواصل مع الأبناء | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-MOT-05` | استقبال بلاغ استغاثة | partially real | **D** | sos_final SQLite exists; host Stage1; remote delivery MOCK |
| `JRN-MOT-06` | متابعة موقع ابنها | partially real | **D** | Domain location SQLite; map/history Stage1; GPS NOT_IMPLEMENTED |
| `JRN-CHD-01` | ربط جهازي وفهم القواعد | simulated | **B** | Identity/onboarding RAM — local persist candidate |
| `JRN-CHD-02` | يومي في لمحة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-03` | طلب النجدة | partially real | **D** | sos_final SQLite exists; host Stage1; remote delivery MOCK |
| `JRN-CHD-04` | التواصل مع عائلتي | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-05` | معرفة ما يُجمع عني | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-SHR-01` | معالجة خطأ أو انقطاع شبكة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-15` | ضبط وقت الشاشة لابن | simulated | **B** | Memory Prefs ScheduleWindow/ST — CONVERT candidate |
| `JRN-FAT-16` | إدارة تطبيقات الابن | partially real | **B** | App Control Domain on FAT-034; OS intercept MOCK |
| `JRN-FAT-17` | ضبط فلترة الإنترنت | partially real | **B** | Domain WF SQLite; native block MOCK-REMOTE |
| `JRN-FAT-18` | قفل فوري لحظة العشاء | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-19` | معالجة محاولة تحايل | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-20` | ضبط وضع المدرسة | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-FAT-21` | صناعة محتوى في الاستوديو | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-22` | الاستفادة من مكتبة المجتمع | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-23` | إدارة تعليم ابنه | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-24` | تنظيم التقويم العائلي | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-25` | إسناد مهمة بمكافأة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-26` | إدارة الاشتراك | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-27` | ضبط الإشعارات | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-28` | الخصوصية والبيانات | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-29` | مراجعة أنماط العقل | partially real | **C** | FS-007 local classifier real; Advisor cloud MOCK/UNSUPPORTED |
| `JRN-FAT-30` | اللغة والمساعدة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-MOT-07` | الموافقة على طلب وقت إضافي | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-MOT-08` | متابعة التقويم والمهام | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-06` | طلب وقت إضافي | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-07` | يوم دراسي كامل | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-08` | سؤال المعلم الذكي | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-CHD-09` | جلسة تركيز للمذاكرة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-10` | نقاطي ومكافآتي | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-11` | مشاركة لحظة مع العائلة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-12` | مهامي المنزلية | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-31` | استقبال تنبيه ذكي والتصرف بحوار | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-FAT-32` | ضبط الرقابة الذكية والمنصات | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-FAT-33` | مراجعة تقرير الاستخدام | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-34` | إدارة الدائرة الخارجية | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-35` | متابعة حفظ القرآن | simulated | **C** | Licensed source boundary; UI mock |
| `JRN-FAT-36` | قراءة التقرير الأسبوعي بتوصية | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-37` | سؤال العقل بلغة طبيعية | partially real | **C** | FS-007 local classifier real; Advisor cloud MOCK/UNSUPPORTED |
| `JRN-FAT-38` | استكشاف الميزات القادمة | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-MOT-09` | استقبال إخطارات التحليلات | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-13` | طلب إضافة صديق | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-14` | وردي اليومي — قرآن وأذكار | simulated | **C** | Licensed source boundary; UI mock |
| `JRN-CHD-15` | خطتي الذكية ومراجعة اليوم | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-CHD-16` | استكشاف المرح القادم | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-39` | متابعة السلامة على الطريق | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-40` | حماية شبكة المنزل | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-FAT-41` | تفويض الوكيل الذكي | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-FAT-42` | توزيع المهام بذكاء | partially real | **C** | FS-007 local classifier real; Advisor cloud MOCK/UNSUPPORTED |
| `JRN-FAT-43` | إطلاق مشروع تعليمي بمراحل | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-17` | مرح وإبداع متقدم | simulated | **B** | Stage1 InMemory / Prefs dominant |
| `JRN-CHD-18` | تلاوتي الذكية | partially real | **D** | Modes SQLite + Prefs fallback authority |
| `JRN-FAT-44` | ضبط وضع ذكي بلمسة | simulated | **B** | Memory Prefs ScheduleWindow/ST — CONVERT candidate |
| `JRN-FAT-45` | لحظة الفخر الأسبوعية | simulated | **B** | Stage1 InMemory / Prefs dominant |

---

## 13. 130-Screen Migration Matrix

Includes tombstone `SCR-FAT-039`. Flutter route presence is assumed from current conversion campaign; migration status reflects **implementation reality**, not visual completeness.

| Screen | Name | State source | Domain | Persistence | Mock deps | Placeholder | Native | Remote | Migration |
|---|---|---|---|---|---|---|---|---|---|
| `SCR-SHR-001` | شاشة الترحيب | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-SHR-002` | إنشاء حساب | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-SHR-003` | تسجيل الدخول | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-001` | إنشاء العائلة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-002` | معالج الإعداد | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-003` | إضافة ابن | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-004` | رمز الربط QR | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-005` | شرح الصلاحيات | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-006` | نجاح الربط | Stage1 / Domain hybrid | Location | mixed | Stage1 | no | GPS | no | **D** |
| `SCR-FAT-007` | وضع التجربة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-008` | دعوة الأم (من لوحة الأب) | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-009` | قبول دعوة الأم | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-010` | لوحة اليوم | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-011` | اقتراحات العقل | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-012` | قائمة الأبناء | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-013` | ملف الابن | Stage1 / Domain hybrid | Location | mixed | Stage1 | no | GPS | no | **D** |
| `SCR-FAT-014` | خريطة الموقع | Stage1 map pins + Domain silent locate | Location Domain partial | SQLite trail/zones + InMemory pins | stage1LocationMapRepository | no | GPS NOT_IMPL | no | **D** |
| `SCR-FAT-015` | سجل المواقع | stage1LocationHistoryRepository | DomainHistory unused | InMemory | Stage1 | no | GPS | no | **D** |
| `SCR-FAT-016` | المناطق الآمنة | stage1SafeZonesRepository | DomainSafeZones unused default | InMemory | Stage1 | no | geofence native later | no | **D** |
| `SCR-FAT-017` | إنشاء منطقة آمنة | stage1SafeZonesRepository | optional Domain unused | InMemory | Stage1 | no | no | no | **D** |
| `SCR-FAT-018` | بلاغ استغاثة | stage1SosAlertRepository | sos_final unbound | InMemory SOS | Stage1 SOS | no | FCM/SMS MOCK | MOCK-REMOTE | **D** |
| `SCR-FAT-028` | إعداد الطوارئ | Emergency setup Stage1 | sos_final unbound | Memory ladder/settings | Stage1 | no | remote delivery | MOCK-REMOTE | **D** |
| `SCR-FAT-019` | مركز التنبيهات | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-020` | تفصيل التنبيه | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-021` | قائمة المحادثات | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-022` | المحادثة | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-023` | مكالمة جارية | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-024` | سجل المكالمات | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-025` | الإعدادات | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-026` | تفصيل الجهاز | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-027` | أعضاء العائلة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-029` | لوحة تحكم العقل | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-CHD-001` | ترحيب الابن | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-002` | مسح رمز الربط | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-003` | إقرار الشفافية | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-004` | لوحة يومي | Day board Stage1 + ST Prefs | no Modes inject | InMemory + Prefs | RegisterMock / stage1 | no | no | no | **D** |
| `SCR-CHD-005` | زر الاستغاثة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-006` | الاستغاثة جارية | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-007` | محادثاتي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-008` | المحادثة | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-009` | مكالمة | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-010` | ماذا يُجمع عني | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-SHR-005` | خطأ الشبكة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-SHR-006` | حالة فارغة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-SHR-007` | اختيار الوضع (شاشة عمر محايدة) | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-SHR-008` | تبديل المستخدم على الجهاز | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-011` | قفل وضع الابن + المدخل السري | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-030` | طلب فتح وضع الوالد (المفتاح الثاني) | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-031` | مستوى صلاحية الأم | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-032` | وقت الشاشة لابن | Prefs / Domain AC | ST/AC | Memory Prefs / SQLite | stage1 | no | OS | no | **B** |
| `SCR-FAT-033` | طلبات الوقت الإضافي | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-034` | تطبيقات الابن | Stage1AppControlRuntime bootstrap | AppControl Domain | SQLite ac_* + Prefs ST axes | stage1ChildApps until boot | no | OS intercept MOCK | no | **B** |
| `SCR-FAT-035` | موافقة تطبيق جديد | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-036` | فلترة الإنترنت | Stage1WebFilterRuntime | WebFilter Domain | SQLite wf_* | Prefs unlock residual | no | VPN MOCK | no | **B** |
| `SCR-FAT-037` | القفل الفوري | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-038` | تنبيهات التحايل | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-039` | وضع المدرسة [محذوفة نهائيًا بقرار أد-١٢ + ق-١٢ في 37] | TOMBSTONE | n/a | n/a | n/a | deleted school mode | n/a | n/a | **I** |
| `SCR-FAT-040` | لوحة الاستوديو | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-041` | أضف من أي مصدر | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-042` | التقاط من الكاميرا | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-043` | مخرجات التوليد | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-044` | معاينة واعتماد | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-045` | الإسناد والمكافأة | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-046` | مكتبة المجتمع | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-047` | المسار التعليمي | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-048` | المواد والدروس | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-049` | إنشاء واجب واختبار | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-050` | متابعة النتائج | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-051` | تقرير التركيز | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-052` | التقويم العائلي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-053` | إضافة حدث | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-054` | المهام العائلية | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-055` | إنشاء مهمة بمكافأة | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-056` | الباقات والاشتراك | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-057` | إدارة الاشتراك | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-058` | الإشعارات | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-059` | الخصوصية والبيانات | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-060` | سجل التدقيق | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-061` | اللغة والمساعدة | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-062` | أنماط العائلة | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-063` | الخط الزمني للفرد | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-064` | خرائط المعرفة | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-CHD-012` | تعلّمي — الرئيسة | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-013` | الدرس | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-014` | واجبي | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-CHD-015` | الاختبار | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-016` | نتيجتي | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-CHD-017` | معلمي الذكي | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-CHD-018` | وضع التركيز | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-019` | نقاطي وشاراتي | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-020` | طلب وقت إضافي | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-CHD-021` | انتهى الوقت — بلطف | Prefs / Domain AC | ST/AC | Memory Prefs / SQLite | stage1 | no | OS | no | **B** |
| `SCR-CHD-022` | مهامي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-023` | مشاركة وسائط | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-024` | أنا وصلت + موقعي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-065` | التنبيهات الذكية | SC runtime + AI | ScreenCamera + OfflineAI | SQLite sc_* / ai_* | Smart alerts catalog residue | no | capture MOCK | no | **A** |
| `SCR-FAT-066` | تفصيل التنبيه وخطوة الحوار | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-067` | إعدادات الرقابة الذكية | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-068` | مراقبة المنصات | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-069` | تقرير استخدام الابن | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-070` | الدائرة الخارجية | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-071` | موافقة طلب صديق | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-072` | متابعة حفظ القرآن | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-FAT-073` | التقرير الأسبوعي بتوصية | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-074` | عقل عائلتي (المساعد الذكي) | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-076` | إخطارات الذكاء للأم | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-075` | ميزات قادمة ✨ | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-025` | وردي — حفظ وتلاوة | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-026` | حفظي وتقدمي | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-027` | أذكاري اليومية | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-028` | خطتي الذكية | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-029` | مراجعة اليوم | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-030` | أصدقائي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-031` | قادم لك 🎁 | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-077` | السلامة على الطريق | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-078` | فلترة الراوتر المنزلي | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-079` | مساعدي الذكي — ماذا يفعل عني | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-080` | ماذا فعل المساعد | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-081` | مقارنة الأقران | InMemory stage1 / Prefs | feature repo | RAM Prefs | stage1* | maybe | no | maybe | **B** |
| `SCR-FAT-082` | موزع المهام الذكي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-083` | المحادثة الصوتية مع العقل | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-FAT-084` | مشروع بمراحل | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-032` | تلاوتي الذكية | Advisor mock / AI store | AIC / FS-007 | RAM or SQLite AI | AdvisorRepository | maybe | no | cloud AI | **C** |
| `SCR-CHD-033` | قصصي التفاعلية | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-034` | التحديات العائلية | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-035` | أصوات التركيز | InMemory education | EDU | RAM | stage1 edu | maybe | no | content source | **B** |
| `SCR-CHD-036` | مرح المكالمة | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-CHD-037` | ملصقاتي وخلفياتي | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |
| `SCR-FAT-085` | الأوضاع الذكية | Modes then Prefs fallback | Modes Domain / Prefs SmartModes | SQLite mode_* OR Memory Prefs | Prefs fallback | no | OS wake MOCK | no | **D** |
| `SCR-FAT-086` | لحظات عائلتنا | InMemory stage1 | COM feature | RAM | stage1 chat/call | maybe | telephony? | YES | **C** |

---

## 14. Legacy Simulation Inventory

| Legacy path | Replacement target | Class |
|-------------|-------------------|-------|
| `stage1SafeZonesRepository` default on FAT-016/017 | `DomainSafeZonesRepository` | **G** after AUTH-FS001 |
| `stage1LocationHistoryRepository` default | `DomainLocationHistoryRepository` | **G** |
| Decorative map pins without GPS | Keep UI; Domain trail for history; GPS stays NOT_IMPLEMENTED | **C** + **E** |
| `PrefsSmartModePrefsRepository` fallback | Modes-only after proof | **G** |
| `stage1SosAlertRepository` / ladder Memory on n10 | `Stage1SosFinalRuntime` / `LocalSosFinalStore` | **G** |
| Prefs web unlock residual | Domain temp-allow only | **G** |
| Prefs WF policy (test/legacy symbols) | Domain WF | **G** |
| Empty `stage1ChildrenListRepository` | Identity+roster SQLite/local | **B** |
| `Memory*PrefsStore` for ST/time-request/etc. | Approved local store / kv / domain tables | **B** |
| InMemory chat/call/advisor | Local drafts optional; live = remote | **C** |
| `MockRemoteAdapter` | Keep until Backend gate | **C** |

---

## 15. Recommended Migration Order

Dependency-first (not screen number, not FS number alone):

1. **FOUND-01 / STOR-01** — Foundation honesty + SQLite restart proof criteria  
2. **AUTH-FS001** — Bind Domain zones/history (and map trail honesty)  
3. **AUTH-FS005** — Modes-only FAT-085; Prefs → legacy  
4. **AUTH-FS006** — SOS hosts → sos_final  
5. **AUTH-FS002-UNLOCK** — Retire Prefs unlock residual  
6. **DOM-ST** — Screen Time Prefs → real local persistence (ScheduleWindow ownership affirmed ST-only)  
7. **DOM-IDENTITY** — Family context + children roster local persistence  
8. **EVT-01** — Local domain events + audit (+ outbox enqueue without fake delivery)  
9. **HOST-*** — Router/constructor injection sweep for Domain repos (KEEP UX)  
10. **DOM-*** remaining CONVERT_TO_REAL_LOCAL subsystems with known ownership  
11. **NAT-*** / **REM-*** — later phases only

### Locked first migration slice (recommendation only — not armed)

1. Storage proof + Memory-fallback observability  
2. Authority binds: FS-001 zones/history, FS-005 Modes-only, FS-006 SOS host  
3. Then ST Prefs → local persist  

---

## 16. Blockers

| Blocker | Type | Blocks |
|---------|------|--------|
| Owner OD-B/C/D (authority decisions) | AUTHORITY | AUTH-FS001 / FS-005 / ScheduleWindow affirm |
| No disk restart proof | LOCAL test gate | Claiming offline-resilient |
| Missing Domain twins for most ADM/COM/EDU | DESIGN / ownership | Blind CONVERT |
| Native GPS/VPN/OS/FCM | NATIVE/REMOTE | Completeness claims |
| FS-008→FS-010 analysis incomplete | PHASE 1 | Inventing those policies |
| Blueprint folder absent | DOC | Do not cite Blueprint |
| Empty children roster UX | DATA / seed policy | Father walkthrough (Owner demo-seed separate) |

---

## 17. Risks

- Treating CapabilityRegistry `IMPLEMENTED` as native-complete  
- “Fixing” dual stores by adding a third store  
- Mass Placeholder conversion for % progress  
- Closing Phase 1.75 while hosts still default to Stage-1  
- Inferring Backend readiness from outbox table existence  
- Demo/sample seed mistaken for live GPS/enforcement  
- Over-trusting FS_001_007_CLOSURE_REPORT “no duplicate stores” wording  

---

## 18. Phase 1.75 Exit Criteria

Phase 1.75 **codegen remains NOT ARMED** until Owner accepts this audit and explicitly authorizes the first slice.

Suggested exit criteria for later (post-implementation waves):

1. SQLite reopen persistence proven for FS domain stores  
2. No production host defaults to Stage-1 where Domain twin is lawful (FS-001 zones/history, FS-005 Modes, FS-006 SOS)  
3. Memory Prefs for ST core paths migrated or explicitly DEBT-logged with Owner  
4. Capability honesty unchanged or stricter — never looser  
5. KEEP/REFINE screens visually preserved  
6. No new duplicate authorities  
7. Native/remote planes still labeled MOCK-REMOTE / NOT_IMPLEMENTED / UNSUPPORTED  
8. verify_ship gate green for touched slices  

---

## Final report

```text
PHASE 1.75 MIGRATION AUDIT: COMPLETE

Real Local candidates:
  - FsSessionKernel + Local*Stores (FS-001…007 domains) where hosts already bind (WF policy, AC bootstrap, SC, Modes primary path, Offline AI store)
  - CONVERT_TO_REAL_LOCAL: Screen Time Prefs, time requests, identity/roster, notification/privacy Prefs, education assignment local caches (ownership-gated)

Authority-blocked:
  - FS-001 Stage-1 zones/history defaults (OD-B)
  - FS-005 Modes↔Prefs fallback (OD-C)
  - FS-006 SOS host under-bind to sos_final
  - CHD-004 Modes disclosure unbound

Native-blocked:
  - GPS, VPN/DNS, OS intercept, MediaProjection/capture agent, OS camera kill, OS wake, telephony

Remote-blocked:
  - FCM/SMS delivery, Backend APIs, multi-device sync, cloud AI, live chat transport

Legacy paths:
  - stage1 zone/history/map-pin defaults; Prefs Smart Modes fallback; Stage-1 SOS alert/ladder; Prefs web unlock; Memory Prefs ST

Conflicting paths:
  - Dual-authority Modes/Prefs; Domain vs Stage-1 location hosts (Integrity C-02/C-03 class)

Deferred:
  - FS-008→FS-010 analysis continuation; Placeholder-only screens; tombstone SCR-FAT-039; licensed Quran source; full COM live

Recommended first migration slice:
  1) STOR-01 SQLite restart proof + fallback honesty
  2) AUTH-FS001 / AUTH-FS005 / AUTH-FS006 host binds
  3) DOM-ST Prefs→local (after OD-D)

Migration blockers:
  - Owner OD authority decisions; unproven restart; missing Domain twins outside FS; native/remote gates; Phase 1 analysis incomplete for FS-008→010

PHASE 1.75 CODEGEN: NOT YET ARMED
```

**STOP** — documentation only; no implementation begun.
