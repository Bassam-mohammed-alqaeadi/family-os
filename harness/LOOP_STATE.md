# LOOP_STATE

```
status: RUNNING
current_card: PHASE-3 screens — chat to the ADR-053 line (SCR-FAT-021/022 · SCR-CHD-007/008), then child dashboard
blocked_by: (none)
last_tick: 2026-09-24
resume_hint: PERS-1 + PERS-2a..2e shipped — the whole 20-table contract has real local rows, and the two gaps ADR-052 deferred are now closed. PERS-2e = ADR-053 «خطّ واتساب المعتدل»: schemaVersion 5 adds message.pinned_at/pinned_by_* (with a coherence CHECK), message_read (PK (message_id, reader_key)) and chat_preference (PK (conversation_id, owner_key)); repos gain pinMessage/unpinMessage/pinnedMessageIn/markRead/readersOf/readCount/tickOf/markThreadRead plus a new DriftChatPreferencesRepository; communication_rules.dart gains MessageTick (only ✓ and ✓✓ — no "delivered" tick we cannot observe), chatIsMuted/muteUntilFor/kMuteForeverUntil, receiptsMayBeDisabled (mandatory in any thread containing a parent), mayPin/requirePinState, and the theme/wallpaper sets. Registry: S-COM-040/041/042 wired to SCR-FAT-021/022. Suite 1057/1057 (was 1033); analyze clean; registry validate 243 services with 100% coverage. DELIBERATELY LEFT OUT, recorded in ADR-053: status/channels/communities/broadcast, web-style device linking, call links, disappearing messages (they erase a parent's evidence), call recording, the grey delivered tick, and the "🔒 e2e" badge until a backend with real key management exists. NEXT=the four chat screens rebuilt and verified to that line (transfer from the visual reference, measure with ADR-042), then the child dashboard (25 placeholders), then the geofence editor SCR-FAT-017. CI note: run `dart run build_runner build` before `flutter test` — *.g.dart is gitignored. Push needs the GitHub token.
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
