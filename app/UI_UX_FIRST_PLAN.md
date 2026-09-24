# Family OS — UI/UX-First Plan: Complete Every Screen & Control Panel, Then Go Real

Companion to `PRODUCTION_READINESS_AUDIT.md` (what's broken) and `FRONTEND_FIRST_PLAN.md` (the architecture strategy).

**This document re-orders the work to match your priority:**

```
Wave 0–2   Complete every screen + per-role control panel + UX systems        ← your goal #1
Wave 3     Remove all simulation → real app, backend-ready (no server needed)  ← your goal #2
Wave 4     Backend + full APIs                                                  ← later
```

Everything below is grounded in the actual code — verified counts, real screen IDs, real role rules.

---

## Part 0 — The one hard truth, and the move that solves it

You cannot *finish* a screen on fixture data. Empty, loading, error, offline, stale, "not verified yet", "denied by role", "capability not supported on this device" — those states **are** the UX of a family-safety app, and they do not exist while data is fake.

The old plan therefore put persistence first. That fights your ordering. There is a better move:

> **Freeze the six port interfaces in Wave 0, and author every screen against them — never against a fixture.**

Concretely, in Wave 0 we add `AppScope` (an `InheritedWidget` composition root) and the six `abstract class` ports (`RemoteSyncPort`, `PolicyDeliveryPort`, `IdentitySource`, `NotificationGateway`, `CallMediaPort`, `LocationSource`). In Waves 0–2 the implementations behind those ports are still in-memory. **But the screens never know that.** Every screen:

- imports only interfaces, never `lib/mock/`
- handles all seven states honestly
- reads/writes `AppScope.of(context).x` with no `?? stage1Foo` fallback

Then Wave 3 swaps the implementations behind the frozen ports — SQLite, secure storage, native bridges, real auth. **Zero screen rewrites.** You get your ordering *and* you never do the 130 screens twice. This is the single most important decision in this plan.

The second truth, stated plainly: **"no simulation left" ≠ "backend exists."** Only 4 of 24 feature areas truly need a server (SOS-to-another-phone, cloud sync, cross-device accounts, email/SMS invites). Everything else is device-local and can be made genuinely real — real GPS, real alarms, real app blocking, real local persistence — with **no backend at all**. Wave 3 delivers that. Wave 4 is the server.

---

## Part 1 — The role model is the spine of the control panels

Verified from code, not assumed:

| Fact | Source |
|---|---|
| `enum AppRole { father, mother, child }` | `lib/core/domain/role.dart:5` |
| `enum MotherLevel { observer, partner, full }` | `lib/core/domain/mother_level.dart` |
| `WebUnlockActor.canApproveUnlock`: father always; mother only at `partner`/`full`; child never | `mother_level.dart` |
| `ownerOnlyScreenIds` = `SCR-FAT-059` (privacy), `SCR-FAT-060` (audit) — child blocked, mother allowed | `lib/app/role_guard.dart:29` |
| `fatherOnlyScreenIds` = `SCR-FAT-029` (brain control), `SCR-FAT-031` (mother level), `SCR-FAT-056` (plans), `SCR-FAT-057` (manage subscription) | `lib/app/role_guard.dart:44` |
| `canShowSosMuteControl()` returns `false` for **every** role — deliberately | `role_guard.dart` |
| Role switch lives at `SCR-SHR-008` (`device_mode_screen.dart`) | `lib/features/shared_onboarding/` |

So there are **four panel identities**, not two:

```
┌─ ① OWNER PANEL ────────── Father ──────────────────────────────────────┐
│  5 tabs · 86 FAT screens · all 4 father-only screens · owner-only       │
├─ ② CO-PARENT PANEL ────── Mother × 3 levels ────────────────────────────┤
│  Same 5 tabs, minus 4 father-only screens. THREE distinct experiences:  │
│   observer → read-only + "ask father" affordances                       │
│   partner  → + approval inbox (web unlock, time, app requests)           │
│   full     → + rule editing                                             │
├─ ③ CHILD PANEL ────────── Child ────────────────────────────────────────┤
│  4 tabs · 37 CHD screens · zero control surfaces · requests instead      │
├─ ④ SHARED / SYSTEM ────── Role-agnostic ────────────────────────────────┤
│  7 SHR screens: onboarding, invites, pairing, device-mode switch          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Two gaps this plan must fix

**Gap 1 — authority is under-modelled.** `MotherLevel` gates exactly one thing today (`canApproveUnlock`). There is no single declaration of "who may do what." Add:

- **`PanelProfile`** — derived from `(AppRole, MotherLevel?)`, describes the panel's capabilities.
- **`PermissionMatrix`** — one table: `capability × role × level → {allow, readOnly, requestOnly, hidden}`. Consumed by all four places that need it: router redirect, hub tile filtering, in-screen control enable/disable, and audit labels. One source of truth instead of scattered `if (role == …)`.
- **`RoleGate` widget** — renders allow / read-only / request-only / hidden consistently, so a gated control never just "does nothing."

**Gap 2 — "son" and "daughter" are not roles.** The code has one `child` role. That is correct: sex/age personalisation belongs in the **child profile** (`ChildId` + profile data), not in an authorization role. Recommendation: keep it that way. If you want genuinely different child *layouts* (younger vs teen), model it as a `ChildProfileMode` (e.g. `kid / teen`) that skins the same panel — not as a new `AppRole`.

---

## Part 2 — What a "control panel" is: a 4-layer grammar

The problem today is that control elements are spread without a rule. `_HubStrip` holds up to **22 tiles** at `maxHeight: 220` with FABs at hardcoded `bottom: 260/72` — the nav gets pushed below the fold on the app's primary screen. Fix it by declaring where elements are allowed to live.

### The layers

| Layer | What it is | Today | Rule |
|---|---|---|---|
| **L0 Shell** | Tab bar + hub strip + FAB | 5 parent / 4 child tabs; hub 5–22 tiles; 2 hardcoded FABs | Child's content area ≥ 65% of viewport. Hub ≤ 8 tiles + "More". Max 1 FAB, contextual, from `Scaffold.floatingActionButton` — delete the 33 magic `Positioned`s. |
| **L1 Tab panel** | The hub grid for one tab | `hubIndex`: today 14 · kids **22** · family 11 · studio 13 · settings 15 · myday 5 · learn 14 · cfam 8 · me 5 | ≤ 3 sections (e.g. *Watch / Control / Configure*); ≤ 8 tiles per section; each tile = icon + label + live status chip. |
| **L2 Screen** | A working surface | 130 screens, inconsistent | Header (title + status badges) → primary action zone (≤ 2 primary buttons) → control sections → danger zone last. |
| **L3 Control row** | One setting | Bare `Switch`/`Slider`/`ListTile` | Label · current value · control · one-line "what this does" · honesty badge. Never a control without a visible current state. |

### Element-distribution rules (the "flexible UX" contract)

1. **Progressive disclosure:** simple first, advanced behind "متقدم". A panel shows ≤ 7±2 rows per section.
2. **Every enforcement control shows its real status.** If it only configures and does not enforce, the badge says so (`MOCK-REMOTE` / `Configured but not applied`). You already own `capability_honesty_badge.dart` and `enforcement_status_badge.dart` — make them mandatory in the control library.
3. **Role-gated controls are *visible but explained*, not invisible** — except where invisibility is the safety feature (SOS mute, child control surfaces). Say which is which in `PermissionMatrix`.
4. **Irreversible actions** → confirmation sheet; type-to-confirm for anything destroying data or leaving the family.
5. **One primary action per screen.** Everything else is secondary/tertiary.
6. **The child's "control panel" is a request panel.** Every control the child lacks becomes a request with a visible lifecycle — `Configured → Published → Delivered → Applied → Verified` from `lib/core/policy/policy_delivery.dart`. This is the most under-exploited asset in the codebase: build the full delivery-status UX now, and Wave 4's server drives the same components with zero UI change.

### The control widget library (build once in Wave 1)

`lib/core/design/components/` has a good start (`components.dart`, `hub_grid.dart`, `tabs_bar.dart`, `family_ui_mode.dart`, the two badges). Add the missing panel primitives so 130 screens compose instead of inventing:

`PanelSection` · `PanelTile` (icon/label/status) · `SettingToggle` · `SettingChoice` · `SettingSlider` · `SettingSchedule` · `SettingEntityPicker` (which child? which device?) · `SettingStatusRow` (read-only variant) · `HonestyRow` · `ApprovalQueueCard` · `RequestLifecycleTracker` (the 5 phases) · `RoleGate` · `DangerZone` · `ConfirmSheet` · `ExplainerRow` · `AppSkeleton` · `AppEmptyState` · `AppErrorState` · `AppOfflineBanner` · `AppStaleBanner`.

---

## Part 3 — The UX systems (what "flexible and consistent" means concretely)

Ten systems, each with the measured defect and the target.

| # | System | Measured today | Target |
|---|---|---|---|
| 1 | **Typography** | 1,078 inline `fontSize:` literals across ~25 sizes; theme defines 4 of ~15 styles; only 5/131 screens use theme text styles | `FamilyTypography` ThemeExtension, 9–11 steps, Arabic-tuned `height`/`letterSpacing`. **Zero** inline sizes. Highest-leverage change in the plan. |
| 2 | **Spacing & density** | Ad-hoc paddings | `FamilySpacing` scale (4/8/12/16/24/32) + a density mode (comfortable/compact) for tablet |
| 3 | **Color & contrast** | `ink2` `#8A8FA3` ≈ 3.0:1 — fails WCAG AA for body text | Darken to ~`#6B7085`; audit every token pair; token-only colors enforced by lint |
| 4 | **Shape & elevation** | Inconsistent | Radius + elevation tokens; one card style per role panel |
| 5 | **Iconography** | 15 **emoji** nav icons vs 144 Material icons in screens | One vector set (Material Symbols), filled/outlined by state |
| 6 | **Layout / responsive** | 5/131 screens use `LayoutBuilder` — no tablet, no landscape | `FamilyBreakpoints` (360/600/900) + `MaxWidthBox`; boards go 2-column on tablet |
| 7 | **Navigation shell** | Hub up to 22 tiles; FABs at hardcoded `bottom: 260/72`; nav below the fold | Declutter to ≤ 8 + "More"; real FAB; nav always visible; deep-link-safe |
| 8 | **State system** | 102/131 raw spinners; only 22/131 have error states; raw `e.toString()` leaks at `day_board_screen.dart:132` | 7 authored states per screen (skeleton/empty/error/offline/stale/denied/populated), localized, with retry |
| 9 | **Honesty & status** | Badge components exist but are used ad hoc | Every capability-dependent surface declares its real status; the badge flipping `MOCK-REMOTE → IMPLEMENTED` is your release note |
| 10 | **Input, feedback & a11y** | **Zero** `HapticFeedback` calls; zero dynamic-type handling; AR reachable, EN written but unreachable (`main.dart` hardcodes `Locale('ar')`) | Haptics on SOS fire/ack, lock/unlock, approve/deny, destructive confirm; dynamic type safe at 1.5×; ≥48dp targets; semantics labels; real persisted EN/AR switch; dark mode |

Plus **full RTL/LTR parity** across all 130 screens — the ARB files (≈3,406 keys) already have EN/AR parity, so this is wiring, not translation.

---

## Part 4 — Per-role panel inventory (what exists, what's missing)

### ① Owner panel — Father (5 tabs, 86 FAT + 7 SHR)

| Tab | Root | Hub tiles | Panel job |
|---|---|---|---|
| اليوم (today) | `SCR-FAT-010` | 14 | Day board, approvals inbox, alerts, advisor suggestions |
| الأطفال (kids) | `SCR-FAT-012` | **22 → declutter** | Per-child control centre: location (`014`/`015`/`016`/`017`), screen time, apps, web filter, modes, devices, permission level |
| العائلة (family) | `SCR-FAT-021` | 11 | Chat, calls, calendar, tasks, members |
| الاستوديو (studio) | `SCR-FAT-040` | 13 | Learning content, lessons, materials, preview/approve |
| الإعدادات (settings) | `SCR-FAT-025` | 15 | Device, members, **brain control `029`**, **second-key parent mode `030`**, **mother level `031`**, **billing `056`/`057`**, notifications `058`, **privacy `059`**, **audit `060`**, language `061` |

*Missing / to design:* a real **approvals inbox** as a first-class panel; **permission matrix editor** (extend `031` beyond a single level picker); **audit trail** browsable and filterable; billing UI switched off the mock service.

### ② Co-parent panel — Mother × 3 levels (same 5 tabs, minus `029`/`031`/`056`/`057`)

The screens exist; **the three experiences do not.** Design each level explicitly, using the same components:

| Level | Can | Panel differs by |
|---|---|---|
| `observer` | See & be notified only | Control rows render as `SettingStatusRow` (read-only) + a "اطلب من الوالد" affordance; billing/brain/second-key tiles hidden with reason |
| `partner` | + approve child requests | **Approval inbox appears** (web unlock, time requests, app approvals); `WebUnlockActor` already encodes this |
| `full` | + edit rules | Rule editors enabled; same approve rights as partner |

*Missing / to design:* the **level-aware variants** of every gated screen; a **request-elevation flow** for observer; an **approval inbox filtered by actor** for partner/full; `SCR-FAT-027` (members) must display each adult's level.

### ③ Child panel — Child (4 tabs, 37 CHD)

| Tab | Root | Hub tiles | Panel job |
|---|---|---|---|
| يومي (myday) | `SCR-CHD-004` | 5 | Day board, schedule, tasks, rewards |
| تعلّم (learn) | `SCR-CHD-012` | 14 | Learning hub, lessons, Quran/education (`n17_child_learn`, 18 screens) |
| العائلة (cfam) | `SCR-CHD-007` | 8 | Family chat, calls, sharing |
| أنا (me) | `SCR-CHD-010` | 5 | Profile, settings, **my requests**, SOS |
| — | `SCR-CHD-005`/`006` | — | SOS fire + in-progress (FAB + child tabless) |

*Missing / to design:* the **"my requests & status" panel** — every request the child can make (more time, unlock a site, install an app) showing its live 5-phase delivery status. This is the child's entire control panel, and it is what makes the app feel fair rather than coercive. Also: **transparency surfaces** (what the parent can see), which `transparency_consent_screen.dart` begins.

### ④ Shared / system (7 SHR + onboarding)

`SHR-001/002/003` onboarding, `SHR-005/006/007` pairing/device setup, `SHR-008` **device-mode switch** — this must become a real profile switcher showing role + mother level + which panel you're entering, not a role toggle.

*To remove for "no simulation":* `lib/features/n13_coming_soon/` and `SCR-FAT-075` ("ميزات قادمة ✨") — coming-soon placeholders directly contradict the no-simulation goal. Either ship the feature or delete the tile.

---

## Part 5 — The Screen Completion Contract (definition of done)

Every one of the 130 screens passes all 12 checks before it is called done. This is what turns "improve the UI" into a finishable, auditable job.

| # | Check |
|---|---|
| 1 | Registered in `shell_config.dart` via `tool/gen_routes.dart` — never hand-edited |
| 2 | **Zero** inline `fontSize:` / color literals — theme tokens only |
| 3 | All 7 states authored: skeleton, empty, error (localized + retry), offline, stale/not-verified, denied/locked, populated |
| 4 | Responsive verified at 360 dp, 600 dp, 900 dp (no overflow, no below-the-fold nav) |
| 5 | Dynamic type safe at `textScaler: 1.5` |
| 6 | RTL Arabic **and** LTR English render correctly; zero hardcoded strings |
| 7 | A11y: semantics labels, ≥48 dp targets, sane focus order, AA contrast via tokens |
| 8 | Feedback: haptic on destructive/confirm; snackbar + undo where reversible |
| 9 | Role-aware via `PermissionMatrix` + `RoleGate`; the gated state is *designed*, not just router-blocked |
| 10 | Honesty: every capability it depends on shows its true status; no fake success while a row is `MOCK-REMOTE` |
| 11 | Data via `AppScope` only — zero imports from `lib/mock/`, zero `?? stage1*` fallbacks |
| 12 | Tested: a widget test plus a golden at phone/tablet × AR/EN × 1.0/1.5 scale (min. 4 goldens/screen) and a test per non-happy state |

### Tiering (so 130 screens is a schedule, not a wish)

| Tier | Count | Examples | Treatment |
|---|---|---|---|
| **A — Control centres** | ~26 | 9 tab roots, day board, children list, child profile, settings hub, mother level, brain control, plans, screen-time, web filter, pairing, smart modes, emergency, notifications, privacy/audit, gallery | Fully bespoke design + all goldens + manual review |
| **B — Working screens** | ~70 | Lists, editors, detail screens across `n02_day`, `n17_child_learn`, `n14_studio`, `n07_advisor` | Standard contract, composed from the control library |
| **C — Leaf / utility** | ~34 | Confirmations, single-purpose, auth/onboarding leaves | Contract minus bespoke layout |

Track this in a **screen ledger** (`SCREEN_LEDGER.md`, one row per screen: id · tier · batch · states · responsive · AR/EN · a11y · wired · goldens). Progress becomes visible and non-arguable.

---

## Part 6 — The waves

### Wave 0 — UX system foundation (≈2 weeks) · blocks everything
`FamilyTypography` (9–11 AR-tuned steps) · `FamilySpacing` + density · `FamilyBreakpoints` + `MaxWidthBox` · state components (skeleton/empty/error/offline/stale) · icon set (kills the 15 emoji) · motion + haptic tokens · contrast-fixed palette · dark-theme scaffolding · **`AppScope` + the 6 port interfaces (interfaces only, in-memory impls)** · lint rules banning inline `fontSize`, hardcoded strings, and `lib/mock/` imports.

> Do not skip or shorten this. Every screen is edited twice if the tokens do not exist first.

### Wave 1 — Shell + panel framework (≈2 weeks)
`PermissionMatrix` + `PanelProfile` + `RoleGate` · hub declutter (107 tiles → ≤8/tab + "More") · FAB/Scaffold normalisation (delete the magic `Positioned`s) · tab bar redesign with vector icons + live status · the ~20-component control library · panel templates · delete coming-soon screens and `placeholder_screen.dart` · refresh `device_mode_screen` into a profile switcher.

### Wave 2 — Complete every panel, feature-batch by feature-batch (≈10–14 weeks)
Six batches, each running the same loop — **Screen → Wire → Verify**:

| Batch | Scope | Screens |
|---|---|---|
| 2a | Parent **today** + approvals inbox + alerts | ~14 |
| 2b | Parent **kids** — per-child control centre (biggest, incl. location/web/screen-time/apps/modes/devices) | ~22 |
| 2c | Parent **family** — chat, calls, calendar, tasks, members | ~11 |
| 2d | Parent **settings** + father-only surfaces (brain, second-key, mother level, billing, notifications, privacy, audit, language) + Mother × 3 levels | ~15 + 3 variants |
| 2e | **Child** panel (4 tabs incl. learners, Quran, requests & status, transparency, SOS) | ~37 |
| 2f | **Shared** — onboarding, invites, pairing, device-mode switch | ~12 |

**"Wire" means:** that batch's real repository behind the frozen port (persistence tables for roster/chat/calls/calendar/tasks/notifications/settings/onboarding), its fixtures deleted, and its `CapabilityRegistry` rows left honestly labelled. So the app gets *more real with every batch* instead of waiting for a big-bang phase — and by the end of 2f, everything device-local is genuinely real. **Only Wave 4 needs a server.**

### Wave 3 — De-simulation sweep: make it a real app, backend-ready (≈5–8 weeks)
1. Extend `FamilyLocalSchema` to v11+ for the tables still in memory; replace `Memory*PrefsStore` with real KV prefs; drop `InMemory*` repos to `test/` only.
2. Real identity: `IdentitySource` replaces `createStage1IdentityRuntime()`; onboarding creates real `Account`/`Family`/`FamilyMembership`/`ChildIdentity`; `LoginScreen` authenticates locally instead of navigating.
3. `flutter_secure_storage` + SQLCipher (the DB currently holds children's location in plaintext).
4. Native bridge (`FamilyOsPlugin.kt` — there is **zero** `MethodChannel` today, `MainActivity.kt` is a stock 5-liner) and the capability flips: GPS → `fs001.native_gps`; AlarmManager/WorkManager → `fs005.os_wake` (**today a bedtime mode does nothing unless someone opens the app**); AccessibilityService + UsageStats + DeviceAdmin → `fs003.os_intercept`; `VpnService` DNS → `fs002.native_block`; MediaProjection/DeviceAdmin → `fs004.*`; `flutter_local_notifications`.
5. **No-simulation gates** (all must be zero / true):
   - `grep -rn "stage1" lib/` → 0 · `grep -rn "InMemory" lib/` → 0
   - `grep -rn "lib/mock" lib/` → only the capability registry
   - every displayed capability is `IMPLEMENTED` or badged as not-yet
   - `RegisterMockFamily` unreachable; `day_board_projection.dart:153` returns a true empty projection
   - no coming-soon screens; no debug writers (`main.dart:45`, `login_screen.dart:36`, `router.dart:323`, `tool/gen_routes.dart`)
6. P0 release blockers: Android manifest permissions (currently **zero**, not even INTERNET), iOS `*UsageDescription` keys (currently zero → release crash), delete `test/debug_sys3_route_probe_test.dart`, fix the two order-dependent test failures, add CI + crash reporting, replace the stock icon/splash.
7. Final UX pass across all waves: tablet/landscape, dynamic type at 1.5×, dark mode, real EN/AR switch, a11y audit.

**Gate:** kill and relaunch — every setting, child, task, mode and message survives; on a real Android device a bedtime actually locks the device with the app closed; a safe-zone exit fires a real ENTER/EXIT; every screen passes goldens at 1.5× on a 600 dp tablet in both languages with no overflow.

### Wave 4 — Backend (later, ≈8–12 weeks)
Implement the same six ports against a server; move `PolicyDeliveryPhase` advancement from local to server-driven; FCM; cross-device sync + conflict policy; `in_app_purchase`; email/SMS invites; SOS remote delivery. **If any UI change is required here, a port was leaked in Waves 0–3.**

---

## Part 7 — Sequencing picture

```
Wave 0  Systems foundation      ████░░░░░░░░░░░░░░░░░░  2 wks   tokens · states · AppScope + 6 ports
Wave 1  Shell + panel framework ░░░░████░░░░░░░░░░░░░░  2 wks   PermissionMatrix · control library · declutter
Wave 2  Complete every panel    ░░░░░░░░██████████████  10–14 wks  6 batches × (Screen → Wire → Verify)
Wave 3  De-simulation sweep     ░░░░░░░░░░░░░░░░██████  5–8 wks  native capabilities · identity · persistence · P0s
Wave 4  Backend                 ░░░░░░░░░░░░░░░░░░░░██  later    real sync · auth · FCM · purchases
                                                  ↑
                        Wave 2 done = every screen designed. Wave 3 done = no simulation, backend-ready.
```

Total to your two stated goals ("all screens complete" + "a real app, no simulation, backend-ready"): **≈19–26 weeks**, Android-first.

---

## Part 8 — Decisions needed before Wave 0 starts

1. **Vertical-slice batches (recommended) or all-screens-then-wire?** The batches above deliver a polished, partially-real app continuously and remove the risk of designing 130 screens against data that then changes. The alternative is faster to *look* uniform but defers all reality to the end.
2. **State management:** keep `AppScope` (`InheritedWidget`, zero new deps) or adopt Riverpod for `AsyncNotifier`-driven loading/error? Decide once — 130 screens migrate once.
3. **Single app or child flavor?** One codebase with a **child `applicationId` flavor** keeps the parent app permission-light and eases Play Store review, since the child agent needs aggressive background privileges.
4. **Android-first or both platforms?** iOS cannot enforce web filtering or app interception the way Android can; shipping Android first with iOS as a degraded observer is honest and roughly halves Wave 3.
5. **Confirm the Mother levels.** Are `observer` / `partner` / `full` the final semantics, and is there ever a fourth adult (grandparent, guardian) or a second father?
6. **Son vs daughter:** confirm keeping one `child` role with profile-level personalisation (recommended), rather than more roles.
7. **Dark mode now or later?** Cheap in Wave 0 (tokens are already `ThemeExtension`s), expensive after 130 screens assume light.

---

## Appendix — Verified inventory (baseline for the ledger)

- **130 registered screens** (131 screen classes): **86 FAT** (parent) · **37 CHD** (child) · **7 SHR** (shared).
- **Tabs:** parent 5 (`today`/`kids`/`family`/`studio`/`settings`, roots `FAT-010`/`012`/`021`/`040`/`025`) · child 4 (`myday`/`learn`/`cfam`/`me`, roots `CHD-004`/`012`/`007`/`010`).
- **Tabless:** parent 17 · child 5.
- **Hub tiles: 107 total** — today 14 · **kids 22** · family 11 · studio 13 · settings 15 · myday 5 · learn 14 · cfam 8 · me 5.
- **Feature areas:** `n02_day` 26 · `n17_child_learn` 18 · `n14_studio` 14 · `n07_advisor` 13 · `n01_linking` 12 · `n03_screen_time` 7 · `n12_devices` 6 · `shared_onboarding` 5 · `n16_tasks` 4 · `n10_emergency` 4 · `n08_platform` 4 · `n05_lock` 4 · `n07_privacy` 3 · `n15_calendar` 2 · `n11_billing` 2 · `n04_web_filter` 2 · remainder 1 each.
- **Design system present:** `lib/core/design/tokens.dart` (token-only colors, 4 `ThemeExtension`s), `lib/core/design/components/*`, `/gallery` reference screen.
- **Fixtures in production path:** 33 `stage1*` singletons · 104 `InMemory*` repos · `lib/mock/register_mock_family.dart` · `day_board_projection.dart:153`.
- **Honesty system:** `capability_registry.dart` / `capability_status.dart` (12 `MOCK-REMOTE`/`NOT_IMPLEMENTED` rows) · `policy_delivery.dart` (`Configured → Published → Delivered → Applied → Verified`).
