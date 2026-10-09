# Family OS — Master Discovery Summary

**Product:** Family OS (`family_os` / عائلتي)  
**Repository:** `D:\special projects\family`  
**Discovery date:** 2026-09-23  
**Mode:** Discovery only — documentation under `docs/experience_discovery/`. **No application code was modified.**

This file is the **single entry point** for the discovery package. Read the numbered companions for depth.

---

## 1. What this platform is (FACT)

Family OS is a **mock-first Flutter conversion** of a frozen 129-screen Arabic-first family digital-wellbeing product.

Evidence:

- `app/pubspec.yaml` — `name: family_os`; description: **"Mock-first Flutter app"**; dependencies only `flutter`, `flutter_localizations`, `cupertino_icons`, `intl`, `go_router`.
- Authority sources: `family-os/` (prototype + `_REGISTRY/screens.csv` + `_CONTRACTS/schema.sql`), `handoff/`, constitution in `.cursor/rules/constitution.mdc`.
- Active harness conversion loop: `harness/LOOP_STATE.md` (card work ongoing; education lane open).

**Branding note:** All discovery docs use **Family OS / family-os**. Do not treat “Guardian Eye Pro” as the product name for this repository’s current codebase.

---

## 2. One-line reality check

| Layer | Reality |
|---|---|
| UI screens | Large surface: ~131 `*_screen.dart` files; ~129–130 registry routes |
| In-process policy / role / loops | Strong for a subset of Wave-1/settings spines (minutes, schedules, web filter, SOS prefs, locks, mother levels) |
| Persistence | In-memory / memory “Prefs” stores — **SharedPreferences package not in pubspec** |
| Backend API / DB runtime | **NOT FOUND** in this repo (`backend/`, `server/` absent; no Firebase) |
| Device enforcement (VPN, DO/PO, Usage Access, Accessibility) | **NOT FOUND** — Android `MainActivity` is bare `FlutterActivity` |
| Real parent↔child multi-device sync | **Mock same-session buses only** (`PolicySyncBus`, etc.) |
| Real push notifications / LiveKit / maps SDK | **NOT FOUND** in dependencies |

---

## 3. Counts (FACT)

| Item | Count | Evidence |
|---|---|---|
| Registry screen rows (`screens.csv`) | ~130 SCR-* (constitution target 129; tombstones excluded from routes) | `family-os/_REGISTRY/screens.csv` |
| Generated route screen IDs | 130 listed in `generatedScreenIds` | `app/lib/app/router.dart` |
| Flutter `*_screen.dart` under features | **131** | Glob `app/lib/features/**/*_screen.dart` |
| Routes still using `PlaceholderScreen` | **43** | Count of `PlaceholderScreen(` in `router.dart` |
| `ComingSoonScreen` routes | 1 (`SCR-FAT-075`) | `router.dart` |
| `*_repository.dart` files | **98** | Under `app/lib/` |
| Test files (`*_test.dart`) | **~170** | Under `app/test/` |
| PostgreSQL contract tables (wave 1) | **20** | `family-os/_CONTRACTS/schema.sql` |
| Firebase / Firestore / Auth packages | **0** | Grep + pubspec |
| SQLite/Drift/Hive packages | **0** | Grep + pubspec |
| HTTP client packages | **0** | pubspec |

---

## 4. Major domains discovered

1. Shared onboarding / account / device mode  
2. Family linking / QR pairing / mother invite  
3. Day board / children / alerts / location UI / chat UI / calls UI  
4. Screen time / minutes economy / time requests  
5. Web filter / unlock inbox  
6. Instant lock / anti-tamper / child-mode lock  
7. Notifications prefs  
8. Privacy / audit / transparency  
9. Advisor / AI surfaces (mock)  
10. Platform monitoring honesty / smart alerts  
11. Smart modes  
12. Emergency / SOS  
13. Billing UI (mock entitlement)  
14. Devices / family members / mother permission level  
15. Education studio + child learn (many screens exist; **many routes still placeholders**)  
16. Calendar / tasks  
17. Coming-soon catalog  

---

## 5. Status vocabulary used in this package

| Code | Meaning |
|---|---|
| **A** | Implemented + connected **inside the Flutter process** (same-session loops proven by tests) |
| **B** | Implemented but partial (UI + some logic; missing persistence, device, or multi-device) |
| **C** | UI only / prototype rendering |
| **D** | Backend-only (contracts/schema/docs; no app runtime) |
| **E** | Data model only |
| **F** | Placeholder / mock / stub |
| **G** | Broken / disconnected (e.g. screen file exists, route still `PlaceholderScreen`) |
| **H** | Not found |

**Critical distinction:** **A** here does **not** mean production-ready on real child devices. It means the app’s mock policy layer closes a loop in-process.

---

## 6. Most important confirmed gaps

1. **No production backend** — schema + empty `API_CONTRACT.md` only.  
2. **No real device enforcement** — no VPN/MDM/Usage Stats native code.  
3. **No durable local DB** — “Prefs*” repos use memory maps; Drift deferred in comments.  
4. **43 registry routes still `PlaceholderScreen`** while parallel feature screens often exist → **G disconnected**.  
5. **Education P15-EDU-006/007 open** — child submit does not feed FAT-050; materials toast-only (`GAP_LOG.md`).  
6. **Chat/calls/location/maps** — UI + in-memory repos; no LiveKit/maps/GPS SDKs.  
7. **Mother experience** — levels exist in domain + some approve gates; many journeys still father-centric / mock.  
8. **Constitution aspirational vs stack** — docs mention Riverpod/freezed/EventBus; app uses `ChangeNotifier` + go_router only.  
9. **Closed SET/UI gaps** are closed at **mock policy** level — not real OS enforcement.  
10. **Misleading production appearance** — polished UI + green widget tests can look “done” while enforcement is absent.

---

## 7. Major unknowns

- Whether any external Family OS backend exists **outside** this repo.  
- Exact completeness of every Wave-3 screen’s widget wiring vs placeholder route (spot-checked; full matrix in `10_IMPLEMENTATION_STATUS_MATRIX.md`).  
- Future Drift/SharedPreferences adapter timeline (comments say “adapter-ready”).  
- iOS child-device capability path beyond honesty table fixtures.  
- LiveKit / map provider selection for real comms/location.

---

## 8. Document map

| # | File | Purpose |
|---|---|---|
| 01 | `01_EXECUTIVE_PLATFORM_OVERVIEW.md` | Executive truth |
| 02 | `02_FEATURE_DOMAIN_INVENTORY.md` | Domains |
| 03 | `03_SCREEN_AND_NAVIGATION_INVENTORY.md` | Screens & routes |
| 04 | `04_ARCHITECTURE_AND_SERVICE_MAP.md` | Architecture |
| 05 | `05_DATA_BACKEND_SYNC_MAP.md` | Data / sync |
| 06 | `06_PARENT_EXPERIENCE_BASELINE.md` | Father journeys |
| 07 | `07_COPARENT_EXPERIENCE_BASELINE.md` | Mother journeys |
| 08 | `08_CHILD_EXPERIENCE_BASELINE.md` | Child journeys |
| 09 | `09_END_TO_END_USER_JOURNEYS.md` | E2E chains |
| 10 | `10_IMPLEMENTATION_STATUS_MATRIX.md` | Status matrix |
| 11 | `11_EXPERIENCE_GAP_REGISTER.md` | Gaps |
| 12 | `12_CRITICAL_DEPENDENCIES_AND_RISKS.md` | Risks |
| 13 | `13_OPEN_QUESTIONS_AND_UNKNOWN_FACTS.md` | Unknowns |
| 14 | `14_RECOMMENDED_EXPLORATION_ORDER.md` | Next exploration order |
| 15 | **This file** | Entry point |

**Archive:** `docs/experience_discovery.zip`

---

## 9. Confirmation

- Repository inspected: **Family OS** at `D:\special projects\family` only.  
- Application / Flutter feature code: **not modified** in this discovery pass.  
- Deliverable: documentation + ZIP under `docs/`.
