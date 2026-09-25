# Screen wiring queue — Zero Mocks (Orchestrator-managed loop)

**Owner directive 2026-09-25:** wire every remaining screen to real ADR-054 v6 rows — no mocks,
no errors, no owner intervention — in one continuous loop, with the **Orchestrator (Second Brain)
as manager**: it briefs the worker agent, verifies every gate itself, fixes or re-dispatches on any
failure, and ships (commit + push + mirror + logs) only green.

Measured 2026-09-25 (`rg -l 'Stage1[A-Za-z]*Runtime' -g '*_screen.dart' lib/features | wc -l`):
**70 bound of 131 → 61 unbound.**

Card status — done: WIR-01 (n07_advisor A, `d3257cb`) · WIR-02 (n07_advisor B, `3063773`) ·
WIR-03a (SCR-FAT-012 only, `f9ecd94`). Next: the rest of WIR-03 (day_board · alerts_hub ·
alert_detail · request_inbox · friend_approval · outer_circle), then WIR-04 → WIR-13 in order.

## Cards — one card = one worker run, verified by the Orchestrator

| id | domain | screens (count) | notes |
|---|---|---|---|
| WIR-01 | n07_advisor A | my_advisor · advisor_suggestions · advisor_voice · family_advisor_hub · mother_ai_feed · brain_control (6) | extend `Stage1ReportsRuntime` (DEV-8) via a new `advisor_followup_bridge.dart` |
| WIR-02 | n07_advisor B | family_moments · family_patterns · individual_timeline · knowledge_maps · peer_compare · agent_action_log (6) | same bridge; declare gaps where no column exists |
| WIR-03 | n02_day A | day_board · children_list · alerts_hub · alert_detail · request_inbox · friend_approval · outer_circle (7) | `conversation`/`message`/`message_read` · `sos_alert` · `child` |
| WIR-04 | n02_day B | conversations_list · conversation · child_conversation · child_chats · child_friends · child_media_share · child_stickers_backgrounds (7) | chat prefs + reads + pins |
| WIR-05 | n02_day C | active_call · child_active_call · child_call_play · call_history · child_arrival · road_safety · child_profile (7) | `call_log` · `location_ping` · `geofence_event` |
| WIR-06 | n01_linking A | setup_wizard · add_child · invite_mother · accept_mother_invite · link_qr · child_qr_scan (6) | `invite` · `pairing_token` · `member`/`account` |
| WIR-07 | n01_linking B | link_success · child_welcome · create_family · permissions_explainer · transparency_consent · trial_mode (6) | consent + trial rows |
| WIR-08 | shared_onboarding | welcome · login · create_account · device_mode · device_user_switch (5) | `account` · `member` · `device` · `device_permission` |
| WIR-09 | n03_screen_time + n05_lock | child_screen_time · child_time_mirror · child_time_request · new_app_approval · time_expiry · child_mode_lock · instant_lock · parent_second_key · tamper_alerts (9) | split in two runs if needed |
| WIR-10 | platform + devices + privacy | platform_monitoring · smart_alert_detail · smart_supervision · settings_hub · mother_permission_level · language_help · audit_log · privacy_data (8) | `audit_log` · capability table |
| WIR-11 | singles | home_router_filter · notification_prefs · emergency_setup (3) | — |
| WIR-12 | static check | empty_state_template · network_error_template · coming_soon (3) | verify no data path is needed; record the call |
| WIR-13 | declared gap | child_focus_sounds (1) | no sound/preference table in v6 — stays a declared gap, not a mock |

## Worker brief (one card per run)

1. Work in `/tmp/opencode/family-os` on branch `feat/real-flutter-build`. `export PATH="/tmp/opencode/fl/flutter/bin:$PATH"`.
2. Read the card's `*_models.dart` + `*_repository.dart` + `*_screen.dart` (+ its existing widget test) before writing code.
3. Read the two reference bridges — `app/lib/features/n17_child_learn/learn_followup_bridge.dart` (12 adapters) and
   `app/lib/features/n14_studio/studio_followup_bridge.dart` — and copy their shape exactly.
4. New file per domain `app/lib/features/<domain>/<name>_followup_bridge.dart`; **add getters to the domain's
   existing runtime** (e.g. `Stage1ReportsRuntime`) — never a second runtime for one domain.
5. Bind each screen with `widget.repository ?? Stage1XRuntime.y` (Rule 25 seam); tests keep injecting.
6. Laws: Rule 23 (never a planted name/number — `Stage1RowVocabulary.childKeyFor`), ADR-042 (rows survive a
   reopen — test it where the card writes), fail-closed empty scope, ع-١ (minutes only through `wallet_ledger`),
   no hardcoded Arabic (`tool/check_hardcoded_strings.dart`), vocabulary constants go in
   `app/lib/core/data/stage1_row_vocabulary.dart`.
7. **Missing column = declared gap** (`''`, `null`, empty list) recorded in the card report. Never invent a number.
8. Gates before reporting: `flutter analyze --fatal-infos` (zero) · `dart run tool/check_hardcoded_strings.dart` ·
   the card's new tests · `flutter test` (full suite).
9. **Do not commit, push, or touch `CONVERSION_LOG.md` / `LOOP_STATE.md` / the vault mirror** — the Orchestrator does that.

## Manager gates (Orchestrator, every card)

1. Re-run analyze + strings gate + full suite itself — a green worker report is not proof.
2. Re-count bound screens (`rg -l 'Stage1[A-Za-z]*Runtime' -g '*_screen.dart' lib/features | wc -l`) and floor-check the delta.
3. Any failure → fix or re-dispatch the same card; never push red.
4. Ship: commit + push (`ls-remote` SHA compare) → CONVERSION_LOG + LOOP_STATE → vault plan + memory card + conversation note → mirror (`المستودع-العمل`).
5. Real ambiguity only → `QUESTIONS.md` + LOOP_STATE BLOCKED + stop the loop; never guess.
