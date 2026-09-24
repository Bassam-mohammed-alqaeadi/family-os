# Family OS — Frontend-First Plan: Turning Simulations into a Real App

Companion to `PRODUCTION_READINESS_AUDIT.md`. Answers: *how do we make the simulations real, starting with a complete UI/UX frontend, and add the backend later?*

> **Superseded on ordering by [`UI_UX_FIRST_PLAN.md`](./UI_UX_FIRST_PLAN.md).** That document keeps this one's architecture (the 6 ports, `AppScope`, local-first) but re-orders execution: **complete every screen and per-role control panel first (its Waves 0–2), then remove all simulation (its Wave 3), then backend (Wave 4)**. Its key addition is freezing the 6 port *interfaces* in Wave 0 so screens are authored against interfaces, never fixtures — which is what lets the UI be finished before persistence and still need zero rewrites later. Read this file for the *why*, `UI_UX_FIRST_PLAN.md` for the *what and when*.

---

## 0. The reframe (read this first)

**Most of this app's "mocks" are not backend problems. They are device-capability problems.**

Of the 12 `MOCK-REMOTE` / `NOT_IMPLEMENTED` capability rows, only **four** actually require a server:

| Needs a server | Does NOT need a server (device-local) |
|---|---|
| `fs006.remote_delivery` (SOS → parent's phone) | `fs001.native_gps` — device GPS |
| `fs_a.mock_remote` (cloud sync) | `fs003.os_intercept` — AccessibilityService/DeviceAdmin |
| Real auth + multi-device accounts | `fs002.native_block` — VpnService DNS filtering |
| Email/SMS invites, cloud backup, remote audit | `fs005.os_wake` — AlarmManager/WorkManager |
| | `fs004.capture_pipeline` — MediaProjection + Accessibility |
| | `fs004.camera_os_plane` — DeviceAdmin camera disable |

That split is the whole strategy. **You can ship a genuinely working product with no backend at all**, because this is a single Flutter app that runs as *both* parent and child (`device_mode_screen.dart` switches `AppRole.child`; `_noHubScreenIds` and `childShellTabs` confirm the dual surface). Parent and child on the same device — or two devices in the same household later — can have real GPS, real app blocking, real timers, real alarms today.

**And critically: you cannot finish UI/UX on fixtures.** Loading, empty, error, offline, conflict, stale-data and "enforcement not verified" states *are* the UX of a family-safety app. They only exist once data is real and persisted. That is why persistence and dependency injection come first in this plan — not because they are backend work, but because they are what makes the UI/UX real rather than staged.

Second reframe: **`CapabilityRegistry` is already your roadmap tracker.** Every row you flip from `MOCK-REMOTE` to `IMPLEMENTED` is a phase gate, and you already ship the UI to display it (`capability_honesty_badge.dart`, `enforcement_status_badge.dart`). Use it as the definition of done. Do not delete that mechanism — it is the best asset in this codebase.

---

## 1. Target architecture: local-first with frozen ports

```
                    ┌──────────────────────── UI (131 screens) ────────────────────────┐
                    │  reads/writes via AppScope, never via process globals             │
                    └───────────────────────────────┬──────────────────────────────────┘
                                                    │
                    ┌─────────────── Repositories (SQLite via FsSessionKernel.db) ─────┐
                    │  Location · WebFilter · AppControl · ScreenCamera · Modes        │
                    │  SOS · AI Safety  +  NEW: roster, chat, calls, calendar, tasks   │
                    └───────────────────────────────┬──────────────────────────────────┘
                                                    │
   ┌───────────────────────── PORTS (frozen interfaces — backend plugs in here) ───────┐
   │  1. RemoteSyncPort        exists  (MockRemoteAdapter)  → real HTTP later          │
   │  2. PolicyDeliveryPort    TODO    (drives Configured→…→Verified)                  │
   │  3. IdentitySource        TODO    (replaces createStage1IdentityRuntime)          │
   │  4. NotificationGateway   TODO    (local notifications now, FCM later)            │
   │  5. CallMediaPort         TODO    (local now, WebRTC later)                       │
   │  6. LocationSource        TODO    (MANUAL now, geolocator later)                  │
   └───────────────────────────────────────────────────────────────────────────────────┘
                                                    │
                    ┌──────────── Native platform layer (currently missing) ───────────┐
                    │  Zero MethodChannels today; MainActivity.kt is stock FlutterActivity │
                    │  ADD: FamilyOsPlugin.kt → GPS · alarms · Accessibility · VpnService  │
                    └───────────────────────────────────────────────────────────────────┘
```

**Rule: no feature code may import a concrete adapter.** Today 33 `stage1*` singletons and 104 `InMemory*` classes are imported directly by screens. That is the single thing blocking every other step.

### The 6 ports to freeze now

Each is a plain `abstract class` with one local implementation today and one remote implementation later. Freeze the interface, never the impl.

1. **`RemoteSyncPort`** — already exists and is well designed (`enqueue` / `pending` / `flush`). Keep as-is. Real impl = HTTP + auth + retry/backoff.
2. **`PolicyDeliveryPort`** — this is the important one. `policy_delivery.dart` already defines the exact honest vocabulary: `Configured → Published → Delivered → Applied → Verified`, monotonic, version-resetting. **Build the full UX on it now**, advancing phases locally and honestly. When the backend lands, the server drives `Published` and the child device reports `Applied`/`Verified` — the UI does not change at all. This is the best-designed seam you have; exploit it.
3. **`IdentitySource`** — today returns a locally-created account persisted in secure storage. Later returns server auth. Delete `createStage1IdentityRuntime()` behind it.
4. **`NotificationGateway`** — `show(childId, kind, payload)`. Local notifications now; FCM later. Same call sites.
5. **`CallMediaPort`** — in-app audio/video; local loopback now, WebRTC later.
6. **`LocationSource`** — a `Stream<LocationFix>` producer. Ships a `ManualLocationSource` (for honest testing/demo) today; `GeolocatorLocationSource` in Phase 2. Nothing else in the app changes because `LocationDomainRepository.appendFix(LocationFix)` is already the intake.

### Dependency injection (the prerequisite)

Replace the `widget.projectionRepository ?? stage1DayBoardProjectionRepository` pattern in all 131 screens with a single composition root:

- Add an `AppScope extends InheritedWidget` exposing the six ports plus a `Repositories` bundle.
- Screens become `AppScope.of(context).dayBoard` — no `stage1*` globals, no `??` fallbacks.
- Tests wrap the widget in an `AppScope` with fakes. This **fixes the 2 order-dependent test failures** as a side effect, because the mutable process-globals disappear.
- Keep it dependency-free (no `provider`/`riverpod` needed) or adopt Riverpod if you want `AsyncNotifier` for the loading/error states — either is fine, but decide once and apply everywhere.

---

## 2. Work phases

### Phase 1 — Foundation: real persistence + real DI (3–4 weeks)
*Goal: the app stops forgetting things and stops importing fixtures. UI/UX becomes buildable.*

1. Fix the P0 blockers from the audit (delete `AGENT_DEBUG` writers including the `tool/gen_routes.dart` emitter; declare Android permissions + iOS usage strings; delete `test/debug_sys3_route_probe_test.dart`; fix the `e.toString()` leak; add CI).
2. Add `AppScope` + `Repositories`; delete all `stage1*` global instances from `lib/mock/` and the 104 `InMemory*` classes (keep them as test doubles under `test/`, not `lib/`).
3. **Extend `FamilyLocalSchema` to v11+** with tables for the screens still on memory: roster/children, chat threads+messages, call log, calendar events, tasks, notifications, settings/prefs, onboarding progress. Add repositories over `FsSessionKernel.db` mirroring the existing FS-001…007 style.
4. Replace `Memory*PrefsStore` with a real `shared_preferences` (or SQLite KV) adapter — the `SchedulePrefsStore` seam was designed for exactly this.
5. Delete `RegisterMockFamily` from the production path; make `day_board_projection.dart:153` return a genuine empty projection. Every screen must render its real empty state.
6. Make onboarding create real entities: `CreateAccountScreen` → local account in secure storage; `CreateFamilyScreen` → real `Family` + `FamilyMembership`; `AddChildScreen` → real `ChildIdentity`. Then `LoginScreen` authenticates against the local store instead of navigating.
7. Add `flutter_secure_storage` + SQLCipher.
8. Rename the 259 `Stage-1` comments into a real backlog (file issues; delete the prose).

**Gate:** kill and relaunch the app — every setting, child, task and message survives. Zero `stage1*` imports remain in `lib/`.

### Phase 2 — Device capability: make enforcement real, no backend (6–10 weeks)
*Goal: the product's core promise actually works on one device. This is native work.*

1. **Native bridge.** Create `FamilyOsPlugin.kt` + a Dart `FamilyOsPlatform` facade. There is currently **zero** `MethodChannel` in the project and `MainActivity.kt` is a stock 5-line `FlutterActivity`.
2. **GPS** → `geolocator` → `GeolocatorLocationSource` → `appendFix`. Flip `fs001.native_gps` to `IMPLEMENTED`. This alone lights up the whole location stack (zones, geofence ENTER/EXIT, trail, SOS evidence) that is already built and tested but starved of input. Replace the `CustomPaint` map with `flutter_map` (OSM) or Google Maps.
3. **Mode wake** → `AlarmManager` (Android) / `BGTaskScheduler` (iOS) → flip `fs005.os_wake`. This is the highest-credibility fix in the whole plan: right now a bedtime mode does nothing unless someone opens the app.
4. **App intercept** → `AccessibilityService` + `UsageStatsManager` + `DeviceAdminReceiver` → flip `fs003.os_intercept`. Persist dispositions in the existing `ac_document`/`ac_exception` tables.
5. **Local notifications** → `flutter_local_notifications` for tamper alerts, time-expiry, approvals, SOS receipts on the same device. Flip nothing (new capability row).
6. **Web filter** → `VpnService` with DNS-level allow/block driven by the existing `wf_document`. Heaviest item; flip `fs002.native_block` only when DNS enforcement is verified end-to-end. Present it honestly as "DNS filter active" vs "policy configured" using the existing badge components.
7. **Screen/camera policy** → `MediaProjection` + Accessibility for capture monitoring; `DeviceAdmin` for camera disable. Flip `fs004.capture_pipeline` and `fs004.camera_os_plane` *only to the degree actually enforced*.
8. **Real pairing.** QR encodes a locally-generated key pair + family/device IDs; handshake local (same device or LAN). No server needed for a household.
9. Haptics on SOS fire/ack, lock/unlock, approve/deny, destructive confirms (currently 0 `HapticFeedback` calls).

**Gate:** on a real Android device, set a bedtime — the device actually locks at that time with the app closed. Add a zone — walking out fires a real ENTER/EXIT event.

### Phase 3 — Full UI/UX build-out (4–6 weeks, partly parallel with Phase 2)
*Goal: production-grade frontend. Now that data is real, all the states exist to be designed.*

1. **Type scale** — add `FamilyTypography` `ThemeExtension`, 9–11 steps, Arabic-tuned `height`/`letterSpacing`. Delete all 1,078 inline `fontSize:` literals. This is the single highest-leverage visual change.
2. **Responsive layout** — `FamilyBreakpoints` + a `MaxWidthBox` wrapper; tablet/landscape 2-column for boards; hub grids reflow 2→3→4. Only 5/131 screens use `LayoutBuilder` today.
3. **State components** — `AppSkeleton` (shimmer: card/board/list variants) to replace 102 raw spinners; unify `AppErrorState` across all 131 screens with localized messages + retry + offline variant; add pull-to-refresh to every async surface.
4. **Dynamic type** — zero `textScaler` handling today. Golden-test every screen at `textScaler: 1.5`; fix overflows the 1,078 fixed sizes create (removing them in step 1 solves most).
5. **Icon system** — replace the 15 emoji nav icons in `shell_config.dart` with one vector set (Material Symbols). Emoji tabs next to 144 Material icons in screens is the most visible quality ceiling.
6. **Shell declutter** — `_HubStrip` holds up to 22 tiles at `maxHeight: 220` with FABs at hardcoded `bottom: 260/72`. Cap at 6–8 + "More", use real `Scaffold.floatingActionButton`, remove the 33 magic `Positioned`s.
7. **Contrast** — darken `ink2` (`#8A8FA3` ≈ 3.0:1, fails AA for body text) to ~`#6B7085`; audit all token pairs.
8. **Language switch** — make it real (persist locale, add a `ValueNotifier<Locale>` above `MaterialApp.router`). English ARB is complete and unreachable.
9. **Dark mode** — tokens are already `ThemeExtension`-structured, so this is cheap now and expensive after 131 screens hardcode light assumptions.
10. **Per-screen upgrades** — day board, children list, settings hub, plans, map, child surfaces (see audit §3.6).

**Gate:** every screen passes a golden at 1.5× text scale, on a 600 dp tablet, and in English and Arabic, with no overflow.

### Phase 4 — Backend (later, 8–12 weeks)
Only now. Implement the six frozen ports against a real service; take `PolicyDeliveryPhase` advancement from local to server-driven; add FCM; add real cross-device sync with the conflict policy you chose in Phase 1. **No UI changes should be required** — if any are, a port was leaked in Phase 1–3.

---

## 3. Screen-by-screen: what becomes real, and when

| Feature area | Simulated today | Becomes real in | Needs backend? |
|---|---|---|---|
| GPS, safe zones, trail | `CustomPaint` map, injected fixes | P2 | No |
| Geofence ENTER/EXIT alerts | Logic real, no input | P2 | No |
| Bedtime / smart modes | Evaluated only on app open | P2 | No |
| App blocking | Dispositions in SQLite only | P2 | No |
| Web filter | Policy configured, no DNS plane | P2 | No |
| Screen/camera prevent | Policy configured | P2 | No |
| Local alerts (tamper, expiry) | None | P2 | No |
| Child device pairing (QR) | Painted mock | P2 (local handshake) | No |
| Children roster, tasks, calendar | `InMemory*` | P1 | No |
| Chat / calls | `InMemory*`, no transport | P1 (persist) → P4 (transport) | P4 |
| Child learning, Quran, wallet | In-memory demo data | P1 | No |
| Language switching | Toast only | P3 | No |
| Auth / account | `acc_stage1_father` fixture | P1 (local) → P4 (server) | P4 |
| Billing / subscription | `MockEntitlementService` | P4 (`in_app_purchase`) | No, but store console |
| SOS → parent's phone | No `remote_delivery` | P4 | **Yes** |
| Cloud sync / backup | `MockRemoteAdapter` outbox | P4 | **Yes** |
| Remote audit trail | Local table only | P4 | **Yes** |
| Email/SMS invites | Toast | P4 | **Yes** |
| Cloud AI classification | `UNSUPPORTED` by design | — | Product decision |

**Note:** only 4 of 24 rows need a server. That is the headline of this plan.

---

## 4. What stays simulated in the frontend phase — say so in the UI

Do not fake these. Use the existing honesty components to state them plainly:

- Family members on **different devices** (single-device works fully; cross-device needs P4).
- SOS **arriving on someone else's phone** (on-device escalation works; remote needs P4).
- Cloud backup / restore across devices.
- Anything the target platform genuinely cannot do — iOS web filtering and app interception are far more restricted than Android; the registry already flags `UNSUPPORTED` territory. Launch Android first.

The `CapabilityStatus` enum + `capability_honesty_badge.dart` already exist for this. Keep every row honest at every phase; the badge flipping from `MOCK-REMOTE` to `IMPLEMENTED` is your release note.

---

## 5. Sequencing summary

```
P1 Foundation      ████░░░░░░░░░░░░░░░░  3–4 wks   persistence · DI · kill fixtures · P0 blockers
P2 Device capab.   ░░░░████████████░░░░  6–10 wks  GPS · alarms · intercept · VPN · notifications
P3 UI/UX           ░░░░░░░░░██████████░  4–6 wks   type scale · responsive · states · a11y · dark
P4 Backend         ░░░░░░░░░░░░░░░░████  8–12 wks  real sync · auth · FCM · cross-device
                                    ↑
                    ~14–20 wks to a real, working, backend-free v1 (Android)
```

Do P3 partly in parallel with P2 — the type scale and state components are independent of native work and will make every subsequent screen review cheaper.

---

## 6. The three decisions to make before writing code

1. **Single app or two apps?** One Flutter app with a role switch (current design) is simpler and the QR/pairing story is easier, but the child agent needs aggressive background/native privileges that Play Store review scrutinises. Consider one codebase with a **child flavor** (`applicationId` suffix + child-only manifest) so the parent app can stay permission-light.
2. **Android-first, or both?** iOS cannot enforce web filtering or app interception the way Android can. Shipping Android first, with iOS as a degraded observer-only client, is honest and much faster. Decide now — it changes Phase 2 scope by ~2× .
3. **State management:** stay `InheritedWidget`-based, or adopt Riverpod for `AsyncNotifier` loading/error handling across 131 screens? Decide before Phase 1 so the 131 screens get migrated once.
