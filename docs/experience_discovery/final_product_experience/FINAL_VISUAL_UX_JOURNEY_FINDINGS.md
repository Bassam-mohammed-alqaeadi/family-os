# FINAL VISUAL · UX · JOURNEY — STATIC FINDINGS REGISTER

**Date:** 2026-09-25
**Type:** DOCS-ONLY pre-audit (static inspection of code + docs). **No production code changed.**
**Companion docs:** `FINAL_VISUAL_UX_JOURNEY_VERIFICATION_PROGRAM.md` · `FINAL_VISUAL_UX_JOURNEY_MATRIX.md` (+ `.json`) · `FINAL_VISUAL_UX_JOURNEY_EXECUTION_PLAN.md`
**Authority order:** Policy Register (`handoff/04_POLICY_REGISTER_EN.md`) → frozen prototype → Owner Q-CEX-001..004 → handoff → code as implementation evidence.

## 0. How to read this register

- **ID scheme:** `FVX-G-nn` = GLOBAL (pattern across systems) · `FVX-S-nn` = SYSTEM · `FVX-C-nn` = SCREEN · `FVX-D-nn` = documentation / registry drift (no code).
- **Scope class:** GLOBAL / SYSTEM / SCREEN.
- **Nature class:** CONTROL · UX · VISUAL · NAVIGATION · STATE · DATA · HONESTY · RTL · DEVICE · NATIVE_CLOSED · REMOTE_CLOSED · OWNER_DECISION (a finding may carry more than one).
- **Priority (wording, not a score):** CRITICAL (trust/privacy/safety — fix first) · HIGH (breaks a family loop or misleads) · MEDIUM (friction, inconsistency) · LOW (polish).
- **Static confidence:** CONFIRMED (read in code) · PENDING-RENDER (needs a rendered check to confirm the visible effect) · PENDING-DEVICE.
- **Evidence limitation:** the shell tool was unavailable in this session, so `git`, `flutter analyze` and test runs could not be executed. All evidence is file:line from direct reads/greps. Line numbers are as of 2026-09-25 working tree (uncommitted CE-B0→B5 changes included).

## 1. Summary counts

| Class | Count |
|---|---:|
| GLOBAL findings | 17 |
| SYSTEM findings | 9 |
| SCREEN findings | 8 |
| DOC / registry drift | 6 |
| **Total actionable or decision findings** | **40** |
| Explicit NO ACTION confirmations | 16 |

Primary nature of the 34 code findings (G + S + C; the 6 D items are documentation only):

| Nature (primary) | Count | IDs |
|---|---:|---|
| CONTROL | 6 | G-03, G-06, S-01, S-04, S-07, C-03 |
| NAVIGATION | 6 | G-04, G-07, G-08, G-17, S-06, S-09 |
| HONESTY | 5 | G-01, G-02, G-09, S-08, C-01 |
| UX | 4 | S-03, S-05, C-02, C-04 |
| VISUAL | 4 | G-10, G-13, G-14, C-07 |
| RTL | 3 | G-11, G-12, G-15 |
| DATA | 3 | G-05, G-16, C-06 |
| STATE | 2 | S-02, C-08 |
| OWNER_DECISION (primary) | 1 | C-05 |
| DEVICE | 0 | device effects are carried as PENDING-DEVICE checks (Program §13) |
| NATIVE_CLOSED / REMOTE_CLOSED (new) | 0 | existing closures stay closed and honest — §6 |

**Owner decisions (updated 2026-09-25):** originally 10 findings needed an Owner choice. Answered and now **actionable**: G-02 (D2 glossary), G-06 (D7 parent + viewed child), G-15 (D5 Western digits), S-01 (D9 local database seeded from roster), S-07 (D1 real AR/EN switch); S-08 becomes active under D1; N-08 is reopened into G-12 under D1. Second round (same day): G-03 → D6 NO CHANGE to `core/policy` (call sites only, VX-B2); G-07 → D4 (VX-B1); G-14 → D3 YES, Owner-authorized `tokens.dart` contrast change (VX-B4); G-16 → D8 YES (VX-B8 tidy); S-09 → D10 YES (VX-B5); C-05 → D11 YES (VX-B1). **No finding waits on the Owner any more.**

**VX-B1 status (2026-09-25): PASSED (Owner-run; `.verify/VX-B1-TRUST.json`)** — G-01, G-07, G-09, C-01, C-03, C-04, C-05 are **CLOSED — FIXED, PASSED 2026-09-25**. Their phone checks are PENDING-DEVICE (final device pass).

**VX-B4 status (2026-09-26): PASSED (Owner-run; `.verify/VX-B4-SHELL-RTL.json` · full suite +1548)** — G-08, G-10, G-11, G-12, G-13, G-14 **CLOSED**. G-17 partial (non-dashboard SOS/push done; dashboard remained VX-B5). Phone checks PENDING-DEVICE.

**VX-B5 status (2026-09-26): PASSED (Owner-run; `.verify/VX-B5-DASHBOARD.json` · analyze + vx_b5 +6 + related +60)** — S-02, S-03, S-09, C-08, G-17 **CLOSED**. Phone checks PENDING-DEVICE.

**VX-B6 status (2026-09-26): PASSED (Owner-run; `.verify/VX-B6-JOURNEYS.json` · analyze + vx_b6 +4 + related +69)** — S-04, C-07, S-05, C-02, S-01, SHR-008 **CLOSED**. Phone / D6 mini-check PENDING-DEVICE.

**VX-B7 status (2026-09-26): PASSED (Owner-run; `.verify/VX-B7-RENDER.json` · analyze + render +80 + vx_b4 +3)** — system-home Vis/UX/RTL smoke **CLOSED**; FVX-R-01 (CHD-012 overflow) **CLOSED**. Non-home PR + device → D-FINAL.

**VX-B2 status (2026-09-25): code done, Owner test gate pending** — G-03, G-04, G-05, G-06, S-06 are FIXED-PENDING-GATE (details on each finding). Two new Owner questions came out of VX-B2: **OD-13** (store parent + child on one SOS record — needs `core/policy`) and **OD-14** (move the education `child_a` fixtures onto roster children) — see `QUESTIONS.md`.

| Priority | Count |
|---|---:|
| CRITICAL | 3 (G-01, G-03, G-06) |
| HIGH | 9 (G-02, G-04, G-05, G-07, S-01, S-02, S-03, S-04, C-01) |
| MEDIUM | 16 |
| LOW | 6 (G-12, G-13, G-16, S-08, C-05, C-07) |

---

## 2. GLOBAL findings (systemic patterns)

### FVX-G-01 — Debug instrumentation ships in production code (file write + network POST)
- **Scope / nature:** GLOBAL · HONESTY · DATA · (privacy) — **CRITICAL** — CONFIRMED
- **Affected:** app boot (all screens), SCR-SHR-003 Login.
- **Evidence:**
  - `app/lib/main.dart:63–89` — `// #region agent log` block imports `dart:io`, writes identity boot flags to `D:\special projects\family\debug-296a8e.log`, and prints `AGENT_DEBUG` lines.
  - `app/lib/features/shared_onboarding/login_screen.dart:14–55` — `_agentDebugLog` writes the same file **and POSTs via `HttpClient` to `http://127.0.0.1:7833/ingest/4add46c7-…`** with header `X-Debug-Session-Id`, carrying session data; called from the login flow (~lines 87–150).
- **Why it matters to a family:** a parent's sign-in step sends session details to a network endpoint and writes to a hard-coded Windows path. On a phone this either fails silently or leaks data. It also breaks Constitution rule 25 (no network in `features/`) and the Register's privacy stance.
- **Smallest fix:** delete both `#region agent log` blocks and `_agentDebugLog` (no behavior depends on them). Add a guard test that greps `lib/` for `HttpClient`, `debug-296a8e`, `AGENT_DEBUG`, `127.0.0.1`.
- **Batch:** VX-B1. **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** — both blocks and `dart:io`/`dart:convert` imports removed (not gated behind `kDebugMode`); guard test `test/app/vx_b1_no_debug_residue_test.dart`.

### FVX-G-02 — Honesty copy is written in engineering jargon, including on child screens
- **Scope / nature:** GLOBAL · HONESTY · UX · RTL — **HIGH** — CONFIRMED (text), PENDING-RENDER (look)
- **Affected:** ~50 Arabic ARB values + the `CapabilityHonestyBadge` labels; surfaces across SEC, COM, EDU, AIC, ADM. Child-facing examples: SCR-CHD-016, 017, 020, 023, 024, 030, 032, flashcards.
- **Evidence (app/lib/core/i18n/app_ar.arb):**
  - `:1323` "…غير متاح حتى Native…", `:3508` "فرض VPN/DNS غير متاح حتى Native", `:3655/3659` "قفل النظام غير متاح حتى Native"
  - `:4324`, `:10170` "…يتطلّب Backend/FCM…"
  - `:6423`, `:6475`, `:6479`, `:7076`, `:7140` "…التسليم متعدد الأجهزة مغلق Remote."
  - `:9738` **child praise** "أتقنت جمع الكسور! النتيجة محلية — إشعار الوالد مغلق Remote." (also hard-codes "fractions" as the subject)
  - `:9826` **child tutor** "…بوابة المعلّم مغلق Remote."
  - `:10629`, `:10729` "التقاط/MediaProjection Native مغلق"
  - `:11344`, `:11422` "…REMOTE CLOSED"
  - `:12961` CTA label "تحقق من جاهزية Native"
  - `:14660–14676` badge labels "IMPLEMENTED", "MOCK-REMOTE", "DEGRADED", "UNSUPPORTED", "NOT IMPLEMENTED" (English, upper-case) — rendered by `core/design/components/capability_honesty_badge.dart` on SCR-FAT-014, 017, 034, 035, 036, 085 and screen-camera panels.
  - Grammar: "بوابة المستشار مغلق" (feminine noun, masculine adjective) repeats in ≥8 strings.
- **Why it matters:** CE-B0 made the product honest, but the honesty is phrased for engineers. A mother reading "MediaProjection Native مغلق" or a 9-year-old reading "إشعار الوالد مغلق Remote" after a quiz learns nothing and loses trust. Register G-3: "UI must be human language, never programmer IDs".
- **Smallest fix:** ARB-only rewrite against a short approved **honesty glossary** (e.g., "يعمل على هذا الجهاز فقط" / "سيصل إلى الأجهزة الأخرى في تحديث قادم" / "يتطلّب تفعيلًا على جهاز الابن لاحقًا"), with a child-tone variant; localize the 5 badge labels. No widget or policy change.
- **Owner decision:** ANSWERED (D2, 2026-09-25) — glossary approved (v1 in execution plan §8.1); child screens show one gentle line. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B3 Owner gate; phone check PENDING-DEVICE).**
- **Batch:** VX-B3.

### FVX-G-03 — Child identity is fragmented across systems (different fallback child IDs)
- **Scope / nature:** GLOBAL · CONTROL · DATA — **CRITICAL** (breaks father↔child loops) — CONFIRMED
- **Evidence:**
  - `'demo-child'`: `features/n03_screen_time/stage1_child_scope.dart:7` (`kStage1CanonicalChildId`); used by `web_filter_screen.dart:88`, `instant_lock_screen.dart:134`, `privacy_data_screen.dart:91`, `what_is_collected_screen.dart:88`, `time_expiry_screen.dart:44`, `smart_alerts_screen.dart:134`, `new_app_approval_screen.dart:165`, `audit_log_screen.dart:130`.
  - `'child_a'`: `n14_studio/quran_progress_repository.dart:44`, `n17_child_learn/child_quran_ward_repository.dart:26`, `child_learn_home_repository.dart:20`, `child_quiz_screen.dart:89`.
  - `'child_demo'`: `core/policy/smart_mode_prefs.dart:107` (`SmartModePrefs.defaultChildId`), consumed by `n02_day/child_day_board_screen.dart:66`.
  - `'child_1'`: `core/policy/desired_monitoring_prefs.dart:15`.
  - A correct resolver already exists (`activeScopedChildId` / `activeChildScope`) but is not used everywhere.
- **Why it matters:** the father sets a limit, lock, or Quran plan for "his child", and the child's device reads another ID — the setting appears saved but never reaches the child's side. This is exactly the "loop closure" the Constitution (rule 24) requires.
- **Smallest fix:** route every feature fallback through the one existing resolver (identity → active child → roster first child). Leave `core/policy` defaults untouched (rule 21) but stop features from relying on them (pass an explicit `ChildId`). Add a cross-system test: one roster child ⇒ FAT-032/036/037/072 writes are read by CHD-004/021/025.
- **Owner decision:** OD-06 only for the two `core/policy` default constants.
- **Batch:** VX-B2. **Status: FIXED-PENDING-GATE (VX-B2 code done 2026-09-25)** — one resolver `core/identity/active_child_resolver.dart` over `IdentityRuntime` (explicit route/profile child → active child; no literal fallback). `kStage1CanonicalChildId` removed; web filter, instant lock, privacy, what-is-collected, time expiry, smart alerts, new-app approval, tamper alerts, child apps, child screen time, time request, wallet, Quran progress + child Quran ward now resolve through it. `core/policy` defaults untouched (D6); CHD-004 / FAT-085 / FAT-067 / CHD-010 / FAT-068 receive the route child explicitly so writer and reader agree. **Not changed previously; OD-14 CLOSED 2026-09-26:** education loops now bind to the active-family roster (never planted `child_a`). See `.verify/OD-14-EDU-ROSTER.json`.

### FVX-G-04 — Router drops `childId` for per-child (PERCHILD) screens
- **Scope / nature:** GLOBAL · NAVIGATION · CONTROL — **HIGH** — CONFIRMED
- **Evidence:** `app/lib/app/router.dart` builds these without reading `state.uri.queryParameters['childId']`: SCR-FAT-033, 036 `WebFilterScreen()`, 037 `InstantLockScreen()`, 051, 065, 066, 067 `SmartSupervisionScreen()`, 069, 072, 085, CHD-004, CHD-021 `TimeExpiryScreen()`. Child profile tools **do** pass it: `features/n02_day/child_profile_screen.dart:345–395`. Screens that honor it: FAT-013/014/015/016/017/018/032/034/035/038, CHD-006, CHD-020.
- **Why it matters:** from "Ahmad's profile → Web filter", the father edits the default child, not Ahmad. With two children this silently configures the wrong child. Register G-5: per-child tools live inside the child profile.
- **Smallest fix:** in the generator template (`tool/gen_routes.dart`) pass `childId` for the PERCHILD set; screens already accept a `childId` constructor param or can fall back to the resolver (FVX-G-03). Regenerate router. Test: `router_routes_test.dart` asserts each PERCHILD route forwards `childId`.
- **Batch:** VX-B2. **Status: FIXED-PENDING-GATE (VX-B2 code done 2026-09-25)** — `app/route_child_context.dart` (`routeChildId` / `routeScopedChildId`) used by FAT-032 (family-scoped key), 036, 037, 065, 067, 068, 072, 085, CHD-004, CHD-005, CHD-010, CHD-021 in both `tool/gen_routes.dart` and `router.dart`. The child profile also makes the chosen child the family context's selected child, so tools without a route param (e.g. Quran) follow it. FAT-033/051/066/069 routes unchanged (no per-child constructor param today; they read the family context's selected child). Guard: `test/app/vx_b2_perchild_route_context_test.dart`; loop: `test/features/vx_b2_father_child_loop_test.dart`.

### FVX-G-05 — Family scope pinned to `FamilyId('fam_stage1')`
- **Scope / nature:** GLOBAL · DATA · CONTROL — **HIGH** — CONFIRMED
- **Evidence:** core runtimes: `core/app_control/app_control_runtime.dart:18`, `core/sos_final/sos_final_runtime.dart:19`, `offline_ai_safety_runtime.dart:14`, `screen_camera_runtime.dart:14`, `modes_runtime.dart:15`, `web_filter_runtime.dart:16`; core/policy defaults `sos_break_glass.dart:173`, `web_unlock_service.dart:112`; features `safe_zones_screen.dart:149`, `create_safe_zone_screen.dart:195/318`, `location_history_screen.dart:130`, `location_map_screen.dart:204`, `n02_day/day_board_projection.dart:219` (singleton built without a family function).
- **Why it matters:** after creating/switching family (SCR-FAT-001 / sys3 family-select), the Kids list (FAT-012) follows the new family but the Today board (FAT-010), safe zones and several runtimes stay on the demo family — two different families on two tabs.
- **Smallest fix:** inject the existing `CurrentIdentity` family function into the day-board projection singleton and the feature call sites; runtimes read family from the identity scope at call time. `core/policy` defaults → OD-06.
- **Batch:** VX-B2. **Status: FIXED-PENDING-GATE (VX-B2 code done 2026-09-25)** — Today projection singleton reads the active family; the Today board and safe zones reload on a family switch; safe zones, create zone, location history and location map use the active family instead of `fam_stage1`. **Not changed:** `core/*` runtimes and `core/policy` defaults (D6 / rule 21). Test: `test/features/n02_day/vx_b2_day_board_family_scope_test.dart`.

### FVX-G-06 — SOS actor attribution is inconsistent
- **Scope / nature:** GLOBAL · CONTROL · DATA (safety) — **CRITICAL** — CONFIRMED
- **Evidence:** `fire(childId: …)` is called with `'family'`, `'self'` (child screens), `'demo-child'` (`n07_privacy/audit_log_screen.dart:130`), `'child_local'`, `'parent_local'`, `_resolvedCallId` (`n02_day/active_call_screen.dart:181` — a call ID used as a child ID), `_resolvedPeer` (`conversation_screen.dart:178`).
- **Why it matters:** when an SOS is raised, SCR-FAT-018 and the audit log cannot reliably say **who** needs help. In an emergency, "who" is the first question.
- **Smallest fix:** one shared `SosActorResolver` in features (child device → active child ID from identity; parent device → acting member ID) used by every SOS entry; no change to SOS ladder or break-glass policy. Test: every SOS entry point records the same actor for the same session.
- **Owner decision:** ANSWERED (D7, 2026-09-25) — record the acting parent plus the child being viewed; parent only when no child is in view. Actionable in VX-B2.
- **Batch:** VX-B2. **Status: FIXED-PENDING-GATE (VX-B2 code done 2026-09-25), partial by rule 21** — `core/identity/sos_sender.dart` resolves every SOS entry (≈80 call sites): child screens send the real child id; parent screens send the viewed child, else the acting parent's membership id; shared screens follow their role. No `'self'`, `'family'`, `'child_local'`, `'parent_local'`, `'demo-child'` or call id remain. Child hold also records the child's linked device. **Gap → OD-13 CLOSED 2026-09-26:** `SosFireService.fire` now carries `actorId` + subject `childId`; parent SOS opens durable `sos_final` (`parentAlert`, schema v11). See `.verify/OD-13-SOS-PARENT-CHILD.json`.

### FVX-G-07 — Role-guard "blocked" landing is the developer design gallery
- **Scope / nature:** GLOBAL · NAVIGATION · HONESTY — **HIGH** — CONFIRMED
- **Evidence:** `app/lib/app/role_guard.dart:43` `roleGuardSafeLocation = '/gallery'` (used at :73, :83); `/gallery` = `app/gallery_screen.dart` (token swatches, hex codes, sample toasts); `router.dart:311`.
- **Why it matters:** a child who taps into an owner-only screen (billing, privacy, audit) lands on a page of colour hex codes — confusing and unprofessional.
- **Smallest fix:** blocked users go to their role home (parent → SCR-FAT-010, child → SCR-CHD-004) with a toast "هذه الصفحة لوليّ الأمر" (ARB). Keep `/gallery` for dev only (or behind `kDebugMode`).
- **Owner decision:** ANSWERED (D4) — own role home + polite message; gallery never the landing.
- **Batch:** VX-B1. **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** — child → `/scr-chd-004`, father/mother → `/scr-fat-010`, with `?guard=blocked` so the home shows one toast (`roleGuardBlockedChild` / `roleGuardBlockedParent`). `/gallery` route itself is kept (dev surface, no longer a landing).

### FVX-G-08 — Shell hub labels are hard-coded Arabic; hub opens context-requiring screens without context
- **Scope / nature:** GLOBAL · NAVIGATION · UX · RTL — **MEDIUM** — CONFIRMED
- **Evidence:** `app/lib/app/shell_config.dart` (generated) `HubEntry.name` = Arabic registry names (e.g. "طلب فتح وضع الوالد (المفتاح الثاني)", "ميزات قادمة ✨"), rendered at `family_shell.dart:267`; `shellTabLabel` falls back to the raw ARB key (`family_shell.dart:372`). Hub lists detail/form screens with no context: SCR-FAT-026 (needs device), FAT-042 camera, FAT-053 add event, FAT-055 create task, and (Kids hub) FAT-014, 016, 017, 085 which are per-child but not in `_perChildScreenIds` (`family_shell.dart:394–409`).
- **Why it matters:** labels are registry names (long, technical in places) and would stay Arabic in English; opening "Device detail" from a hub with no device shows an empty/not-found state — a dead end.
- **Smallest fix:** generator emits ARB keys for hub labels (new `hub*` keys, AR = current text, EN translated); move FAT-014/016/017/085 into the per-child set or pass the active child; drop FAT-026 from the hub (reachable from FAT-025 list) or pass the first device; keep FAT-053/055 (valid "new" forms).
- **Batch:** VX-B4. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B4 Owner gate; phone check PENDING-DEVICE)** — hub tab labels via ARB (VX-B3); FAT-014/016/017/085 in per-child set; FAT-026 dropped from hub (reachable from FAT-025).
- **Scope / nature:** GLOBAL · HONESTY · STATE — **MEDIUM** — CONFIRMED
- **Evidence:** `errorNetworkMessage` ("We couldn't reach the server…") used on local save failure: `create_safe_zone_screen.dart:338, 373` (+1), `notification_prefs_screen.dart` (1), `web_filter_screen.dart` (2).
- **Why it matters:** there is no server. Blaming the network sends a parent to check Wi-Fi for a problem that is on the device.
- **Smallest fix:** new ARB key `errorLocalSaveMessage` ("تعذّر الحفظ على هذا الجهاز — حاول مرة أخرى") in these 6 call sites.
- **Batch:** VX-B1. **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** — all 6 call sites switched. `create_family_screen` still uses the network template (not in this finding's scope; reviewed again in VX-B3 wording pass).

### FVX-G-10 — Two feedback systems (SnackBar vs AppToast)
- **Scope / nature:** GLOBAL · VISUAL · UX — **MEDIUM** — CONFIRMED
- **Evidence:** raw `ScaffoldMessenger…showSnackBar` in ~14 files (create_safe_zone ×6, active_call ×5, sos_alert ×4, conversation, child_chats, child_conversation, request_inbox, web_filter, child_active_call, child_sos_in_progress, alert_detail, conversations_list, call_history); `AppToast.show` in ~85 files.
- **Why it matters:** the same kind of confirmation looks and sits differently from screen to screen; SnackBars can be hidden by the shell's tab bar/FAB area.
- **Smallest fix:** replace with `AppToast.show` (component already exists). No copy change.
- **Batch:** VX-B4. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B4 Owner gate; phone check PENDING-DEVICE)** — SnackBar→AppToast on listed surfaces; tests dismiss toast timers.

### FVX-G-11 — Drill-in chevrons likely point the wrong way in Arabic
- **Scope / nature:** GLOBAL · RTL · VISUAL — **MEDIUM** — PENDING-RENDER (high likelihood)
- **Evidence:** `Icons.chevron_left` used as a row "go to detail" affordance in ~25 places: `device_health_list_screen.dart:330`, `child_profile_screen.dart:1323`, `trial_mode_screen.dart:195/206`, `studio_board_screen.dart:559`, `sys3` screens :370/:721, `family_advisor_hub_screen.dart:492`, `child_apps_screen.dart:805`, `time_expiry_screen.dart:346`, `alerts_hub_screen.dart:450`, `child_wallet_screen.dart:445–461`, `settings_hub_screen.dart:481`, `link_qr_screen.dart:373`, `language_help_screen.dart:545`, `child_learn_home_screen.dart:635`, `materials_lessons_screen.dart:462`, `add_from_source_screen.dart:527/598`, `setup_wizard_screen.dart:205/217`, `children_list_screen.dart:625`. Flutter's Material `chevron_left` is direction-matched, so in RTL it renders pointing **right** (the "back" direction), while the prototype shows "‹" (pointing left = forward in Arabic).
- **Why it matters:** every list row would visually say "go back" instead of "open".
- **Smallest fix:** confirm on one rendered screen; if confirmed, switch to `Icons.chevron_right` (which mirrors to point left in RTL). Back buttons using `Icons.arrow_back` are correct — NO ACTION.
- **Batch:** VX-B4 (confirm in VX-B7 render pass first screen). **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B4 Owner gate; phone/render confirm PENDING-DEVICE / VX-B7)** — drill-in rows use `Icons.chevron_right` (mirrors correctly in RTL).

### FVX-G-12 — Physical (left/right) positioning and fixed-pixel illustrations
- **Scope / nature:** GLOBAL · RTL · DEVICE · VISUAL — **LOW** — PENDING-RENDER / PENDING-DEVICE
- **Evidence:** fixed-pixel map art with `Positioned(left: 322 …)` etc. in `location_map_screen.dart:490–580`, `create_safe_zone_screen.dart:800–890`, `sos_alert_screen.dart:857–897`, `link_success_screen.dart:189` (`right: 140`); `Alignment.centerLeft/Right` in ~20 files (e.g. `login_screen.dart:265`); `EdgeInsets.only(right: 3)` `child_family_challenges_screen.dart:258`. Shell FABs `Positioned(left: 16)` `family_shell.dart:172–197`.
- **Why it matters:** on a 360 dp phone the fixed-pixel art can overflow or clip; decorative "map pins" at fixed spots may look like live GPS. Alignment literals are fine in AR-only but flip wrong if English is enabled.
- **Smallest fix:** wrap map art in `LayoutBuilder` + fractional positions; replace `Alignment.centerLeft` with `AlignmentDirectional.centerStart` where the meaning is "start". FABs: **reopened under D1** (English LTR enabled) — `Positioned(left: 16)` → `PositionedDirectional(end: 16)` so Arabic keeps the prototype position and English mirrors it.
- **Batch:** VX-B4 (+ device check in FINAL DEVICE PASS). **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B4 Owner gate; phone check PENDING-DEVICE)** — map art `LayoutBuilder` + fractions; FABs `Positioned.directional(end: …)`.

### FVX-G-13 — Colour literals outside tokens
- **Scope / nature:** GLOBAL · VISUAL — **LOW** — CONFIRMED
- **Evidence:** `child_apps_screen.dart:715` (`0xFF0277BD`), `child_quiz_screen.dart:302`, `outer_circle_screen.dart:532`, `child_friends_screen.dart:318`, `child_quran_ward_screen.dart:238`, `quran_progress_screen.dart:378`, `child_flashcards_screen.dart:328`, `child_qr_scan_screen.dart:432`, `studio_camera_capture_screen.dart:320`, `mother_ai_feed_screen.dart:263/266`, `child_sos_button_screen.dart:306`; ~70 `Colors.white` (should be `colors.surface`).
- **Why it matters:** rule 14; small visual drift and future dark-mode breakage.
- **Smallest fix:** map each literal to the nearest existing token (tokens.dart is not changed). `device_user_switch_screen.dart:125` parses a stored colour — NO ACTION.
- **Batch:** VX-B4. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B4 Owner gate; phone check PENDING-DEVICE)** — listed feature colour literals mapped to tokens (no new token invent).

### FVX-G-14 — Design-system gaps: low-contrast secondary text, no spacing/type scale, no loading component
- **Scope / nature:** GLOBAL · VISUAL · STATE · OWNER_DECISION — **MEDIUM** — CONFIRMED (math), PENDING-RENDER
- **Evidence:** `core/design/tokens.dart` `ink2 #8A8FA3` on `bg #F5F6FA` ≈ 2.97:1 and on white ≈ 3.2:1 — below WCAG AA 4.5:1 for the 12 px `bodySmall` it is used for; only 4 text styles, no spacing scale; `core/design/components/` has `app_empty_state`, `app_error_state` but **no loading-state component** (screens use ad-hoc `CircularProgressIndicator`).
- **Why it matters:** hints, timestamps and honesty lines (the text parents most need to read) are the faintest text in the app — worse outdoors and for older grandparents.
- **Smallest fix:** OD-03 (tokens are frozen by rule 21) — options: darken `ink2` (e.g. ≈ #6B7082 ≈ 4.6:1), or keep `ink2` for ≥14 px only and use `ink` for 12 px. Add `AppLoadingState` component (additive, core/design/components) — batch VX-B4.
- **Owner decision:** ANSWERED (D3) — darken `ink2` to WCAG AA; explicit rule-21 token authorization.
- **Batch:** VX-B4. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B4 Owner gate; phone check PENDING-DEVICE)** — `ink2` → `#6B7082`; `AppLoadingState` added. Spacing/type-scale expansion not in scope (KEEP).

### FVX-G-15 — Arabic numerals are inconsistent (Eastern vs Western digits on the same screen)
- **Scope / nature:** GLOBAL · RTL · OWNER_DECISION — **MEDIUM** — CONFIRMED (code), PENDING-RENDER
- **Evidence:** digit conversion exists only in 5 screens (`add_child_screen.dart`, `link_qr_screen.dart`, `children_list_screen.dart`, `child_profile_screen.dart`, `create_safe_zone_screen.dart`; helper `toEasternDigits` is defined locally in `add_child_screen.dart`). Demo seeds use Eastern digits ("٨٤٪", "١ س ٤٦ د" — `children_list_local_repository.dart:15–75`); live values elsewhere (minutes, counts, `{days}` placeholders) render Western digits.
- **Why it matters:** "٨٤٪" next to "30 د" on one card looks broken.
- **Smallest fix:** one shared numeral formatter in `core/i18n` used by all numeric placeholders, following D5 (ANSWERED 2026-09-25: **Western digits** on Arabic screens) — remove `toEasternDigits` use and Eastern digits in demo seeds.
- **Batch:** VX-B3. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B3 Owner gate; phone check PENDING-DEVICE).**

### FVX-G-16 — Mock data lives inside `features/`, not `mock/`
- **Scope / nature:** GLOBAL · DATA · OWNER_DECISION — **LOW** (no visible effect) — CONFIRMED
- **Evidence:** 19 `*_mock.dart` files under `features/` (e.g. `n02_day/day_child_mock.dart` imported by production repos, `alerts_hub_mock.dart`, `conversation_mock.dart`, `n03_screen_time/child_apps_mock.dart`, `n12_devices/family_members_mock.dart`) + `core/policy/chat_mock_store.dart`, `core/fs_foundation/mock_remote_adapter.dart`; only `app/lib/mock/register_mock_family.dart` is in `mock/`.
- **Why it matters:** rule 23 says deleting `mock/` must leave the app working; today it would not prove anything. No family-visible effect.
- **Smallest fix:** OD-08 — relocate (structural, zero UX change) in a separate hygiene batch, or defer to Backend integration.

### FVX-G-17 — Navigation primitive inconsistency (`go` vs `push`)
- **Scope / nature:** GLOBAL · NAVIGATION — **MEDIUM** — CONFIRMED
- **Evidence:** dashboard uses `context.go` for drill-downs (`day_board_screen.dart:157, 165`, quick actions :365–368), SOS escalations use `go` in `child_apps_screen.dart:259`, `new_app_approval_screen.dart:219`, `mother_permission_level_screen.dart:156`; most other screens use `push`.
- **Why it matters:** after "Today → child card → profile", system Back leaves the app or jumps tabs instead of returning to Today.
- **Smallest fix:** rule: tab switches use `go`; drill-down and SOS use `push`. Apply to the listed call sites.
- **Batch:** VX-B5 (dashboard) + VX-B4 (others). **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B5 Owner gate; phone check PENDING-DEVICE)** — dashboard quick actions and drill-downs use `push` + `childId`; VX-B4 already closed non-dashboard SOS/`push`.

---

## 3. SYSTEM findings

### FVX-S-01 — Family chat is empty and cannot be started on a fresh install (COM:أ)
- **Scope / nature:** SYSTEM · CONTROL · STATE · OWNER_DECISION — **HIGH** — CONFIRMED
- **Affected:** SCR-FAT-021, FAT-022, CHD-007, CHD-008 (JRN-FAT-11, JRN-MOT-04, JRN-CHD-04).
- **Evidence:** `stage1ConversationsListRepository`, `stage1ConversationRepository` (`features/n02_day/conversation_repository.dart:193`) and `stage1ChildChatsRepository` default to empty in-memory stores and are never bound in `main.dart`; `send` throws "conversation not found" when no thread exists; FAT-021 shows the empty text "When a family chat starts it appears here…" with no way to start one. FRONTEND_COMPLETION_MATRIX lists FAT-021 as "YES (Local chat list)".
- **Why it matters:** Rule 9 says family chat is never disabled; Q-CEX-001 locked durable chat. Today a family opens Chat and finds nothing to tap.
- **Smallest fix (D9 ANSWERED 2026-09-25):** chat local persistence adapter on the existing `FsSessionKernel` → `LocalDatabase`; on first run seed family thread(s) from the real roster/identity; UI reads only from that database; **no seeded messages**; honest "Saved on this device only" line; multi-device stays REMOTE_CLOSED. Full interpretation and conflict flags: execution plan §8.2. Batch VX-B6.
- **Batch:** VX-B6. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B6 Owner gate; phone check PENDING-DEVICE)** — Local family thread seeded (zero messages); FAT-021/022 + CHD-007/008 bound via `FamilyChatLocalPersistence`.

### FVX-S-02 — Alerts hub is never fed (AIC:أ)
- **Scope / nature:** SYSTEM · STATE · CONTROL — **HIGH** — CONFIRMED
- **Affected:** SCR-FAT-019, FAT-020 (JRN-FAT-10).
- **Evidence:** `stage1AlertsHubRepository` (used at `alerts_hub_screen.dart:104`) and `stage1AlertDetailRepository` are empty in-memory defaults with no producer; local producers already exist (`core/events/local_event_journal.dart`, `stage1AntiTamperAlertBus`, SOS fire, time requests).
- **Why it matters:** the "Alerts" place a parent checks is always empty even after a tamper alert or SOS on the same device — it trains parents to ignore it.
- **Smallest fix:** a read-only projection from the local event journal (tamper, SOS, time-request, app-install events) into the existing `AlertsHubRepository` interface; empty state stays honest when nothing happened.
- **Batch:** VX-B5. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B5 Owner gate; phone check PENDING-DEVICE)** — `ProjectingAlertsHubRepository` / local projection binds SOS, tamper, time-request, app-install, friend-approval into FAT-019.

### FVX-S-03 — Today dashboard does not show the decisions waiting for a parent (ADM:ز)
- **Scope / nature:** SYSTEM · UX · NAVIGATION · CONTROL — **HIGH** — CONFIRMED
- **Affected:** SCR-FAT-010 (JRN-FAT-05, JRN-MOT-02).
- **Evidence:** `features/n02_day/day_board_projection.dart:222–269` builds the pending card only from learning results and athkar; **time requests (FAT-033), new-app approvals (FAT-035) and friend requests (FAT-071) never surface**. Athkar item uses `inboxPath: '/scr-chd-027'` (`:154`, `:256`) — sends the **father to a child screen**. Quick actions (`day_board_screen.dart:365–368`: Quran FAT-072, Tasks FAT-054, Lock FAT-037, Map FAT-014) open without the active child ID and via `go`. `lastSyncLabel: null` (`:266`). Family scope from FVX-G-05.
- **Why it matters:** the dashboard's job is Orient → Prioritize → Act. A child's "10 more minutes please" is the most time-sensitive thing a parent does, and it is not on the home screen.
- **Smallest fix:** add pending counts from the existing time-request, app-approval and friend-approval repositories; athkar item → parent-side SCR-FAT-072 (or remove); quick actions pass `childId` and use `push`; `lastSyncLabel` → "محفوظ على هذا الجهاز" style honest line (per OD-02 glossary) instead of null.
- **Batch:** VX-B5. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B5 Owner gate; phone check PENDING-DEVICE)** — pending from time/app/friend ahead of learning; athkar → FAT-072; quick actions `push`+`childId`; `dayBoardLocalSaveLine` honesty.

### FVX-S-04 — Adding a child loses the name the parent typed (ADM:ب)
- **Scope / nature:** SYSTEM · CONTROL · HONESTY · UX — **HIGH** — CONFIRMED
- **Affected:** SCR-FAT-003 → FAT-012 → FAT-013 (JRN-FAT-02, JRN-FAT-06).
- **Evidence:** `features/n01_linking/add_child_screen.dart` `_continue` calls `repo.createChild(familyId, childId: ChildId(_alias))` only — name, age, character and colour are discarded. `features/n02_day/children_list_screen.dart:150–180` `_mergeChildren` shows the new child as `displayName: child.childId.value` (e.g. "child_3fa2"), emoji 🧒, age 0, and empty meta rendered as "📍  · " / "🔋 · ⏱" (`:765`, `:775`). Blocked-add toast reuses key `childScreenTimeReadOnly`.
- **Why it matters:** the first thing a parent does is add their child by name; the app then calls the child "child_3fa2". Register G-3 (no programmer IDs).
- **Smallest fix:** persist display name/age/colour through the existing identity roster (local) and read them in FAT-012; hide location/battery rows when absent (show "لم يُربط الجهاز بعد"); dedicated ARB key for the block toast.
- **Batch:** VX-B6. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B6 Owner gate; phone check PENDING-DEVICE)** — `upsertChild` on Local roster from Add Child; empty meta → `childrenListDeviceNotLinked`.

### FVX-S-05 — Location & safe zones residue (SEC:د)
- **Scope / nature:** SYSTEM · UX · HONESTY · VISUAL — **MEDIUM** — CONFIRMED
- **Affected:** SCR-FAT-014, 015, 016, 017.
- **Evidence:** `create_safe_zone_screen.dart:215–223` name field **pre-filled with the hint text as a real value**; `:320, :353` emoji '🥋' hard-coded for every new zone; `:338, :373` server-error copy (FVX-G-09); SnackBars ×6 (FVX-G-10); fixed-pixel map (FVX-G-12); `safe_zones_screen.dart:149` pinned family (FVX-G-05).
- **Why it matters:** a parent can save a zone literally named after the placeholder, and every zone shows a karate icon.
- **Smallest fix:** empty controller + hint; emoji chosen by zone type or a neutral 📍; other items via the global fixes.
- **Batch:** VX-B6. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B6 Owner gate; phone check PENDING-DEVICE)** — empty name controller + required toast; save emoji 📍.

### FVX-S-06 — Device detail opened from the child profile uses the wrong ID (ADM:ج)
- **Scope / nature:** SYSTEM · NAVIGATION · STATE — **MEDIUM** — CONFIRMED (code), PENDING-RENDER (visible state)
- **Affected:** SCR-FAT-013 → SCR-FAT-026.
- **Evidence:** `child_profile_screen.dart:418` pushes `deviceId=<childId>`; `stage1DeviceHealthSeam = FakeDeviceHealthSeam.demo()` keys devices as `dev_a…` (`features/n12_devices/device_health_seam.dart`).
- **Why it matters:** "Check device" from a child's profile likely lands on "device not found".
- **Smallest fix:** look up the device by child ID through the seam (add `deviceForChild`), or pass the linked device ID.
- **Batch:** VX-B2. **Status: FIXED-PENDING-GATE (VX-B2 code done 2026-09-25)** — both the Device health tool and the device link now pass the child's linked device (identity devices, then managed devices); no param when the child has none (FAT-026 then shows its list).

### FVX-S-07 — Language setting does nothing (ADM:ح)
- **Scope / nature:** SYSTEM · CONTROL · HONESTY · OWNER_DECISION — **MEDIUM** — CONFIRMED
- **Affected:** SCR-FAT-061 (JRN-FAT-30).
- **Evidence:** `language_help_screen.dart:158–165` English option only shows toast `languageHelpLocaleToast` ("English interface — coming in a later update"); `main.dart` hard-codes `locale: const Locale('ar')`; the full English ARB exists. The support tile toast ("Arabic support chat — reply during business hours") implies a live remote channel.
- **Why it matters:** rule 24 (a switch that changes nothing is a violation) vs. Register G-3 (full Arabic RTL). The honest options differ.
- **Smallest fix (D1 ANSWERED 2026-09-25):** real locale switch persisted in prefs-misc and applied app-wide (`MaterialApp.locale` instead of the fixed Arabic locale). Support toast → honest copy ("سيتوفر الدعم المباشر لاحقًا — راسلنا عبر…" per OD-02).
- **Batch:** VX-B3. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B3 Owner gate; phone check PENDING-DEVICE)** — `LocaleController` + Language Help AR/EN apply `MaterialApp.locale`; toast is "Interface language updated".

### FVX-S-08 — Demo telemetry on roster and device list is bannered but Arabic-only and numerically mixed (ADM:ب / ADM:ج)
- **Scope / nature:** SYSTEM · HONESTY · RTL — **LOW** — CONFIRMED
- **Evidence:** `children_list_local_repository.dart:15–75` seeds "ابن ١" (age 14, 'المدرسة', 'قبل ٣ د', '٨٤٪', '١ س ٤٦ د'), "ابن ٢" (32 % at risk); device seam 'Redmi Note 13', heartbeat '٩ د'. Banners exist (`childrenListLocalDemoBanner`, `day_board_screen.dart:305`) and are reused on the device list.
- **Why it matters:** acceptable for LOCAL_DEMO (honest), but the seed values are display strings in one language rather than data — a sample that will look wrong in EN and mixes digit systems.
- **Smallest fix:** keep the banners (NO ACTION on honesty); store numbers as numbers and format via FVX-G-15 formatter. **Active** — D1 enabled English, so demo display strings need EN equivalents.
- **Batch:** VX-B3 (conditional).

### FVX-S-09 — Settings "other" shortcuts expose a mother-side join screen and an event-driven SOS screen (ADM:ح / SEC:هـ)
- **Scope / nature:** SYSTEM · NAVIGATION · UX — **MEDIUM** — CONFIRMED
- **Evidence:** `app/lib/app/family_shell.dart:296–310` Settings hub shortcuts: SCR-SHR-008 (device switch — fine), **SCR-FAT-009 "accept mother invite"** (a joining-mother screen, shown to the father), **SCR-FAT-018 "SOS alert"** opened by navigation without an alert (Register G-6: event-driven screens are invoked by events).
- **Why it matters:** father taps "SOS alert" and sees an emergency screen with no emergency; father taps "Accept invite" for an invite meant for someone else.
- **Smallest fix:** remove FAT-009 and FAT-018 shortcuts (FAT-009 stays reachable from Login/invite link; FAT-018 from SOS events and "last SOS" in the audit log). Keep SHR-008.
- **Owner decision:** none if the Register G-6 reading is accepted; otherwise OD-10.
- **Batch:** VX-B5. **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B5 Owner gate; phone check PENDING-DEVICE)** — Settings Other keeps SHR-008 only; FAT-009/018 shortcuts removed (OD-10).

---

## 4. SCREEN findings

### FVX-C-01 — SCR-SHR-003 Login: fingerprint button claims success
- **Nature:** HONESTY · NATIVE_CLOSED — **HIGH** — CONFIRMED
- **Evidence:** `login_screen.dart` biometric button shows `loginBiometricToast` = "Signed in with fingerprint" without signing in.
- **Fix:** honest toast "الدخول بالبصمة يتوفر عند تفعيل الجهاز" (glossary OD-02) or hide the button until native. **Batch VX-B1.** **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** — button kept (KEEP), toast now `loginBiometricUnavailable` (AR/EN, glossary "device permission — coming later"); never signs in or navigates.

### FVX-C-02 — SCR-SHR-003 Login: credentials silently ignored; wrong ARB keys; small link target
- **Nature:** UX · HONESTY · VISUAL — **MEDIUM** — CONFIRMED
- **Evidence:** login ignores email/password (no validation, no "local mode" note); session tag reuses unrelated keys `requestInboxReject` / `linkQrExpired` / `dayBoardActiveTag`; forgot-password link `Alignment.centerLeft` (`:265`) with ~32 dp tap height; invite inline link inside a `WidgetSpan` is below 48 dp.
- **Fix:** minimal required-field validation + one honest line ("الحساب محفوظ على هذا الجهاز"), dedicated ARB keys, 48 dp link targets, `AlignmentDirectional`. **Batch VX-B6.** **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B6 Owner gate; phone check PENDING-DEVICE).**

### FVX-C-03 — SCR-FAT-041 Add from source: PDF subject sheet is fake
- **Nature:** CONTROL · HONESTY — **MEDIUM** — CONFIRMED
- **Evidence:** `n14_studio/add_from_source_screen.dart:180–188` "Math" option hard-coded `selected: true` with `onTap: () {}`; "Science" shows a "selected" toast without changing selection.
- **Fix:** bind to a local selected-subject state (screen state is fine here — it feeds the next step) or remove the subject step. **Batch VX-B1.** **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** — both sources selectable, choice kept while the screen is open, fake "selected (demo)" toast removed, tiles gained Semantics (selected flag) + 48 dp minimum. Passing the choice into FAT-043 is not done (FAT-043 takes no input today; would be new behavior).

### FVX-C-04 — SCR-FAT-079 My advisor: saved rules display "Rule" and a technical ID
- **Nature:** UX · RTL · HONESTY — **MEDIUM** — CONFIRMED
- **Evidence:** `n07_advisor/rule_editor.dart:65` saves `title: 'Rule'`, `body: _selected.id`; `my_advisor_screen.dart:352, 361` renders `rule.title` / `rule.body`.
- **Fix:** save/display the localized consequent label (ARB) instead of literal + ID. **Batch VX-B1.** **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** — display-side: editor-authored rules (no source suggestion) show `myAdvisorOwnRuleTitle` + localized consequent labels, so they follow the AR/EN switch; approved-suggestion rules unchanged. Stored data unchanged (`core/policy` untouched).

### FVX-C-05 — SCR-FAT-077 Road safety is routed although classified Out of Scope
- **Nature:** OWNER_DECISION · NAVIGATION — **LOW** — CONFIRMED
- **Evidence:** `router.dart` builds `RoadSafetyScreen` for `/scr-fat-077`; not on any hub (`family_shell.dart:386`) and not linked from any feature — reachable only by deep link. FRONTEND_COMPLETION_MATRIX:124 says "Tombstone or out-of-scope owner"; CONTROL_EXPERIENCE_AUDIT says "OOS screens correctly unrouted".
- **Fix:** OD-11 — tombstone-redirect like FAT-039, or keep (harmless, unlinked). **Batch VX-B1 if tombstone chosen.** **Status: CLOSED — FIXED, PASSED 2026-09-25 (VX-B1 Owner gate; phone check PENDING-DEVICE)** (D11) — `legacyRedirectPaths` sends `/scr-fat-077` to `/scr-fat-075` Coming soon (which lists Road safety). Registry row and route entry kept so the catalog count is unchanged.

### FVX-C-06 — SCR-CHD-016 My result: praise hard-codes the subject
- **Nature:** DATA · UX — **MEDIUM** — CONFIRMED
- **Evidence:** `app_ar.arb:9738` `childResultPraiseMasteredAdd` "أتقنت جمع الكسور!" — a prototype sample topic in a live praise string (plus jargon, FVX-G-02).
- **Fix:** placeholder `{topic}` from the result model (rule 23 data dynamism). **Batch VX-B3.**

### FVX-C-07 — SCR-FAT-012 / FAT-013 row meta renders empty separators
- **Nature:** VISUAL · STATE — **LOW** — CONFIRMED (code), PENDING-RENDER
- **Evidence:** `children_list_screen.dart:765, 775` render "📍  · " / "🔋 · ⏱" when location/battery labels are empty (new children).
- **Fix:** omit empty segments. **Batch VX-B6** (with FVX-S-04). **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B6 Owner gate; phone check PENDING-DEVICE).**

### FVX-C-08 — SCR-FAT-018 SOS alert opened with no alert
- **Nature:** STATE · UX — **MEDIUM** — PENDING-RENDER
- **Evidence:** Parent-side SOS buttons across ~15 screens fire SOS then `push('/scr-fat-018')` (e.g. `conversations_list_screen.dart:153`, `settings_hub_screen.dart:96`) — valid event-driven entry; but the Settings hub shortcut (FVX-S-09) opens it with no event.
- **Fix:** covered by FVX-S-09 + verify FAT-018 renders a designed "no active alert" state (SHR-006 look) when opened without an alert. **Batch VX-B5.** **Status: CLOSED — FIXED, PASSED 2026-09-26 (VX-B5 Owner gate; phone check PENDING-DEVICE)** — empty state covered by `vx_b5_sos_no_alert_state_test` + Settings shortcut removed.

---

## 5. Documentation / registry drift (no code change)

| ID | Drift | Evidence | Resolution |
|---|---|---|---|
| FVX-D-01 | `PROJECT_EXECUTION_PLAN.md` had no marker for the CE-B0→B5 campaign or for this verification gate. | grep of plan for CONTROL/CE-B/VISUAL: 0 hits | **CLOSED 2026-09-25** — D12: both markers added to the plan CURRENT STATE table + gate section; AGENTS.md marker added. |
| FVX-D-02 | FAT-077 described as "OOS correctly unrouted" but is routed. | `CONTROL_EXPERIENCE_AUDIT.md` vs `router.dart` | Correct audit text after OD-11. |
| FVX-D-03 | FRONTEND_COMPLETION_MATRIX / PROGRESS carry no CE-B0→B5 entries. | `CE_B0_B5_COMPLETE_CHANGE_IMPACT_INVENTORY.md` notes this | Append CE rows at final certification. |
| FVX-D-04 | FAT-021/CHD-007 marked "YES (Local chat list)" while production repositories are unbound empty stores. | FVX-S-01 | Re-classify after VX-B6 lands the D9 local-database binding. |
| FVX-D-05 | FS-008 (S-PAR-030) missing from `services.csv`; 18 services on no journey. | Phase 3 `01_SYSTEM_MAP.md`, `06_JOURNEY_INTEGRITY_MAP.md` | Registry only; carried AUD-C7 (Owner). |
| FVX-D-06 | 14 identity routes in `app/lib/app/sys3_routes.dart` are live surfaces not in `screens.csv`. | sys3_routes.dart | Included in the matrix as non-catalog surfaces; no registry change without Owner. |

---

## 6. Closed capabilities that stay closed (not fix targets)

These are **correct** honest closures; the verification program checks that their copy is human (FVX-G-02) and that no control implies enforcement, but it does not open them.

| Capability | Classification | Surfaces |
|---|---|---|
| OS app blocking / VPN-DNS web filtering / system lock | NATIVE_CLOSED | FAT-034, 035, 036, 037, 078, CHD-021 |
| Live GPS / battery / heartbeat | NATIVE_CLOSED | FAT-006, 013, 014, 015, 016, 017, 025, 026, CHD-004, CHD-024 |
| Calls (LiveKit), camera, microphone, file picker, QR camera | NATIVE_CLOSED | FAT-023, 024, 042, CHD-002, 009, 023, 036 |
| Screen capture / MediaProjection | NATIVE_CLOSED | FAT-065, 066, 067, 068 |
| Biometrics | NATIVE_CLOSED | SHR-003 (see FVX-C-01) |
| Push/FCM/SMS delivery, email/PDF export, multi-device chat delivery | REMOTE_CLOSED | FAT-008, 018, 021, 022, 033, 069, 073, CHD-005, 006, 007, 008, 020 |
| AI Gateway (Advisor/Insights/Tutor) | REMOTE_CLOSED | FAT-011, 029, 043, 044, 062–064, 073, 074, 076, 079, 080, 083, CHD-017, 028, 032 |
| Licensed Quran audio pack | REMOTE_CLOSED | FAT-072, CHD-025, 026, 032 |
| Billing / store | REMOTE_CLOSED | FAT-056, 057 |

---

## 7. Explicit NO ACTION (checked — no fix needed)

| # | Item | Why no action |
|---|---|---|
| N-01 | `family_members_screen.dart:562` invite disabled for non-owner | Correct RBAC (owner-only), not a dead button. |
| N-02 | LOCAL_DEMO banners on FAT-010/012/025 | Honest and required; keep. |
| N-03 | Q-CEX-001..004 closures (chat ticks, lock copy, home-router guide) | Owner-locked; preserve. |
| N-04 | `simulateBypassAttempt` / `simulateSimChange` (`instant_lock_screen.dart:291–296`) | Public test hooks, not called from UI. |
| N-05 | Theme tap targets (`materialTapTargetSize.padded`, IconButton 48×48) | Global 48 dp baseline correct; only custom InkWell/WidgetSpan links need review (FVX-C-02). |
| N-06 | `Icons.arrow_back` back buttons (7 sites) | Auto-mirrors correctly in RTL. |
| N-07 | AI suggestions (AIC) suggest-only with approve/reject | Rule 7/26 satisfied. |
| ~~N-08~~ | Shell FAB position `left: 16` | **Reopened 2026-09-25** — D1 enabled English; moved into FVX-G-12 (VX-B4). |
| N-09 | `EdgeInsets.fromLTRB` (≈150 files) | Almost all symmetric; only asymmetric ones reviewed in render pass. |
| N-10 | SOS/chat/Quran never time-locked or plan-gated | Rules 9/11 honoured in copy and routing. |
| N-11 | Audit log repository append-only | Rule 10 honoured. |
| N-12 | `device_user_switch_screen.dart:125` colour parse | Data-driven colour, not a literal. |
| N-13 | Parent-side SOS button → fire → push FAT-018 | Event-driven entry (G-6); only the Settings shortcut is wrong (FVX-S-09). |
| N-14 | CE-B1 tasks/ops, CE-B2 reports empty-first, CE-B3 control spine, CE-B4 Quran local, CE-B5 mock hardening | Closed with evidence; regression-protect only. |
| N-15 | Only 3 `GestureDetector` uses | Low risk; Semantics check in render pass only. |
| N-16 | SHR-005 / SHR-006 templates (`AppErrorState`, `AppEmptyState`) | Correct shared components; adoption is checked per screen in the matrix. |

---

## 8. Owner decisions referenced

**Status 2026-09-25:** ANSWERED — OD-01 (real EN switch), OD-02 (glossary + one child line), OD-05 (Western digits), OD-07 (parent + viewed child), OD-09 (local database seeded from roster, no mock messages), OD-12 (authorized). Second round (same day) ANSWERED — OD-03 (YES, rule-21 token authorization), OD-04 (role home + message), OD-06 (NO CHANGE), OD-08 (YES, VX-B8), OD-10 (YES), OD-11 (YES, → FAT-075). **OPEN (raised by VX-B2, 2026-09-25):** none — OD-13 and OD-14 **CLOSED** 2026-09-26 (Owner-run; `.verify/OD-13-SOS-PARENT-CHILD.json` · `.verify/OD-14-EDU-ROSTER.json`).

Full list with options lives in `FINAL_VISUAL_UX_JOURNEY_EXECUTION_PLAN.md §8`: OD-01 language · OD-02 honesty glossary · OD-03 contrast token · OD-04 role-guard landing / gallery · OD-05 numerals · OD-06 core/policy defaults · OD-07 parent SOS actor · OD-08 mock relocation · OD-09 family chat on single device · OD-10 settings shortcuts (only if G-6 reading disputed) · OD-11 FAT-077 · OD-12 plan marker / CHANGE PHASE · plus carried AUD-C*, REP-C*, CHAT-C*.
