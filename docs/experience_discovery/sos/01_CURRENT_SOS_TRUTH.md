# 01 — Current SOS Truth

**Labels:** `CURRENT FACT` · `PROPOSED DESIGN` · `OWNER DECISION REQUIRED` · `UNKNOWN`  
**Source of truth:** repository as of 2026-09-23 discovery.  
**Entry:** [13_SOS_MASTER_TRUTH_SHEET.md](13_SOS_MASTER_TRUTH_SHEET.md)

---

## 1. What exists

### 1.1 Screens (`app/lib/features/n10_emergency/`)

| Screen ID | Widget | Route | Lean behavior |
|---|---|---|---|
| SCR-FAT-018 | `SosAlertScreen` | `/scr-fat-018?alertId&childId` | Child → empty lean |
| SCR-FAT-028 | `EmergencySetupScreen` | `/scr-fat-028` | No role lean; any navigator can edit UI |
| SCR-CHD-005 | `ChildSosButtonScreen` | `/scr-chd-005` | Parent → lean |
| SCR-CHD-006 | `ChildSosInProgressScreen` | `/scr-chd-006?alertId&childId` | Parent → lean |

Registry notes (`screens.csv`): emergency priority; FAT-018 “pierces mute”; CHD-005 “works without internet/subscription”; CHD-006 “location broadcast + auto-call”.

### 1.2 Policy / domain

| Artifact | Path | Nature |
|---|---|---|
| `SosFireService` / `MockSosFireService` | `core/policy/sos_fire.dart` | Always `fired: true`; simulates recipient deliveries |
| `SosLadder` + repos | `sos_ladder.dart`, `sos_ladder_repository.dart` | Rung-1 father+mother immovable; backups editable |
| `SosAlert` + `InMemorySosAlertRepository` | `sos_alert.dart`, `sos_alert_repository.dart` | Status: `active` \| `resolved` only |
| `NotificationDelivery.simulateSosAlert` | `notification_delivery.dart` | Critical always delivers |
| `NotificationPrefs` | forbids SOS-mute JSON keys | `sosReceiptAlwaysOn = true` |
| Lock / expiry exempt | `device_lock_service.dart`, `time_expiry_surface.dart` | `sos` in exempt lists |
| RoleGuard | `app/role_guard.dart` | `canShowSosMuteControl` always false; SOS screens not father/owner-only |

### 1.3 Shell / navigation

- Child FAB → CHD-005 (hidden on CHD-005/006) — `family_shell.dart`
- Parent settings shortcut → FAT-018
- FAT-018 empty → CTA FAT-028; live map CTA → FAT-014
- Setup wizard / FAT-025 copy references emergency setup

### 1.4 Schema / API (contracts only — not wired)

```sql
-- family-os/_CONTRACTS/schema.sql
CREATE TYPE sos_status AS ENUM ('ACTIVE','ACKNOWLEDGED','RESOLVED');
CREATE TABLE sos_alert ( ... status sos_status ... request_id uuid UNIQUE ...);
```

API intent: `POST /sos`, `POST /sos/{id}/ack`, `PATCH /sos/{id}/resolve` — **no Flutter client**.

### 1.5 Absent as product features

- Typed `FamilyEvent` for SOS (`CURRENT FACT`: grep found none)
- Live GPS bound to SOS session
- SMS / dialer / FCM critical channel
- App enum value for `ACKNOWLEDGED`
- Automatic timer-based ladder escalation
- Product “Evidence Pack”, “Panic Quiet Mode”, or “Break-glass” SOS modes

---

## 2. What is actually connected

| Step | Connected? | Reality |
|---|---|---|
| CHD-005 3s hold → fire | Yes (in-process) | `fireAndSeedSosAlert` → mock fire + seed |
| Delivery sim to father/mother | Simulated | `delivered == true` for critical |
| Quiet hours pierce | Policy + tests | No OS notification |
| CHD-006 “father/mother saw” | UI-only | Static ARB strings |
| FAT-018 map/battery/movement | Fixture | Demo `SosAlert` + pin fractions |
| Auto-call 5s | Timer → snackbar/callback | No `tel:` / VoIP |
| Escalate | Counter++ | No SMS/call to backups/national |
| Resolve (parent or child) | In-memory clear | No proven audit append from SOS path |
| Ladder config | MemorySosLadderStore | Process-lifetime; not DB |
| Offline / airplane | Claimed by P-4 / UF-08 | **Not proven** on device (`UNKNOWN`) |

---

## 3. Mock / stub / UI-only map

| Layer | Classification |
|---|---|
| CHD-005 hold UX | Real UI + timer logic |
| `MockSosFireService` | Mock service (always succeeds) |
| `InMemorySosAlertRepository` | In-memory Stage-1 store |
| FAT-018 coral board | Real UI over mock data |
| Auto-call / Call now | Stub (snackbar Stage-1) |
| Escalate | Stub (counter) |
| Live map on FAT-018 | Decorative / stylized |
| FAT-014 navigation | Real route; separate location seam |
| Piercing siren | Copy honesty only — no OS critical alert |
| Audio broadcast (P-4) | **Not implemented** (see GAP-A-SEC-008 in project-plan) |

---

## 4. Parent (Father / Primary) journey today

```
START → open FAT-018 (shell shortcut) or seeded active alert
INTENT → see / act on child SOS
SCREEN → SosAlertScreen (coral when active)
ACTION → Call now | Live map | Resolve | Escalate
LOGIC → SosAlertRepository.resolve / escalateEmergencyContacts; auto-call Timer
DATA → InMemorySosAlertRepository
NOTIFICATION → none real (sim only at fire time)
CHILD EFFECT → none across devices (same-process seed only)
RESULT → snackbar + pop / go day board
RECOVERY → empty state → open FAT-028
```

Configure path: FAT-028 — parents locked ON; add/toggle/remove backups.

---

## 5. Mother journeys today

Policy: all `MotherLevel` values receive SOS (`NotificationDelivery.guardianReceivesSos`; SET-021).

| | Observer | Partner | Full |
|---|---|---|---|
| Receive (sim) | Yes | Yes | Yes |
| Mute SOS UI | Never | Never | Never |
| FAT-018 CTAs | Same — `motherLevel` does **not** gate actions | Same | Same |
| FAT-028 edit | No MotherLevel gate on screen | Same | Same |

Widget proof: mother Observer can resolve FAT-018 (`sos_alert_screen_test.dart`).

**OWNER DECISION REQUIRED:** whether Observer should remain action-capable or receive-only.

---

## 6. Child journey today

```
START → shell FAB or CHD-005
ACTIVATION → hold 3s (early release = accidental protection)
ACTIVE STATE → CHD-006 coral board
COMMUNICATION → “Call father” → navigates CHD-007 (chat), not dialer
LOCATION → broadcast copy only; no GPS
RESTRICTIONS BYPASS → lock/expiry exempt `sos`; fire entitlement-free
RESOLUTION → confirm-safe sheet → resolve() → CHD-004
```

Default `childId` on CHD-005: `'child_local'` (parametric seam exists).

---

## 7. Intended real-world requirement (authority — not app)

From Policy Register P-4/P-5 + UF-08 + S-SEC-026…030:

- Works with no internet, time expired, subscription expired
- 3s press → location (+ intended audio) → siren piercing silent on father & mother + live map
- Escalation ladder: parents → backups (father-set delays) → national emergency
- Guardians cannot mute SOS receipt
- Schema lifecycle: ACTIVE → ACKNOWLEDGED → RESOLVED

---

## 8–9. Screens that can support vs need change

| Screen | Can support target? | Engineering stance |
|---|---|---|
| CHD-005 | Yes — keep hold activation | Modify (wire real fire pipeline) |
| CHD-006 | Yes — keep in-progress board | Extend (honest delivery/location; cancel semantics) |
| FAT-018 | Yes — keep coral alert board | Extend (live location, call, ACK, receipts) |
| FAT-028 | Yes — keep ladder UX | Extend (phones, delays scheduler, national #, role gates) |
| FAT-014 | Supporting live map | Reuse / deep-link from SOS |
| FAT-058 | Quiet hours honesty | Keep; never add mute SOS |
| CHD-021 | SOS reachable at expiry | Keep CTA |
| New | Delivery failure / evidence / history | Possibly new — OWNER |

---

## 10. Capability domains required

Policy, domain models, backend `sos_alert`, push critical channel, location stream, telecom (SMS/call), offline outbox, device permissions, audit immutability, entitlement exclusion — detail in docs 03, 08, 09.
