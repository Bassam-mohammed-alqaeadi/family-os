# 03 — FS-005 Capability Inventory

**Mode:** Evidence-only. Do not invent parental-control industry defaults.  
**Master:** [11_FS005_DISCOVERY_CLOSURE_REPORT.md](11_FS005_DISCOVERY_CLOSURE_REPORT.md)

Classification: **IMPLEMENTED** · **PARTIAL** · **MOCK/SIMULATION** · **DOCUMENTED ONLY** · **MISSING** · **UNKNOWN**

---

## Matrix

| # | Capability | Class | Evidence (short) |
|---|---|---|---|
| 1 | Named FS-005 / Modes discovery pack (pre-this) | **MISSING** | First structured pack under this label |
| 2 | Built-in mode catalog (6 + custom) | **PARTIAL** | `BuiltInModeId` 7 values; Register M-A; prototype differs (`famtime`) |
| 3 | Custom mode create/edit | **MOCK/SIMULATION** | Prototype toast; Flutter `custom` switch only |
| 4 | Mode identity (name + icon) | **PARTIAL** | ARB labels on FAT-085; no icon model field in prefs |
| 5 | Six-property `FamilyMode` entity | **PARTIAL** / **MISSING** fields | Grace/conflict domain yes; allowedApps/exceptions/seasonal/scope incomplete |
| 6 | Weekly schedule type | **PARTIAL** | School TOD on FAT-085; no weekday matrix in prefs |
| 7 | Manual-only activation | **PARTIAL** | Toggle activate; Register manual-only for study in proto string |
| 8 | Seasonal date-range schedule | **DOCUMENTED ONLY** | Register + prototype strings; no date fields in Flutter |
| 9 | Per-child mode prefs | **PARTIAL** | `SmartModePrefs.childId` |
| 10 | Family-wide / multi-kid scope | **DOCUMENTED ONLY** | Prototype `kids[]`; Flutter single childId |
| 11 | Manual activate / deactivate | **PARTIAL** | FAT-085 switch → prefs + bus |
| 12 | Scheduled auto-activate by clock | **MISSING** | No timer/cron fires mode from school times |
| 13 | Location / geofence auto-activate (S-SEC-059) | **DOCUMENTED ONLY** | Banner/host map claims; no FS-001 wire |
| 14 | Grace period (0–5, default 2) | **IMPLEMENTED** (domain) / **MISSING** (runtime UX) | `ModeGrace`; no countdown UI/bus field |
| 15 | Manual skips grace | **IMPLEMENTED** | `ModeGrace.manualActivationSkipsGrace` |
| 16 | Child grace “finish” control | **MOCK/SIMULATION** (proto) / **MISSING** Flutter | GAP-A-CHILD-015 risk in proto |
| 17 | Single active mode | **PARTIAL** | `withRow` clears other actives; Register M-B implies multi conflict |
| 18 | Multi-mode stacking / composition | **DOCUMENTED ONLY** / **UNKNOWN** product | `ModeConflictResolver` ready; UI enforces single |
| 19 | Conflict → stricter (intersect allow lists) | **IMPLEMENTED** (pure) / **MISSING** (wired lists + notify) | Unit tests only |
| 20 | Father conflict notification (M-B) | **MISSING** | No notification emission |
| 21 | Allowed-apps list per mode | **DOCUMENTED ONLY** / **MISSING** store | Proto lists; not in `SmartModeRow` |
| 22 | Mode → TimeEngine deny | **PARTIAL** | Flag path works when `modeActive` set |
| 23 | Feed allow-list from Modes into `appAllowedInMode` | **MISSING** | Callers default / ST base; not from FAT-085 |
| 24 | Mode exceptions (Ruling A) | **PARTIAL** | `hasModeException` flag; no ModeException store/UI on FAT-085 |
| 25 | Grant vs mode start (Ruling C) | **IMPLEMENTED** (require choice) / **MISSING** UI | `GrantOnModeStart`; no dialog host |
| 26 | Tighten-only overlays | **DOCUMENTED ONLY** (FS-002/003 L2) / **UNKNOWN** Modes L2 | Proto vacation **loosens** (`strict:0`) |
| 27 | Loosen / widen under mode | **MOCK/SIMULATION** (proto vacation) | Contradicts sibling tighten-only — **Q-MODE-07** |
| 28 | App restriction overlay (contextual) | **PARTIAL** | Flag only; not package policy authorship |
| 29 | Web filter tighten via mode | **DOCUMENTED ONLY** | WF-OD-13; no code binding |
| 30 | Silent rewrite of URL lists by mode | **MISSING** (good absence) | Must stay forbidden per FS-002 |
| 31 | Location/geofence interaction | **DOCUMENTED ONLY** | S-SEC-059 claim; no ownership move found |
| 32 | Screen/camera tighten via mode | **MISSING** | FS-004 discovery: no camera facet |
| 33 | Screen Time minutes/wallet ownership by mode | **MISSING** (correct separation) | Modes must not own wallets |
| 34 | ScheduleWindow → modeActive (sleep/prayer/study) | **IMPLEMENTED** | Competing schedule→mode path under ST |
| 35 | SOS reachable under mode | **IMPLEMENTED** / **DOCUMENTED** | ST final + SOS CTAs; never gated |
| 36 | Child visibility (tint / label) | **PARTIAL** | CHD-004; no app-grid tint of allowed set |
| 37 | Parent AuthZ matrix for modes | **MISSING** | No RoleGuard on FAT-085 |
| 38 | Co-Parent configure / activate | **UNKNOWN** product | Eng doc suggests Full; code open |
| 39 | Offline retain last activation | **PARTIAL** | Bus lean offline; prefs memory store |
| 40 | Device acknowledgement of mode policy | **MISSING** | No ack/version for modes |
| 41 | Multi-device mode sync | **MISSING** | In-process only |
| 42 | Outbox for mode mutations | **PARTIAL** | `_queued` on activation bus; not durable outbox |
| 43 | Drift / SQL persistence for FamilyMode | **MISSING** | schema.sql absent |
| 44 | PolicySyncBus integration for modes | **MISSING** | Bus syncs ST schedule/policy only |
| 45 | Audit events mode.activated / deactivated | **MISSING** | No AuditAppend on FAT-085 |
| 46 | Notifications (pre-activate, grace, conflict) | **MISSING** | Phase4 gap “5 min before” still open historically |
| 47 | Emergency behavior under mode | **DOCUMENTED** | SOS never disabled |
| 48 | Android Focus / DND / Digital Wellbeing hook | **MISSING** / honesty **DOCUMENTED** | FAT-085 eng: OS Focus H |
| 49 | iOS Screen Time / Focus filter hook | **UNKNOWN** / **MISSING** | No implementation |
| 50 | Honesty banner on FAT-085 | **IMPLEMENTED** | Host map S-SEC-058/059 copy |
| 51 | Preview-before-apply (registry FAT-085) | **MISSING** | Registry copy; UI has no preview sheet |
| 52 | Instant lock above modes | **IMPLEMENTED** | TimeEngine ladder |
| 53 | Permanent block above modes | **IMPLEMENTED** | TimeEngine ladder |
| 54 | Allowed-in-mode still needs remaining time | **DOCUMENTED** / **PARTIAL** | Register; algebra continues to cap/wallet after P3 allow |
| 55 | Driving mode (P-10) | **DOCUMENTED ONLY** | Register P-10 — not in BuiltInModeId |
| 56 | Focus Report weekly schedules | **MOCK/SIMULATION** | Adjacent scheduler — not Modes |
| 57 | Outer-circle contact schedules | **MOCK/SIMULATION** | Adjacent — not Modes |
| 58 | Notification quiet-hour windows | **PARTIAL** | Adjacent prefs — not Modes |
| 59 | Temporary grant expiry clocks | **PARTIAL** | ST ownership — intersect modes via Ruling C only |
| 60 | Schema `device_mode` vs lifestyle mode | **IMPLEMENTED** (device linking) | **Not** FS-005 entity — naming collision risk |
| 61 | Child Mode Lock screen | **PARTIAL** | `n05_lock` — device lock UX, not lifestyle mode |
| 62 | Trial / device mode onboarding screens | **PARTIAL** | Naming collision only |
| 63 | Unit tests for mode domain | **IMPLEMENTED** | `smart_modes_test.dart` |
| 64 | Widget tests FAT-085 / CHD-004 mode | **IMPLEMENTED** | Feature tests present |
| 65 | Enforce mode on OS launch intercept | **MISSING** | No agent |
| 66 | Multi-device acknowledgement UI | **MISSING** | — |
| 67 | Mode policy version field | **MISSING** | — |
| 68 | Kernel “mode context fact” typed event | **MISSING** | Flags only today |
| 69 | FS-002 mode_tighten chip (L3 designed) | **DOCUMENTED ONLY** | L3 flows; not Flutter |
| 70 | FS-003 mode tighten chip (L3 designed) | **DOCUMENTED ONLY** | L3 flows; not Flutter |

**Capability rows counted:** **70**

---

## Rollup

| Bucket | Count (approx) |
|---|---|
| IMPLEMENTED | 12 |
| PARTIAL | 18 |
| MOCK/SIMULATION | 8 |
| DOCUMENTED ONLY | 14 |
| MISSING | 14 |
| UNKNOWN | 4 |

---

## Non-additions

Do **not** treat as present: OS Focus Mode enforcement, durable Modes outbox, FamilyMode SQL, geofence school auto-activate, custom mode builder, Modes rewriting URL/package stores, invented stacking law.
