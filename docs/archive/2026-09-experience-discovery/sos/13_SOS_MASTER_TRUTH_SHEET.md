# 13 — SOS Master Truth Sheet

**Single entry point for the Family OS SOS / Emergency system.**  
**Discovery date:** 2026-09-23  
**Mode:** Experience Engineering — discovery only (no app code changed).

**Label legend:** `CURRENT FACT` · `PROPOSED DESIGN` · `OWNER DECISION REQUIRED` · `PLATFORM CONSTRAINT` · `UNKNOWN`

---

## Verdict

| Dimension | Verdict |
|---|---|
| **Maturity** | **B/F** — strong policy UI + mock ladder/fire; **not** a real emergency channel |
| **Screens (4)** | FAT-018, FAT-028, CHD-005, CHD-006 — all wired in `router.dart` |
| **Policy spine** | P-4, P-5, SET-010/011/020/021, UI-007/010/011 — largely **implemented in mocks/tests** |
| **Real telecom / GPS / push / SMS** | **Absent** |
| **Schema** | `sos_alert` exists (`ACTIVE`/`ACKNOWLEDGED`/`RESOLVED`) — **unused by app runtime** |
| **Evidence Pack / Panic Quiet Mode / Break-glass** | **Not present** as SOS product features |
| **Biggest honesty gap** | UI promises live location, piercing siren, auto-call, escalate — stage-1 mocks only |
| **Non-negotiable law (Register)** | SOS never gated by subscription, quiet hours, time expiry, or device lock |

---

## Doc index

| # | File | Purpose |
|---|---|---|
| 01 | [01_CURRENT_SOS_TRUTH.md](01_CURRENT_SOS_TRUTH.md) | What exists, connected vs mock, role journeys today |
| 02 | [02_COMPETITIVE_SOS_ANALYSIS.md](02_COMPETITIVE_SOS_ANALYSIS.md) | Qustodio / FamiSafe / Bark / Android — facts vs ours |
| 03 | [03_SOS_POLICY_MODEL.md](03_SOS_POLICY_MODEL.md) | Policy semantics current vs required |
| 04 | [04_SOS_STATE_MACHINE.md](04_SOS_STATE_MACHINE.md) | Formal SOS states |
| 05 | [05_SOS_ROLE_MATRIX.md](05_SOS_ROLE_MATRIX.md) | Primary / Mother levels / Child capabilities |
| 06 | [06_SOS_SCREEN_ENGINEERING.md](06_SOS_SCREEN_ENGINEERING.md) | Per-screen engineering contract |
| 07 | [07_SOS_FAILURE_RECOVERY.md](07_SOS_FAILURE_RECOVERY.md) | Degraded paths |
| 08 | [08_SOS_DATA_EVENT_MODEL.md](08_SOS_DATA_EVENT_MODEL.md) | Data + events |
| 09 | [09_SOS_BACKEND_DEVICE_REQUIREMENTS.md](09_SOS_BACKEND_DEVICE_REQUIREMENTS.md) | Backend + device |
| 10 | [10_SOS_EXPERIENCE_GAPS.md](10_SOS_EXPERIENCE_GAPS.md) | Gap register |
| 11 | [11_SOS_TARGET_EXPERIENCE.md](11_SOS_TARGET_EXPERIENCE.md) | Target journey |
| 12 | [12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md](12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md) | Owner decisions |

---

## Inventory snapshot

### Screens found
- `SCR-FAT-018` — `SosAlertScreen` — `/scr-fat-018`
- `SCR-FAT-028` — `EmergencySetupScreen` — `/scr-fat-028`
- `SCR-CHD-005` — `ChildSosButtonScreen` — `/scr-chd-005`
- `SCR-CHD-006` — `ChildSosInProgressScreen` — `/scr-chd-006`
- Supporting: shell SOS FAB, FAT-058 quiet-hours honesty, CHD-021 SOS CTA, FAT-014 live-map link

### Services / repositories found
- `SosFireService` / `MockSosFireService` / `stage1SosFireService`
- `SosLadder` + `SosLadderRepository` (`Prefs` / `InMemory`)
- `SosAlert` + `InMemorySosAlertRepository` / `stage1SosAlertRepository`
- `NotificationDelivery.simulateSosAlert`
- Exemptions: `kDeviceLockExemptSurfaces`, `kTimeExpiryExemptSurfaces` include `sos`
- `RoleGuard.canShowSosMuteControl` always `false`

### Tests found
- `app/test/features/n10_emergency/*` (4 screen suites)
- `app/test/core/policy/sos_ladder_test.dart`
- `app/test/features/n06_notifications/ui_010_quiet_hours_sos_test.dart`
- `app/test/core/policy/notification_delivery_test.dart`
- `app/test/core/policy/ui_007_paywall_boundary_test.dart`
- `app/test/features/n03_screen_time/ui_011_time_expiry_test.dart`
- Related RoleGuard / spine CTA / touch-target SOS proofs

### Confirmed capabilities (`CURRENT FACT`)
- 3-second hold activation (CHD-005)
- In-process fire → seed alert → CHD-006
- Parent/mother coral alert board with resolve/escalate CTAs
- Rung-1 parents immovable on ladder
- SOS receipt never muteable; quiet hours cannot silence critical
- Entitlement-free fire path (structural)
- Lock / time-expiry treat SOS as exempt surface
- Mother Observer can resolve in widget tests (P-4 / SET-021)

### Confirmed gaps
- No real push / SMS / call / GPS / audio
- Schema `ACKNOWLEDGED` unused; app only `active` \| `resolved`
- Ladder delay fields not scheduled
- No phone numbers on backup contacts
- Child “father/mother saw” is static ARB copy
- No FamilyEvent SOS types; no runtime `sos_alert` DB client
- Evidence Pack / Panic Quiet Mode / Break-glass absent as product features

### Major platform dependencies
- iOS Critical Alerts entitlement; Android high-priority / full-screen intent
- Background location + last-known cache
- Telephony / SMS gateway or device intents
- Battery unrestricted / Doze honesty
- Offline outbox + airplane-mode acceptance

### Proposed target (one line)
Always-on child 3s trigger → canonical SOS session → piercing guardian notifications → live location → parent action / ladder escalate → resolve → immutable audit — with honest degraded modes (no inventing “live” when offline).

### Owner decisions still required
See [12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md](12_SOS_DECISIONS_REQUIRING_OWNER_APPROVAL.md) — Observer powers, ACK vs RESOLVE, child cancel after ACTIVE, auto-call medium, national emergency auto-dial, audio v1, contact channels, evidence retention, Mother edit rights on FAT-028.

---

## Authority references

- `handoff/04_POLICY_REGISTER_EN.md` — P-4, P-5
- `family-os/_REGISTRY/screens.csv` — FAT-018/028, CHD-005/006
- `family-os/_CONTRACTS/schema.sql` — `sos_alert`
- `docs/project-plan/07-user-flows.md` — UF-08
- `docs/project-plan/04-service-catalog.md` — S-SEC-026…030
- App: `app/lib/features/n10_emergency/**`, `app/lib/core/policy/sos_*`
