# 02 — FS-006 Current Repo Evidence

**Mode:** Evidence map. Frozen law lives in `sos_final/`.  
**Master:** [12_FS006_DISCOVERY_CLOSURE_REPORT.md](12_FS006_DISCOVERY_CLOSURE_REPORT.md)

---

## 1. Frozen product pack (authority — not evidence)

| Path | Role |
|---|---|
| `docs/experience_discovery/sos_final/` | **FROZEN** OD/RD/Master |
| Historical `sos/` · `sos_screen_engineering/` | Prior discovery / UX engineering — non-authority where superseded |

---

## 2. Flutter screens / routes

| Screen | Widget | Route | Notes |
|---|---|---|---|
| SCR-CHD-005 | `ChildSosButtonScreen` | `/scr-chd-005` | 3s hold trigger |
| SCR-CHD-006 | `ChildSosInProgressScreen` | `/scr-chd-006` | In-progress / cancel |
| SCR-FAT-018 | `SosAlertScreen` | `/scr-fat-018` | Parent incident board + break-glass CTA |
| SCR-FAT-028 | `EmergencySetupScreen` | `/scr-fat-028` | Ladder / Panic Quiet setup UI |

Shell: child FAB → CHD-005; parent shortcuts → FAT-018 (evidence from prior truth packs + router).

---

## 3. Domain / policy spine

| Artifact | Path | Class |
|---|---|---|
| `SosAlert` + statuses | `sos_alert.dart` | **PARTIAL** — active/acknowledged/escalating/resolved; location/delivery/connection enums |
| `SosAlertRepository` | `sos_alert_repository.dart` | **MOCK/SIMULATION** — in-memory; ack/resolve/escalate methods |
| `SosFireService` / `MockSosFireService` | `sos_fire.dart` | **MOCK** — always `fired: true` |
| `SosLadder` + repos | `sos_ladder*.dart` | **PARTIAL** — rung-1 immutable; backups + verification states in domain |
| `SosRoleActions` | `sos_role_actions.dart` | **IMPLEMENTED** (pure RBAC checks) |
| `SosBreakGlass*` | `sos_break_glass.dart` + sheet | **PARTIAL** / **MOCK** — in-memory lifecycle; UI sheet |
| `SosSettings` | `sos_settings.dart` | **PARTIAL** — prefs-shaped settings incl. Panic Quiet flags |
| Notification SOS path | `notification_delivery.dart` | **MOCK** — `simulateSosAlert`; mute forbidden |
| Exempt surfaces | `time_expiry_surface` / lock lists | **PARTIAL** — SOS exempt from time lock |

---

## 4. Design components

`sos_status_banner` · `sos_delivery_status` · `sos_location_status` · `sos_action_bar` · `sos_readiness_card` · `sos_cancel_confirmation` · `sos_break_glass_sheet` · `trusted_contact_card`

Class: **IMPLEMENTED** as UI components over mock domain.

---

## 5. Tests (evidence of Stage-1 intent)

| Test | Covers |
|---|---|
| `child_sos_button_screen_test` | Hold fire |
| `child_sos_in_progress_screen_test` | In-progress UI |
| `sos_alert_screen_test` | Parent board |
| `emergency_setup_screen_test` | Setup |
| `sos_break_glass_test` | RBAC + no national numbers |
| `sos_role_actions_test` | Role matrix |
| `sos_ladder*_test` | Ladder / verification |
| Paywall boundary | SOS libraries not import billing |

---

## 6. Schema / API contracts

| Asset | Finding |
|---|---|
| `schema.sql` `sos_alert` | ACTIVE/ACKNOWLEDGED/RESOLVED enum; table present |
| Flutter Drift wiring | **MISSING** |
| HTTP `POST /sos` etc. | Documented in contracts — **no Flutter client** |

---

## 7. Native Android / iOS

| Capability | Finding |
|---|---|
| Kotlin/Java SOS agent | **MISSING** (no matches under `app` native for SOS/SMS) |
| Critical alert channel | **DOCUMENTED ONLY** / honesty copy |
| `tel:` / SMS intents | **MISSING** as proven path |
| Background SOS worker | **MISSING** |

---

## 8. What is simulated vs real

| Claim | Reality |
|---|---|
| Child 3s hold fires SOS | Real UI → mock fire + in-memory seed |
| Parents receive critical push | Simulated delivery rows |
| Piercing siren | Copy / banner honesty — no OS critical alert proven |
| Auto-call | Timer / snackbar Stage-1 — no dialer |
| Escalate backups | Status → escalating; no SMS/call |
| Live map | Fixture pin fractions; FAT-014 separate |
| Break-glass override | Session in memory; does not mutate permanent policy (good) — does not drive real unlock plane |
| Offline airplane SOS | Claimed by P-4 / OD-17 — **not proven on device** |
| Evidence pack export | **MISSING** |
| Audio broadcast | **Forbidden** by SOS Final; not implemented (correct absence) |
