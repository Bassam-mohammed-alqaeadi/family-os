# LOOP_STATE

```
status: RUNNING
current_card: DEV-7 shipped (subscription screens on the v6 rows) — the wave-2 domains (tasks · calendar · learning · studio · subscription) are now all on real rows; NEXT = DEV-6b (the rest of the studio: preview/approve · materials/lessons · generation outputs · staged project · add from source) then DEV-6c (community library · focus report · learning path · results followup)
blocked_by: (none)
last_tick: 2026-09-24 (DEV-7 · subscription wired · pushed)
resume_hint: DEV-7 — `app/lib/features/n11_billing/billing_ux_bridge.dart` holds `Stage1BillingRuntime` (one shared `DriftEntitlementService` for both billing screens, with the first-use read notifying the listening screens) and the service itself over `subscription_state` + `billing_event`. The row IS the plan: status maps to the entitlement lifecycle, the trial's remaining days are read from the stored period end against the clock, and auto-renew is implied by a plan that has not ended (the contract has no column for it). Every change updates the one family row and appends a `billing_event` (SUBSCRIBE / CHANGE_PLAN / STATUS_CHANGE / CANCEL_RENEWAL) carrying the plan+status digest; `cancelRenewal()` ends the paid state without touching safety (Rule 9 · P-4). Fail-closed: no family scope claims nothing and writes nothing; another family's row is never read. `setEntitlement` is synchronous by contract, so the write rides `lastWrite` for callers that must await durability. MEASURED: analyze --fatal-infos clean · strings gate OK (331 files) · new tests 7 · FULL suite 1611/1611 (was 1604) · 32 of 131 screen files bind a Stage-1 runtime (was 30). NEXT: the studio remains the only domain with screens still on fixtures — DEV-6b (preview/approve over `content_pack.status` + `content_item`; materials/lessons · generation outputs · staged project · add from source) then DEV-6c (community library `community_cache` · focus report aggregating learn_session kind = FOCUS · learning path + stops · results followup). NOTE `*.g.dart` stays gitignored — CI must run `dart run build_runner build` before `flutter test`.
```

## Field meanings

| Field | Values |
|---|---|
| `status` | `RUNNING` — keep working · `BLOCKED` — unanswered QUESTIONS · `STOPPED` — human stopped the loop |
| `current_card` | Backlog id being worked or next to work |
| `blocked_by` | Question id(s), e.g. `Q-PREFLIGHT-001`, or `(none)` |
| `last_tick` | Date of Orchestrator tick |
| `resume_hint` | One line for the next wake |

## Rules

- Unanswered QUESTIONS → must set `status: BLOCKED` and stop `/loop`.
- After Bassam answers → resume protocol sets `RUNNING` and clears `blocked_by`.
- Never leave `RUNNING` while an unanswered QUESTION exists.
