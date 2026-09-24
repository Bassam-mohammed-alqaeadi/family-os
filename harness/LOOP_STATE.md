# LOOP_STATE

```
status: RUNNING
current_card: NEXT = the child dashboard placeholders, then the geofence editor SCR-FAT-017
blocked_by: (none)
last_tick: 2026-09-24 (DEV-1)
resume_hint: CHAT-053-UX shipped — the four chat screens (SCR-FAT-021 ConversationsList · SCR-FAT-022 Conversation · SCR-CHD-007 ChildChats · SCR-CHD-008 ChildConversation) are now on the ADR-053 «خطّ واتساب المعتدل» line. Feature seams extended (ConversationThread + mute/archived/look/previewKind/locked, ConversationMessage with MessageTick/pinned/deleted/edited/sentAt/replyTo/media kind, ConversationDeliveryStatus dropped — no "delivered"); per-chat settings methods on both list seams and the thread seam; new `chat_ux_bridge.dart` mirrors `location_ux_bridge.dart` (Stage1ChatRuntime.ensureOpen over FsSessionKernel + DriftCommunicationRepository + DriftChatPreferencesRepository, with DriftConversationsListRepository / DriftConversationRepository adapters deriving ticks/pins/mute/look through the pure rules); pure rules gained chatStaysPinned / parentSeesThread / receiptsToggleOffered. UI: pinned bar, RTL bubbles with my-message-on-the-left and time inside, ✓/✓✓ from read rows, reply quote inside the bubble, 15-min author-only edit, tombstone «حُدفت هذه الرسالة» in place, per-chat settings sheet (mute 8h/week/forever · archive · pin · wallpaper · bubble theme), media kinds, voice preview «🎤 رسالة صوتية»; family pinned دائمًا; receipts mandatory with a parent; locks never hide a child thread; presence/typing and the false 🔒 e2e badge are gone (banner copy de-claimed too). MEASURED: `flutter analyze --fatal-infos` clean · `dart run tool/check_hardcoded_strings.dart` OK (324 files) · `flutter test` 1563/1563 (was 1529, +34; new bridge file 16 tests) · registry 243 services, 100% wave coverage, no blocking errors · PlaceholderScreen count still 0. NOTE: the Drift adapters default to an in-process `FamilyDatabase` (stage-1; no sync backend) and contract v5/migration v4→v5 were NOT touched; S-COM-009 lock has no column so `setLocked` throws UnsupportedError while the guarantee lives in `parentSeesThread`. CI: run `dart run build_runner build` before `flutter test` (*.g.dart is gitignored). NOT pushed. Prior push state unchanged: origin/feat/real-flutter-build at a01674b (7 commits) with draft PR #6; the 3-day write token expired around 2026-09-27 — a later session needs a fresh one before pushing. Do NOT auto-start P15-QUR or Stage 3 — Owner must explicitly re-arm.
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
