# 01 — Executive Platform Overview (Family OS)

**Product:** Family OS (`family_os` / عائلتي)  
**Primary source of truth:** current repository code  
**Supporting context:** `family-os/`, `handoff/`, `GAP_LOG.md`, `CONVERSION_LOG.md`, `harness/`  
**Discovery date:** 2026-09-23  

---

## Verdict

Family OS today is a **high-coverage Flutter UI + in-process policy simulator** for a frozen Arabic-first family product. It is **not** yet a real multi-device parental-control / family OS runtime with backend sync and OS-level enforcement.

---

## What the platform currently contains (FACT)

1. **Flutter app** `app/` — package `family_os`, Arabic-first RTL, IBM Plex Sans Arabic, go_router.  
2. **Frozen product registry** — `family-os/_REGISTRY/screens.csv` (~130 SCR-* rows; constitution: exactly 129 active screens).  
3. **PostgreSQL data contract (design)** — `family-os/_CONTRACTS/schema.sql` (20 tables, wave 1).  
4. **Policy core** — `app/lib/core/policy/` (PolicyEngine minutes economy, TimeEngine, web filter, SOS ladder, locks, entitlements mocks, AI stage flags, etc.).  
5. **Feature modules** — `n01`…`n17`, `education`, `shared_onboarding`, `shared_templates`.  
6. **Role model** — father / mother / child via `RoleController` + `RoleGuard` (`app/lib/app/`).  
7. **Design system** — `tokens.dart` + shared components under `core/design/`.  
8. **Large widget/unit test suite** — ~170 test files proving UI + mock loops.  
9. **Harness / conversion backlog** — continuous screen/gap shipping loop.  
10. **Mock family seed** — `app/lib/mock/register_mock_family.dart` (Register §10 names live only in `mock/`).

---

## What is actually implemented and working (FACT, in-app)

Working means: navigable UI + repository/service logic + tests, typically with **in-memory** state.

Examples of **stronger** spines (often status **A in-process** / **B real-world**):

- Minutes economy primitives (`Minutes`, `PolicyEngine.earn` path via wallet/attribution tests).  
- Screen-time policy + schedule windows + `PolicySyncBus` same-session child mirror.  
- Web filter evaluate + father preview parity + unlock request approve/deny (+ mother observer denied).  
- Instant lock / mother FULL lock / father unlock supersession.  
- Notification prefs quiet hours with SOS never muted.  
- Privacy collection toggles mirrored to child transparency (same session).  
- Audit append-only repository API (no update/delete on product interface).  
- RoleGuard father-only brain control + billing; owner-only privacy for child block.  
- SOS ladder parents immovable; MockSosFire still delivers under quiet hours.  
- Family shell chrome (tabs/hub/FABs) — StatefulShellRoute deferred.

---

## What is UI / prototype / placeholder (FACT)

- **43 routes** still mount `PlaceholderScreen` in `app/lib/app/router.dart` despite many corresponding `*_screen.dart` files existing under features (especially Wave 2 child-learn and Wave 3 surfaces).  
- Chat, calls, location map, safe zones: **UI + InMemory repositories**, no realtime SDK.  
- Billing: `MockEntitlementService` — UI + architectural tests that SOS/chat are not gated.  
- Advisor/AI: `MockAdvisorRepository` / stage flags — **no on-device inference**, no AI gateway.  
- Device health / camera permission: **Fake* seams**.  
- Onboarding account/login: mock-first navigation, **no real auth**.

---

## Backend, database, sync, device, policy (FACT)

| Concern | Status | Evidence |
|---|---|---|
| Backend API server | **H NOT FOUND** | No `backend/` / `server/`; empty feature table in root `API_CONTRACT.md` |
| Firebase | **H NOT FOUND** | No deps / imports |
| Runtime DB (Postgres/SQLite) | **H / E** | Schema contract only; app comments say Drift later |
| Local durable prefs | **F** | Memory `*PrefsStore`; SharedPreferences not in pubspec |
| Sync/outbox | **F (in-process)** | `PolicySyncBus`, `DesiredMonitoringSyncBus`, etc. — not network |
| Device Owner / VPN / Accessibility | **H NOT FOUND** | `MainActivity.kt` = `FlutterActivity` only |
| Policy logic | **A/B in-app** | Rich pure Dart policy under `core/policy/` |
| Push notifications | **H / F** | Delivery logic simulated; no FCM |

---

## Real user journeys today (summary)

- **Father:** Can walk most Wave-1/settings spines in the app; configure mock policies; see same-session mirrors; cannot enforce on a physical child phone.  
- **Mother:** Invite + permission level UI; some approve gates (`MotherLevel`); blocked from brain control & billing; SOS receipt always on. Incomplete vs father for many domains.  
- **Child:** Child screens exist; role switch in-app; day board / expiry / SOS UI; **no OS-level lock/filter**. Many learn routes still placeholders in router.

Detail: docs `06`–`09`.

---

## Biggest experience gaps (summary)

1. Screen ↔ real behavior (enforcement) gap.  
2. Feature file ↔ route wiring gap (placeholders).  
3. Backend absence.  
4. Multi-device sync absence.  
5. Co-parent depth incomplete.  
6. Education loop open (GAP_LOG P15-EDU-006/007).  
7. “Closed” GAP_LOG items ≠ real-world complete.

---

## FACT vs INFERENCE

| Statement | Label |
|---|---|
| pubspec is mock-first with no Firebase/Drift/HTTP | FACT |
| schema.sql describes intended Postgres model | FACT |
| Real child device will not be locked by current Android code | FACT |
| Product intent is a full family OS with enforcement | INFERENCE from docs/handoff (not proven by runtime) |
| External backend may exist elsewhere | UNKNOWN |

---

## Related docs

See `15_MASTER_DISCOVERY_SUMMARY.md` for the full package map.
