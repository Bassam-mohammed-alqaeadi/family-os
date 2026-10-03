# 13 — Cross-System Dependencies

**Date:** 2026-09-23  
**Screen Time is System #2** — map edges only; do not start other systems.

---

## Dependency table

| System | Input to Screen Time | Output from Screen Time | Precedence | Event | UI effect | Future backend | Future device |
|---|---|---|---|---|---|---|---|
| **Web Filter** | Block/allow URL | None (orthogonal) | Separate gate | filter.blocked | Polite block page | filter rules sync | VPN/DNS/agent |
| **Instant Lock** | Lock flag | Entertainment deny | Lock > all time rules | lock.engaged | FAT-037 / child banner | lock command | OS lock |
| **Smart Modes** | modeActive + allow list | Access deny/allow under mode | After lock/block | mode.activated | CHD-004 tint / FAT-085 | mode schedule | OS Focus optional |
| **Notifications** | Quiet hours prefs | Warning/request pushes | SOS never muted | time.warning / request.created | Toasts Stage-1 | FCM | OS notify |
| **SOS** | Exempt surface | Must remain reachable | P0 exempt | sos.fire | CHD-005/006 | sos_alert | telecom/GPS |
| **Education** | Attribution rewards | `WalletLedger.earn` | Economy credit | reward.approved | FAT-045 → wallets | ledger API | n/a |
| **Device Management** | Permissions honesty | Enforcement state | Platform constraint | perm.granted | FAT-067/068 | device registry | Usage Access / Screen Time |
| **Policy Engine** | Assignee/reward rules | Deposit amounts | E-1…E-5 | earn.credited | Economy UI | — | — |
| **Sync** | Policy/request queues | Mirror remaining | G-1 | policy.synced | Sync badges | realtime | multi-device |
| **Audit** | Actor decisions | Append-only trail | No delete | * | History | audit store | — |
| **Family Roles** | Role + MotherLevel | Mutation rights | R-2 / ADR-039 | — | Role-specific UX | — | — |

---

## Critical edges (do not break)

1. **SOS × expiry/lock** — exemptions stay.
2. **Education × Minutes** — earn only via ledger; no points.
3. **Web filter unlock ≠ time grant**.
4. **Smart mode allowed app still needs remaining time** (Register).
5. **AI suggests only** — no auto grant without father/mother approve.

---

## Gap-driven dependencies

| Gap | Blocks |
|---|---|
| No consume API | Education earn visible but spend meaningless |
| CHD-020 disconnected | Notifications of requests never fire for real |
| No OS agent | Instant lock / modes are UI theater |

See: [14_PLATFORM_ENFORCEMENT_REQUIREMENTS.md](14_PLATFORM_ENFORCEMENT_REQUIREMENTS.md).
