# LOOP_STATE

```
status: RUNNING
current_card: PHASE-3 screens (child dashboard first)
blocked_by: (none)
last_tick: 2026-09-24
resume_hint: PERS-1 + PERS-2a..2d shipped — the whole 20-table contract now has real local rows. PERS-2d = communication/AI/audit per ADR-052: conversation, message (ciphertext bytes only; one_sender; request_id dedup; 15-min edit by the author; "delete for everyone" blanks the body and keeps the row), call_log (no recording column by design), ai_event (alias only, domain/severity sets, excerpt-not-archive limit, must be JSON), ai_suggestion (one action, confidence, real 10-min undo window), audit_log (append-only, update/delete refuse). communication_rules.dart is pure Dart and tested. Suite 1033/1033 (was 984); analyze clean. OPEN: S-COM-005 read receipt + S-COM-008 pin are deferred to the messaging screen card (need message_read + a pin column) — recorded in ADR-052, not silently dropped. NEXT=Phase 3 screens: child dashboard first (25 placeholders), then geofence editor SCR-FAT-017 (Wave 3, transfer from the visual reference). CI note: run `dart run build_runner build` before `flutter test` — *.g.dart is gitignored. Push needs the GitHub token.
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
