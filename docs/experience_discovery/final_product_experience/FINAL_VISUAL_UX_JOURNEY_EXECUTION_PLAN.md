# FINAL VISUAL · UX · JOURNEY — EXECUTION PLAN

**Date:** 2026-09-25 · **Type:** DOCS-ONLY plan. Nothing here is executed yet.
**Inputs:** `FINAL_VISUAL_UX_JOURNEY_VERIFICATION_PROGRAM.md` (standards) · `FINAL_VISUAL_UX_JOURNEY_FINDINGS.md` (34 code findings + 6 doc drifts) · `FINAL_VISUAL_UX_JOURNEY_MATRIX.md` / `.json` (145 surfaces, 73 journeys, 42 systems).
**Governance:** gate **AUTHORIZED** by Owner decision D12 (2026-09-25) — marker in `PROJECT_EXECUTION_PLAN.md` and `AGENTS.md`. Native/Backend still not authorized. No harness BACKLOG cards are created by this document.
**Current position:** VX-B0…B7 **PASSED** (2026-09-26; Owner TG-7). OD-13 + OD-14 CLOSED. **STOP — await Owner authorize D-FINAL.**
### Decision log (2026-09-25)
| Decision | Answer | Effect |
|---|---|---|
| D12 / OD-12 | AUTHORIZED | Execution may proceed batch by batch |
| D1 / OD-01 | Real AR/EN switch now (bound, persisted locally, app-wide) | VX-B3 implements; VX-B4/B7 add EN (LTR) checks |
| D2 / OD-02 | Glossary approved (§8.1); child screens one gentle line | VX-B3 unblocked |
| D5 / OD-05 | Western digits on Arabic screens | VX-B3 unblocked |
| D7 / OD-07 | Parent SOS records parent + child being viewed | VX-B2 SOS part unblocked |
| D9 / OD-09 | Seed local DB from real roster; UI reads DB; no mock messages (interpretation §8.2) | VX-B6 chat unblocked |
| D3 / OD-03 | YES — raise `ink2` (grey) where needed to WCAG AA 4.5:1; no redesign. **Explicit Owner authorization of a `tokens.dart` change (rule 21)** | VX-B4 token part |
| D4 / OD-04 | YES — blocked role lands on its own home (child → My Day, parent → Today) with a polite AR/EN message; never the gallery | VX-B1 (done, gate pending) |
| D6 / OD-06 | NO CHANGE — `core/policy` defaults untouched; features pass real explicit IDs | VX-B2 call sites only |
| D8 / OD-08 | YES — move sample/demo files to `mock/`, organizational only | New VX-B8 tidy batch (late, optional) |
| D10 / OD-10 | YES — remove the two dead Settings shortcuts (accept invite, SOS alert) | VX-B5 |
| D11 / OD-11 | YES — FAT-077 is a legacy path; redirect to FAT-075 Coming soon (FAT-039 precedent) | VX-B1 (done, gate pending) |

All twelve decisions are answered; no batch is blocked on the Owner except by its own test gate. VX-B2 raised two new questions (OD-13, OD-14) that do not block VX-B3.

---

## 1. Owner-facing note

**What we found.** The app is feature-complete and honest about what is not built yet, but a static pass found four kinds of problems that a family would feel on day one:
1. **Wrong child / wrong family.** Different parts of the app fall back to different "default child" IDs, and several per-child tools ignore which child you opened them from. A father can set a web filter for "Ahmad" and actually change it for a default demo child; the child's side then never sees it.
2. **Trust residue.** Debug code writes files and sends sign-in data to a local network address; a blocked child lands on the developer's colour gallery; the fingerprint button says "signed in" when it did nothing.
3. **Engineering language on screen.** About 50 honesty messages say things like "مغلق Remote", "حتى Native", "MediaProjection", and the status badges read "MOCK-REMOTE" in English — including on children's praise and tutor screens.
4. **Empty or half-connected places.** Family chat has nothing to open on a fresh install, the Alerts centre is never filled, the Today board doesn't show waiting time-requests or app approvals, and a newly added child is shown with a technical ID instead of the name the parent typed.

**Why it matters.** These are the moments that decide whether a parent trusts the app: "Did my setting reach my child?", "Who pressed SOS?", "Why does it call my son child_3fa2?". None requires native or backend work.

**What we recommend.** Seven focused batches, ordered so that shared causes are fixed once: trust residue → context spine → language → shared shell/RTL → dashboard → core journeys → rendered Arabic/visual pass; then one device pass, a re-audit, certification and STOP.

**What will change.** Copy (ARB only), a single child/family/SOS-actor resolver used everywhere, route context for per-child tools, one feedback style, correctly pointing chevrons, dashboard pending items, alerts fed from local events, add-child keeps the name, removal of debug code.

**What remains unchanged.** The frozen prototype layout and flows (KEEP + REFINE), every Owner-locked decision (Q-CEX-001..004), `core/policy/`, `.cursor/rules/`, all native/remote closures, the 128-screen inventory, and the phase map. `tokens.dart` changes only for the D3 contrast value in VX-B4 (Owner-authorized).

**What requires Owner decision.** Nothing further — all 12 decisions (§8) were answered on 2026-09-25. The Owner still runs every test gate.

---

## 2. Sequence

```
AUDIT PROGRAM (this doc set — done)
  → OWNER GATE: OD-12 plan marker + answers to blocking ODs
  → VX-B0  Baseline (analyze + regression net, no code change)
  → VX-B1  Trust residue ............ TEST GATE 1
  → VX-B2  Context spine ............ TEST GATE 2 (+ device mini-check D2)
  → VX-B3  Product language ......... TEST GATE 3
  → VX-B4  Shell, components, RTL ... TEST GATE 4 (BROAD: full suite)
  → VX-B5  Dashboard & system homes . TEST GATE 5
  → VX-B6  Core journey closures .... TEST GATE 6 (+ device mini-check D6)
  → VX-B7  Rendered Arabic/visual pass (all 145 surfaces) ... TEST GATE 7
  → VX-B8  Mock tidy (D8, organizational only) ........ TEST GATE 8 (optional)
  → FINAL DEVICE PASS (D-FINAL)
  → FINAL PRODUCT RE-AUDIT
  → FINAL FRONTEND CERTIFICATION (BROAD: full suite + analyze)
  → STOP
```

Why this order: B1 is cheap and removes trust/privacy risks immediately. B2 must precede every screen verdict because a screen that edits the wrong child cannot pass. B3 before B4 because shared components (badges, hub labels) consume the new ARB keys. B4 before B5/B6 so dashboards and journeys inherit fixed shared pieces. B7 (rendered pass) runs last on the final UI.

All commands below are run **from `app/`**.

---

## 3. Batches

### VX-B0 — Baseline (no production change · Owner-run gate) — **PASSED 2026-09-25**
- **Result (Owner-run):** `flutter analyze` → No issues found! (8.4 s) · app tests → +36 All tests passed! · CE net → +25 All tests passed! · git baseline **pending** (re-issued at the VX-B1 gate as two separate commands). Evidence: `.verify/VX-B0-BASELINE.json`.
- **Objective:** record the starting state (analyze + the regression net every later batch depends on). Cursor could not capture it: its terminal returned no output, and the Dart analyzer tool call did not complete.
- **Scope:** whole app; no code change.
- **Owner-run commands (from `app/`):**
  1. `flutter analyze` — proves the working tree (with all uncommitted CE-B0→B5 changes) compiles cleanly. PASS: `No issues found!`
  2. `flutter test test/app/router_routes_test.dart test/app/role_guard_test.dart test/app/family_shell_test.dart test/app/shell_config_test.dart` — proves routes, role guard, shell tabs/hubs and generated shell config behave as today. PASS: `All tests passed!`
  3. `flutter test test/features/n02_day/ce_b0_chat_delivery_honesty_test.dart test/features/n16_tasks/ce_b1_family_tasks_local_test.dart test/core/family_ops/ce_b1_family_ops_local_test.dart test/features/n07_advisor/ce_b2_reports_empty_first_test.dart test/features/n03_screen_time/ce_b3_control_spine_test.dart test/features/quran/ce_b4_quran_local_test.dart test/features/n08_platform/ce_b5_mock_hardening_test.dart` — proves every CE-B0→B5 closure still holds (the regression net). PASS: `All tests passed!`
  4. `git rev-parse --short HEAD` and `git status --short | Measure-Object -Line` — records the baseline commit and the size of the uncommitted change set. PASS: any output (recorded, not judged).
- **Evidence:** Cursor writes `.verify/VX-B0-BASELINE.json` from the Owner's pasted results (commands, pass/fail, issue count, test counts, SHA).
- **Done when:** Owner reports 1–3 passing (or lists existing issues/failures, which become VX-B0 findings before VX-B1 starts).

### VX-B1 — Trust residue — **PASSED 2026-09-25 (Owner-run gate)**
- **Result (Owner-run):** `flutter analyze` → No issues found! (9.0 s) · 5 new vx_b1 tests → +16 All tests passed! (00:11) · 13 regression tests → +84 All tests passed! (00:37). Findings G-01, G-07, G-09, C-01, C-03, C-04, C-05 CLOSED. Phone checklist deferred to D-FINAL (PENDING-DEVICE).
- **Objectives:** remove debug instrumentation; stop false success; human landing for blocked users; honest local-failure copy; fix dead/fake controls.
- **Findings:** FVX-G-01, G-07, G-09, C-01, C-03, C-04, C-05.
- **Scope (as delivered):** `main.dart`, `login_screen.dart`, `role_guard.dart`, new `app/role_guard_notice.dart`, `router.dart` + `tool/gen_routes.dart` (same edit in both: home-route wrapper + `legacyRedirectPaths`), `create_safe_zone_screen.dart`, `notification_prefs_screen.dart`, `web_filter_screen.dart`, `add_from_source_screen.dart`, `rule_editor.dart`, `my_advisor_screen.dart`, ARB AR+EN + generated `app_localizations*.dart` (5 new keys, 1 removed: `loginBiometricToast` → `loginBiometricUnavailable`). Updated existing tests: `role_guard_test.dart`, `ui_007_billing_screens_test.dart` (`/gallery` expectations → role home).
- **Dependencies:** D4 answered (role home + polite message), D11 answered (FAT-077 → FAT-075), D2 glossary for the fingerprint copy.
- **Expected impact:** no file/network writes from the app; child never sees the gallery; no "server" blame; FAT-041 subject choice real; FAT-079 rules show readable titles.
- **Tests (existing):** `flutter test test/app/role_guard_test.dart test/features/shared_onboarding/login_screen_test.dart test/features/n02_day/create_safe_zone_screen_test.dart test/features/n06_notifications/notification_prefs_screen_test.dart test/features/n04_web_filter/web_filter_screen_test.dart test/features/n14_studio/add_from_source_screen_test.dart test/features/n07_advisor/rule_editor_test.dart test/features/n07_advisor/my_advisor_screen_test.dart`
- **Tests (new, written):** `test/app/vx_b1_no_debug_residue_test.dart`, `test/app/vx_b1_role_guard_landing_test.dart` (D4 + D11), `test/features/shared_onboarding/vx_b1_login_fingerprint_honesty_test.dart`, `test/features/n14_studio/vx_b1_add_from_source_subject_test.dart`, `test/features/n07_advisor/vx_b1_rule_title_label_test.dart`.
- **Owner-run gate commands:** see the VX-B1 gate issued to the Owner (analyze; new tests; existing touched-screen tests incl. `test/features/n11_billing/ui_007_billing_screens_test.dart`, `test/features/n13_coming_soon/ui_013_coming_soon_test.dart`, `test/features/n01_linking/create_family_screen_test.dart`; `test/app/router_routes_test.dart`; git baseline).
- **Device checklist:** cold start + login → confirm no `debug-296a8e.log` is created and nothing is sent to `127.0.0.1:7833`; fingerprint button → honest "coming later" toast, stays on login; child role tries an owner-only screen → lands on My Day with the gentle toast; mother tries Plans → lands on Today with the owner-only toast; open `/scr-fat-077` → Coming soon page.
- **Evidence:** `.verify/VX-B1-TRUST.json`.
- **Done when:** all above pass; `flutter analyze` on touched files clean; findings marked CLOSED in the findings register.

### VX-B2 — Context spine (child · family · SOS actor · device) — **PASSED 2026-09-26**
- **Delivered:** `core/identity/active_child_resolver.dart` (child/family/device over `IdentityRuntime`), `core/identity/sos_sender.dart` (D7), `app/route_child_context.dart`; per-child builders in `tool/gen_routes.dart` + `router.dart` (FAT-032/036/037/065/067/068/072/085, CHD-004/005/010/021); child profile selects the active child and opens Device health with the linked device; Today + safe zones + location screens follow the active family; ≈80 SOS call sites use the sender rule. No `core/policy`, `tokens.dart`, ARB or `.cursor/rules` change. Open: OD-13, OD-14.
- **Objectives:** one resolver for the active child; per-child routes forward `childId`; family scope from identity; one SOS actor rule; device lookup by child.
- **Findings:** FVX-G-03, G-04, G-05 (feature and runtime call sites), G-06, S-06; unblocks the loop register (Matrix §4).
- **Scope:** `tool/gen_routes.dart` + regenerated `router.dart` (PERCHILD set: FAT-033, 036, 037, 051, 065, 066, 067, 069, 072, 085, CHD-004, CHD-021); feature fallbacks listed in G-03; `day_board_projection.dart` family function; SOS entry points; device health seam lookup. `core/policy` defaults untouched unless OD-06 = change.
- **Dependencies:** OD-07 answered (D7: parent + child being viewed; parent only when no child is in view). OD-06 answered **NO CHANGE** — `core/policy` defaults stay; every feature call site passes the real explicit childId/context.
- **Expected impact:** father's change for a named child reaches that child's screens; Today and Kids agree after a family switch; SOS alert names the right person.
- **Tests (existing):** `flutter test test/app/router_routes_test.dart test/features/n05_lock/instant_lock_screen_test.dart test/features/n04_web_filter/web_filter_screen_test.dart test/features/n03_screen_time/child_screen_time_screen_test.dart test/features/n03_screen_time/ce_b3_control_spine_test.dart test/features/n03_screen_time/ui_011_time_expiry_test.dart test/features/n02_day/child_day_board_screen_test.dart test/features/n14_studio/quran_progress_screen_test.dart test/features/n17_child_learn/child_quran_ward_screen_test.dart test/features/quran/ce_b4_quran_local_test.dart test/features/n02_day/day_board_screen_test.dart test/features/n02_day/children_list_repository_family_scope_test.dart test/features/n02_day/child_profile_screen_test.dart test/features/n12_devices/device_health_detail_screen_test.dart test/features/n12_devices/device_health_seam_family_scope_test.dart test/features/n10_emergency/sos_alert_screen_test.dart test/features/n10_emergency/child_sos_button_screen_test.dart test/core/policy/sos_break_glass_test.dart`
- **Tests (new, written):** `test/app/vx_b2_perchild_route_context_test.dart` (router + generator source guard; query child wins, blank → context child, scoped key), `test/core/identity/vx_b2_active_child_resolver_test.dart` (resolver, in-family selection, family switch, device lookups, no `demo-child`/`child_demo`/`child_1` literals in `features/`), `test/features/vx_b2_father_child_loop_test.dart` (two children: Quran plan for child 2 is read by child 2, not child 1), `test/features/n10_emergency/vx_b2_sos_sender_test.dart` (parent + viewed child; parent only; child self; widget checks on CHD-011 and FAT-072), `test/features/n02_day/vx_b2_day_board_family_scope_test.dart` (Today + safe zones on family switch). Command: `flutter test test/app/vx_b2_perchild_route_context_test.dart test/core/identity/vx_b2_active_child_resolver_test.dart test/features/vx_b2_father_child_loop_test.dart test/features/n10_emergency/vx_b2_sos_sender_test.dart test/features/n02_day/vx_b2_day_board_family_scope_test.dart`
- **Device mini-check D2:** two children in roster → set web filter + lock for child 2 from child 2's profile → switch device user to child 2 (SHR-008) → child side reflects; fire SOS as child 2 → FAT-018 shows child 2.
- **Evidence:** `.verify/VX-B2-CONTEXT.json`.
- **Done when:** loop register rows (Matrix §4) move from FAIL to PASS-candidate; all tests pass.

### VX-B3 — Product language (honesty glossary, numerals, language setting)
- **Objectives:** human honesty wording in AR (and EN), child tone on child screens, localized badge labels, one numeral formatter, language setting honest or real, ARB-backed hub labels, data-bound praise topic.
- **Findings:** FVX-G-02, G-15, S-07, S-08 (conditional), C-06, G-08 (label part).
- **Scope:** `app_ar.arb`, `app_en.arb` (value edits + new keys), regenerated localizations, `capability_honesty_badge.dart` (labels only), a numeral helper in `core/i18n/`, `tool/gen_routes.dart` hub label keys, `language_help_screen.dart`, `main.dart` locale (only if OD-01 = enable).
- **Dependencies:** all answered — D2 (glossary §8.1, one gentle child line), D5 (Western digits: remove `toEasternDigits` use, store demo seed numbers as numbers), D1 (real AR/EN switch persisted through the existing prefs-misc local store, applied via `MaterialApp.locale`; English strings for hub labels and demo seed display names).
- **Expected impact:** every "closed" line reads like a sentence a parent or child understands; no English badge text in Arabic; digits consistent.
- **Tests (existing):** `flutter test test/core/design/components/capability_honesty_badge_test.dart test/features/n12_devices/language_help_screen_test.dart test/app/shell_config_test.dart test/app/family_shell_test.dart test/features/n02_day/ce_b0_chat_delivery_honesty_test.dart test/features/n17_child_learn/child_result_screen_test.dart test/features/n17_child_learn/child_tutor_screen_test.dart test/features/n04_web_filter/home_router_filter_screen_test.dart`
- **Tests (new, proposed):** `test/core/i18n/vx_b3_arb_human_language_test.dart` (AR values contain no `Native|Remote|REMOTE|FCM|Backend|MediaProjection|MOCK|Gateway` outside an allow-list; AR/EN key parity), `test/core/i18n/vx_b3_numeral_format_test.dart`, `test/app/vx_b3_hub_labels_localized_test.dart`. Command: `flutter test test/core/i18n/vx_b3_arb_human_language_test.dart test/core/i18n/vx_b3_numeral_format_test.dart test/app/vx_b3_hub_labels_localized_test.dart`
- **Regression note:** honesty tests that assert exact old strings must be updated to assert the key/meaning, not the jargon.
- **Device checklist:** read 10 honesty lines aloud to a non-technical family member — each is understood without explanation.
- **Evidence:** `.verify/VX-B3-LANGUAGE.json` (includes glossary version).
- **Done when:** guard test green; OD-02/05/01 recorded as answered.

### VX-B4 — Shell, shared components & RTL mechanics
- **Objectives:** one feedback system; correct chevrons; directional alignment; responsive map art; token-only colours; a shared loading state; consistent `push` for drill-downs; hub entries that carry or don't need context.
- **Findings:** FVX-G-08 (context part), G-10, G-11, G-12, G-13, G-14 (component + OD-03), G-17 (non-dashboard sites).
- **Scope:** ~14 SnackBar files → `AppToast`; ~25 chevron sites; ~20 `Alignment.*Left/Right`; 4 map-art screens; 11 colour-literal sites + `Colors.white`; new `core/design/components/app_loading_state.dart`; `family_shell.dart` per-child set (FAT-014/016/017/085); hub list (FAT-026).
- **Dependencies:** OD-03 answered **YES** — Owner-authorized `tokens.dart` change (rule 21) limited to raising `ink2` (and only where needed) to WCAG AA 4.5:1 for body/small text; no other token or layout change. D1 adds LTR work: shell FABs `Positioned(left: 16)` → directional (previous NO ACTION N-08 reopened), `Alignment.*Left/Right` → `AlignmentDirectional`.
- **Affected-surface list (required before change):** grep usages of each changed component and list them in the batch notes.
- **Tests (existing):** `flutter test test/app/family_shell_test.dart test/app/shell_config_test.dart test/features/n02_day/location_map_screen_test.dart test/features/n02_day/create_safe_zone_screen_test.dart test/features/n10_emergency/sos_alert_screen_test.dart test/features/n01_linking/link_success_screen_test.dart test/features/n02_day/conversation_screen_test.dart test/features/n02_day/child_chats_screen_test.dart test/features/n02_day/alert_detail_screen_test.dart test/features/n03_screen_time/child_apps_screen_test.dart test/features/n12_devices/mother_permission_level_screen_test.dart test/features/n03_screen_time/new_app_approval_screen_test.dart`
- **Tests (new, proposed):** `test/core/design/components/vx_b4_app_loading_state_test.dart`, `test/app/vx_b4_design_residue_guard_test.dart` (no `ScaffoldMessenger` in features, no `Color(0x` in features, no `Icons.chevron_left` as trailing row affordance), `test/goldens/vx_b4_rtl_representative_test.dart` (AR, 360 dp: FAT-010, FAT-012, FAT-013, FAT-025, CHD-004, CHD-012). Command: `flutter test test/core/design/components/vx_b4_app_loading_state_test.dart test/app/vx_b4_design_residue_guard_test.dart test/goldens/vx_b4_rtl_representative_test.dart`
- **BROAD GATE:** `flutter analyze` then `flutter test` (full suite) — shared layer changed.
- **Device checklist:** 360 dp phone: map screens don't clip; chevrons point to the reading-forward side; toasts not hidden behind tab bar/FAB; Back from every hub tile returns to the tab.
- **Evidence:** `.verify/VX-B4-SHELL-RTL.json` (+ golden images).
- **Done when:** guard + goldens + full suite pass.
- **Status: PASSED 2026-09-26** — Owner TG-4 full suite `+1548: All tests passed!`

### VX-B5 — Dashboard & system homes
- **Objectives:** Today shows what needs a parent's decision, with child context and correct Back; Alerts centre fed from local events; Settings shortcuts sane; SOS screen has a designed "no active alert" state.
- **Findings:** FVX-S-03, S-02, S-09, C-08, G-17 (dashboard sites).
- **Scope:** `day_board_projection.dart`, `day_board_screen.dart`, alerts hub/detail repositories (projection from `core/events/local_event_journal.dart` and existing alert buses), `family_shell.dart` settings shortcuts, `sos_alert_screen.dart` empty state.
- **Dependencies:** VX-B2 (resolver), VX-B3 (last-synced wording). OD-10 answered **YES** — remove the Settings shortcuts to FAT-009 (accept invite) and FAT-018 (SOS alert) only; Settings structure and all valid navigation unchanged; the FAT-018 "no active alert" state proceeds.
- **Tests (existing):** `flutter test test/features/n02_day/day_board_screen_test.dart test/features/n02_day/alerts_hub_screen_test.dart test/features/n02_day/alert_detail_screen_test.dart test/features/n02_day/ui_006_request_inbox_test.dart test/features/n12_devices/settings_hub_screen_test.dart test/app/family_shell_test.dart test/features/n10_emergency/sos_alert_screen_test.dart test/features/n02_day/friend_approval_screen_test.dart test/core/events/evt01a_local_event_bind_test.dart`
- **Tests (new, proposed):** `test/features/n02_day/vx_b5_day_board_pending_sources_test.dart` (time request + app approval + friend request appear; athkar goes to a parent screen; quick actions carry `childId` and use push), `test/features/n02_day/vx_b5_alerts_hub_projection_test.dart` (tamper/SOS/time-request event → hub row), `test/features/n10_emergency/vx_b5_sos_no_alert_state_test.dart`. Command: `flutter test test/features/n02_day/vx_b5_day_board_pending_sources_test.dart test/features/n02_day/vx_b5_alerts_hub_projection_test.dart test/features/n10_emergency/vx_b5_sos_no_alert_state_test.dart`
- **Device checklist:** child requests time → parent Today shows it within one refresh → approve → child sees minutes; Back from every Today drill-down returns to Today.
- **Evidence:** `.verify/VX-B5-DASHBOARD.json`.
- **Done when:** dashboard audit (Program §10) PASS-candidate for FAT-010 and CHD-004.
- **Status: PASSED 2026-09-26** — Owner TG-5: analyze clean; vx_b5 `+6`; related suite `+60`.

### VX-B6 — Core journey closures
- **Objectives:** add-child keeps name/age/colour; new-child rows render cleanly; safe-zone form residue removed; login honest; family chat usable on one device (per OD-09); device-user switch bound.
- **Findings:** FVX-S-04, C-07, S-05, C-02, S-01 (OD-09), local-reality item SHR-008.
- **Scope:** `add_child_screen.dart` + identity roster write, `children_list_screen.dart`, `create_safe_zone_screen.dart`, `login_screen.dart`, chat repositories binding (only if OD-09 = local thread), `device_user_switch` binding.
- **Dependencies:** OD-09 answered (D9, interpretation §8.2): add a chat local persistence adapter on the existing `FsSessionKernel` → `LocalDatabase` (same pattern as `family_tasks_local_persistence.dart`), bind `stage1ConversationsListRepository` / `stage1ConversationRepository` / `stage1ChildChatsRepository` at boot, seed family thread(s) from the real roster/identity on first run, **no seeded messages**. VX-B2, VX-B3 first.
- **Tests (existing):** `flutter test test/features/n01_linking/add_child_screen_test.dart test/features/n02_day/children_list_screen_test.dart test/features/n02_day/create_safe_zone_screen_test.dart test/features/shared_onboarding/login_screen_test.dart test/features/n02_day/conversations_list_screen_test.dart test/features/n02_day/conversation_screen_test.dart test/features/n02_day/child_chats_screen_test.dart test/features/n02_day/child_conversation_screen_test.dart test/features/n02_day/ce_b0_chat_delivery_honesty_test.dart test/core/identity/dom_identity_b_roster_seed_test.dart`
- **Tests (new, proposed):** `test/features/n01_linking/vx_b6_add_child_keeps_name_test.dart` (restart-proof), `test/features/n02_day/vx_b6_family_thread_local_test.dart` (thread seeded from roster, restart-proof, zero seeded messages, send persists), `test/features/shared_onboarding/vx_b6_login_validation_test.dart`. Command: `flutter test test/features/n01_linking/vx_b6_add_child_keeps_name_test.dart test/features/n02_day/vx_b6_family_thread_local_test.dart test/features/shared_onboarding/vx_b6_login_validation_test.dart`
- **Device mini-check D6:** add a child named in Arabic → kill app → relaunch → name shown everywhere (Kids, Today, profile); send a family message as father, kill app, relaunch, switch to child, read it.
- **Evidence:** `.verify/VX-B6-JOURNEYS.json`.
- **Done when:** JRN-FAT-02/06/08/11, JRN-CHD-04 PASS-candidate.
- **Status: PASSED 2026-09-26** — Owner TG-6: analyze clean; vx_b6 `+4`; related suite `+69`.

### VX-B7 — Rendered Arabic/RTL & visual pass (all surfaces)
- **Objective:** apply Program §5–§6 and §13 to every one of the 145 surfaces on rendered screenshots; fix only residue found (screen scope), no new features.
- **Scope:** all rows still `PR` in the matrix.
- **Method:** screenshot each surface at 360 dp and 412 dp, font scale 1.0 and 1.3, in Arabic (RTL) **and English (LTR)** per D1; fill Vis/UX/RTL cells with PASS/FAIL; any FAIL → new finding `FVX-R-nn` → smallest fix in this batch.
- **Tests:** existing screen test for any touched screen + `flutter test test/goldens/` (goldens extended to one per system home: FAT-010, 012, 021, 025, 040, 019, CHD-004, 012, 007, 010).
- **Evidence:** `.verify/VX-B7-RENDER.json` + screenshot index `docs/experience_discovery/final_product_experience/render/INDEX.md` (to be created in the batch).
- **Done when:** matrix has no `PR` cells.
- **Status: PASSED 2026-09-26** — Owner TG-7: analyze clean; system-home render `+80`; vx_b4 RTL `+3`. CHD-012 overflow FIXED. Remaining non-home PR → D-FINAL.

### FINAL DEVICE PASS (D-FINAL)
- Program §13 checklist (9 items) on one small (≤ 360 dp) and one normal Android phone.
- **Evidence:** `.verify/VX-DEVICE-FINAL.json` (device, Android version, tester, date, per-item result).
- Matrix has no `PD` cells.

### FINAL PRODUCT RE-AUDIT
- Re-run Program §19 ten-area check against the matrix and findings; confirm every finding CLOSED, NATIVE/REMOTE-closed with honest state, or Owner-deferred in QUESTIONS.md.
- Update `FRONTEND_COMPLETION_MATRIX.md` / `PROGRESS` with CE and VX entries (closes FVX-D-03), correct FVX-D-02/D-04 texts.
- **Evidence:** `.verify/VX-FINAL-REAUDIT.json`.

### FINAL FRONTEND CERTIFICATION
- **Commands:** `flutter analyze` → 0 issues; `flutter test` (full suite) → all pass; `python .cursor/hooks/verify_ship.py verify --full` (harness gate) → exit 0.
- One line in `CONVERSION_LOG.md`; marker in `PROJECT_EXECUTION_PLAN.md` (Owner-authorized).
- **Evidence:** `.verify/VX-FINAL-CERTIFICATION.json`.
- **Then: STOP.**

### VX-B8 — Mock tidy (Owner D8 · optional · late)
- **Objective:** move sample/demo-data files that live in `features/` (e.g. `*_mock.dart`, seed fixtures) into `mock/`, behind the same repository interfaces.
- **Rules:** organizational only — zero runtime behavior change, no new authority, no screen change; imports updated; deleting `mock/` must still leave the app compiling (rule 23) where already true.
- **Tests:** `flutter analyze` + the tests importing moved files + the CE net.
- **Evidence:** `.verify/VX-B8-MOCK-TIDY.json`.

---

## 4. Test gates summary

### 4.1 Owner-run test-gate protocol (standing Owner instruction, 2026-09-25 — applies to every batch)
1. **Bassam runs all Flutter verification commands manually** in his terminal (`flutter analyze`, `flutter test`, `python .cursor/hooks/verify_ship.py verify [--full]`) and sends the results. **Cursor does not run them.**
2. At each gate Cursor provides only: the exact focused command(s), run from `app/` (verify_ship from the repo root); what each command proves; what PASS looks like. Then Cursor **stops and waits**.
3. Keep gates fast and focused: `flutter analyze <touched files>` and targeted test files. The full suite runs only at the milestone gates already defined as broad: **TG-4** (full `flutter test`) and **TG-FINAL** (`verify --full`).
4. On PASS: Cursor records the pasted result in `.verify/VX-Bn-*.json`, one line in `CONVERSION_LOG.md`, and updates the matrix. On FAIL: Cursor fixes, then hands back the **same** command.
5. No batch starts production changes until the previous gate's result is reported.

| Gate | After | Command set | Tier |
|---|---|---|---|
| TG-0 | VX-B0 | analyze + app tests + CE net (Owner-run; **PASSED**) | focused |
| TG-1 | VX-B1 | §VX-B1 existing + new (Owner-run; **PASSED**) | focused |
| TG-2 | VX-B2 | §VX-B2 existing + new (Owner-run; **pending**) | focused |
| TG-3 | VX-B3 | §VX-B3 existing + new | focused |
| TG-4 | VX-B4 | §VX-B4 + `flutter test` full | **broad** |
| TG-5 | VX-B5 | §VX-B5 existing + new | focused |
| TG-6 | VX-B6 | §VX-B6 existing + new | focused |
| TG-7 | VX-B7 | touched screen tests + goldens | focused |
| TG-8 | VX-B8 | analyze + tests importing moved files + CE net | focused (optional) |
| TG-FINAL | Certification | analyze + full + `verify --full` | **broad** |

Protocol: §4.1 (supersedes the "or authorizes Cursor to run" option in Program §18).

## 5. Device gates summary

| Gate | When | Checks |
|---|---|---|
| D1 | after VX-B1 | no debug files/requests; blocked child landing |
| D2 | after VX-B2 | two-child loop; SOS actor |
| D6 | after VX-B6 | add child restart-proof; family thread from local database survives restart (D9) |
| D-FINAL | before re-audit | full Program §13 checklist, two phone sizes |

## 6. Blockers (closed capabilities — not opened by this plan)

- **NATIVE_CLOSED:** OS app blocking, VPN/DNS filtering, system lock, live GPS/battery/heartbeat, calls (LiveKit), camera/mic/file picker/QR camera, MediaProjection capture, biometrics, OS wake for modes.
- **REMOTE_CLOSED:** push/FCM/SMS, email/PDF export, multi-device chat relay, AI Gateway (Advisor/Insights/Tutor/Agent), licensed Quran audio pack, billing/store, account backend.
These are verified only for **honest closed state** (BLOCKED-NATIVE / BLOCKED-REMOTE with passing copy).

## 7. Risks and regression protection

| Risk | Mitigation |
|---|---|
| Router regeneration changes many routes | `router_routes_test.dart` + new PERCHILD guard; diff review of generated file only in PERCHILD builders |
| ARB rewrite breaks tests asserting old strings | update assertions to keys/meaning in the same batch; guard test prevents jargon returning |
| Resolver change alters prior CE closures | CE regression net runs in every batch |
| Shared component change affects 85+ screens | affected-surface list + broad gate at TG-4 |
| Owner-locked Q-CEX behavior altered | Q-CEX tests in every batch; no copy change on those surfaces without Owner |

## 8. Owner decisions (numbered, with options)

Status as of 2026-09-26: OD-01…OD-14 **answered**. OD-13 and OD-14 **CLOSED** (Owner-run gates; see `.verify/OD-13-SOS-PARENT-CHILD.json` · `.verify/OD-14-EDU-ROSTER.json`).

| # | Decision | Options | Status | Blocks |
|---|---|---|---|---|
| **OD-01** | English interface | (a) enable real AR/EN switch now; (b) stay Arabic-only | **ANSWERED — (a)** real switch, persisted locally, app-wide | — (VX-B3 implements) |
| **OD-02** | Honesty wording glossary | (a) approve a short glossary; (b) Owner wording; child: (i) one gentle line, (ii) none | **ANSWERED — (a)+(i)**; glossary v1 in §8.1 | — (VX-B3 implements) |
| **OD-03** | Secondary text contrast (`ink2`, tokens frozen) | (a) darken `ink2` to ≈4.6:1; (b) keep token, use `ink` for text < 14 px; (c) no change | **ANSWERED — (a)** WCAG AA 4.5:1 where needed; explicit rule-21 authorization for `tokens.dart` | — (VX-B4 implements) |
| **OD-04** | Role-guard blocked landing / dev gallery | (a) role home + toast, gallery debug-only; (b) role home, gallery removed from release; (c) keep | **ANSWERED** — own role home (child → My Day, parent → Today) + polite AR/EN message; gallery never the landing | — (VX-B1 done) |
| **OD-05** | Numerals in Arabic UI | (a) Eastern digits; (b) Western digits | **ANSWERED — (b)** Western digits | — (VX-B3 implements) |
| **OD-06** | `core/policy` default IDs (`SmartModePrefs.defaultChildId`, `DesiredMonitoringPrefs.defaultChildId`, `fam_stage1` defaults in `sos_break_glass`/`web_unlock_service`) | (a) authorize minimal core/policy change; (b) leave core/policy; features pass explicit IDs | **ANSWERED — (b)** no core/policy change | — (VX-B2 call sites) |
| **OD-07** | Parent-originated SOS actor | (a) parent; (b) "family"; (c) parent + viewed child | **ANSWERED — (c)**; parent only when no child in view | — (VX-B2 implements) |
| **OD-08** | Mock files inside `features/` (rule 23) | (a) relocate to `mock/` in optional hygiene batch; (b) defer to Backend | **ANSWERED — (a)** organizational only | — (VX-B8) |
| **OD-09** | Family chat data source | (a) local roster thread, local persistence; (b) empty inactive state | **ANSWERED** — seed the local database from real data, UI reads the database, no mock data (interpretation §8.2) | CLOSED with VX-B6 PASSED 2026-09-26 |
| **OD-10** | Settings "other" shortcuts | (a) remove FAT-009 + FAT-018 shortcuts; (b) keep | **ANSWERED — (a)** | CLOSED with VX-B5 PASSED 2026-09-26 |
| **OD-11** | SCR-FAT-077 Road safety (OOS but routed) | (a) tombstone-redirect like FAT-039; (b) keep unlinked route | **ANSWERED — (a)** redirect to FAT-075 Coming soon | — (VX-B1 done) |
| **OD-12** | Plan marker | (a) add marker; (b) planning only | **ANSWERED — (a)** marker added | — |
| **OD-13** | SOS record holding **parent + viewed child** (D7) and a durable incident for parent-raised SOS | (a) authorize a minimal `core/policy` change (`SosFireService.fire` gains an optional actor field; parent SOS opens a sos_final incident); (b) keep as delivered — the record names the viewed child (else the parent), the acting parent is not stored | **CLOSED — (a)** 2026-09-26 | D7 complete; schema v11 `raised_by_actor_id` |
| **OD-14** | Education loops keyed on the `child_a` fixture (child learn home, child quiz, assignment/task/event/results/focus/attribution pickers) | (a) move both sides to roster children; (b) keep until Backend | **CLOSED — (a)** 2026-09-26 | roster binder; no planted `child_a` in education loops |

### 8.1 Honesty glossary v1 (Owner-approved direction, D2; exact wording editable by Owner at TG-3)
| Case | Arabic | English |
|---|---|---|
| Works locally only | محفوظ على هذا الجهاز فقط | Saved on this device only |
| Other devices later | سيصل إلى الأجهزة الأخرى في تحديث قادم | Will reach other devices in an upcoming update |
| Child-device enforcement later | التطبيق الفعلي على جهاز الابن يتوفر في تحديث قادم | Enforcement on your child's device arrives in an upcoming update |
| AI later | مساعد العائلة الذكي يتوفر في تحديث قادم | The family assistant arrives in an upcoming update |
| Export later | المشاركة بالبريد أو PDF تتوفر لاحقًا | Sharing by email or PDF comes later |
| Device permission later | يحتاج صلاحية من الجهاز — يتوفر لاحقًا | Needs a device permission — coming later |
| **Child screens (one line only)** | بعض الأشياء هنا تعمل على هذا الجهاز فقط الآن 🌱 | Some things here work on this device only for now 🌱 |

Badge labels: IMPLEMENTED → يعمل / Works · MOCK-REMOTE → على هذا الجهاز / On this device · DEGRADED → يعمل جزئيًا / Partly working · UNSUPPORTED → غير مدعوم / Not supported · NOT IMPLEMENTED → قريبًا / Coming soon.
Banned on screen (guard test in VX-B3): Native, Remote, MOCK, FCM, MediaProjection, LiveKit, relay, backend, gateway (English in AR strings, and in EN user-facing strings).

### 8.2 D9 recorded interpretation and conflict flags
- **Owner words:** "Seed the database for everything related to this area, then use data from a real database, not mock data."
- **Interpretation (Backend/Remote NOT authorized):** "real database" = the existing on-device SQLite authority (`FsSessionKernel` → `LocalDatabase`). No second authority; `core/policy/chat_mock_store.dart` is not used as the store (core/policy frozen, and it is a mock).
- **Seeded:** family thread(s) and their participants, derived from the real family roster/identity on first run (idempotent; new members join the thread when added).
- **Not seeded:** messages (inventing messages would be fake content — rule 23), call history, active calls (calls stay NATIVE_CLOSED).
- **Conflict flags:** (1) a remote/cloud database would stay REMOTE_CLOSED — delivery to the other parent's or child's own phone is not possible until Backend is authorized; the thread shows the glossary line "Saved on this device only". (2) If SQLite is unavailable the kernel falls back to memory — the chat must say it is not saved, not pretend. (3) The existing chat mock files in `features/n02_day/` stop being used at runtime; their relocation/deletion is OD-08 (still open).
| Carried | AUD-C*, REP-C* (PDF mandate), CHAT-C* | unchanged — remain Owner-locked | not in scope |

## 9. Completion criteria for the whole program

- All 34 code findings CLOSED, or classified NATIVE_CLOSED / REMOTE_CLOSED with honest state, or Owner-deferred in QUESTIONS.md.
- Matrix: 0 `PR`, 0 `PD`, 0 `F:` cells; journeys 73/73 resolved; systems 42/42 resolved.
- `.verify/VX-*.json` present for B0–B7, device, re-audit, certification.
- Full `flutter analyze` 0 issues; full `flutter test` pass; harness `verify --full` exit 0.
- STOP recorded.
