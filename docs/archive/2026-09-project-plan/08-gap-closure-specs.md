# 08 — Gap Closure Specs (Phase 6.5)
**Mission:** Discovery phase 6.5 · Branch `discovery/master-plan`  
**Date:** 2026-09-20 · **Authority:** Owner directive — analytical closure inside discovery; Policy Register supreme  
**Scope:** Full closure specs for `SET-001…024` (one block each). Specification only — no production code (Rule 23).  
**Living index:** [`GAP_LOG.md`](../../GAP_LOG.md) keeps IDs; each Closure column points here.  
**Git:** Local until PR #2 merges — do not push into phase-6 PR.

---

## 0. Method & schema deltas (shared)

**Template (mandatory fields):** Owner/controller · Storage · Change semantics · Cross-role propagation · Offline · Edge cases · Validation & limits · Notification · Acceptance criteria (3–5) · Bound laws.

**ALTER-style proposals** (phase 10 will formalize; cited by SET storage lines):

| Gap | Proposed delta (additive) |
|---|---|
| **D-1** | `CREATE TABLE screen_time_policy (child_id, daily_cap_minutes, allow_wallet_overflow bool DEFAULT false, daily_cap_includes_wallet bool DEFAULT true, sleep_start, sleep_end, prayer_pause_enabled, study_window_json, updated_at, updated_by)` |
| **D-1b** | `CREATE TABLE schedule_window (id, child_id, kind enum sleep\|prayer\|study, enabled, start_tod, end_tod, meta jsonb)` |
| **D-2** | `CREATE TABLE app_wallet (child_id, app_id, cap_minutes, remaining_minutes, countable bool, blocked bool)` |
| **D-3** | `CREATE TABLE time_request / time_grant (…)` (UF-05) |
| **D-4** | `CREATE TABLE task / task_assignment / reward_minutes` |
| **D-5** | `CREATE TABLE device_lock_state (device_id, kind, actor_member_id, reason, expires_at, active bool)` |
| **WFP** | `CREATE TABLE web_filter_policy (child_id, level, categories jsonb, dict text[], safe_search bool, block_private bool, allow_list, block_list)` |
| **WFR** | `CREATE TABLE web_unlock_request (id, child_id, url, status, decided_by, reason)` |
| **AT** | `CREATE TABLE anti_tamper_policy (child_id OR device_id, no_delete, no_clock_change, no_vpn, sim_alert, settings_pin, bypass_alert)` |
| **NP** | `notification_prefs` per member (non-critical only; critical/SOS not mutable off) |
| **PRIV** | `privacy_collection_scopes` + wipe/forget job tables |
| **MODE** | `smart_mode` + `smart_mode_activation` (host FAT-085) |
| **SOS** | extend ladder config; parents immovable on rung 1 |
| **RULE** | `rules_engine_rule` separate from `ai_suggestion` |

---

## GAP-CLOSURE: SET-001
**Title:** Sleep / prayer / study schedule toggles (VISUAL → real)  
**Host:** `SCR-FAT-032`

- **Owner/controller:** Father OWNER; Mother **FULL** only (doc 20 rules-edit). Child read-only experience. Guardian none. Advisor may suggest.
- **Storage:** D-1b `schedule_window` rows per `child_id` + `kind`; `enabled` bool. Prototype `VISUAL` becomes Drift-backed.
- **Change semantics:** On toggle/save → persist windows → `TimeEngine` / modes recompute → child enters calm/pause/study restriction when window active.
- **Cross-role propagation:** Child CHD bedtime/pause/focus UI updates **same session after sync** (SET-003). Mother below FULL: no edit.
- **Offline behavior:** Child enforces **last-synced** windows; parent edits queue until child ack.
- **Edge cases:** Overlap with smart mode → stricter wins (M-B); mid-window disable → child leaves calm on next policy apply; device offline during parent edit → pending sync banner.
- **Validation & limits:** `end > start`; prayer default 15-min windows if enabled; study allowed-apps list non-empty when enabled.
- **Notification:** Soft child notice on entering sleep/prayer; no critical channel.
- **Acceptance criteria:**
  - Toggle off→on persists across app restart.
  - Child UI shows calm within same session after sync ack.
  - Mother PARTNER cannot change toggles (RoleGuard).
  - Overlapping school mode + sleep uses intersection (stricter).
  - Widget test: control has semantics label + ≥48dp.
- **Bound laws:** S-4; §3 modes; Rule 24; ADR-035 (FULL rules).

---

## GAP-CLOSURE: SET-002
**Title:** Persist daily policy + per-app wallets (no DB today)

- **Owner/controller:** Father; Mother FULL for caps/wallets policy. PolicyEngine reads store — no direct balance writes (Rule 5).
- **Storage:** D-1 `screen_time_policy` + D-2 `app_wallet`. ALTER as §0.
- **Change semantics:** Save policy → Drift write → push to child → TimeEngine.resolve() uses new caps/wallets.
- **Cross-role propagation:** Child CHD-004 countdown + CHD-019 wallets refresh after sync; father sees saved confirmation.
- **Offline behavior:** Child uses last-synced policy; parent save succeeds locally and syncs later; honest “pending device sync”.
- **Edge cases:** Missing child_id; concurrent edits → last-writer with audit; schema migration on first launch.
- **Validation & limits:** `Minutes` ≥ 0; `allow_wallet_overflow` default **false** (Ruling B / SET-024); education apps `countable=false` invariant (S-1) — not a free-form toggle where Register mandates.
- **Notification:** None on save; T-5 warnings use S-3 when near expiry.
- **Acceptance criteria:**
  - After kill/relaunch, caps and wallets reload from store.
  - PolicyEngine.earn/deposit paths read same store.
  - Fake alternate repository compiles (Rule 25 seam).
  - Unit: blocked app never opens via wallet balance (Ruling A).
- **Bound laws:** Ruling A–D; S-1/S-2; Rules 4/5/25; E-1.

---

## GAP-CLOSURE: SET-003
**Title:** Child reflects parent schedule/cap edits same session after sync

- **Owner/controller:** N/A (propagation rule). Triggered by parent save from SET-001/002/024.
- **Storage:** Same policy tables; sync cursor / `updated_at` on policy rows.
- **Change semantics:** Parent save emits `ScheduleChanged` / `TimePolicyChanged` → child device applies → UI streams update **before** next cold open.
- **Cross-role propagation:** Child countdown/wallets/mode tint update live; parent may show “delivered” vs “pending”.
- **Offline behavior:** If child offline, apply on reconnect; until then last-synced; parent status pending.
- **Edge cases:** Child mid-session in countable app when cap drops → TimeEngine locks entertainment, exempts chat/Quran/SOS; race with grant (UF-05) → reconcile with audit.
- **Validation & limits:** Sync must be idempotent; no double-subtract.
- **Notification:** Optional soft child toast; not critical.
- **Acceptance criteria:**
  - Integration: parent −30 min cap → child remaining updates without relaunch after sync.
  - Offline child: applies on reconnect; no false “applied” on parent.
  - Expiry still leaves chat/Quran/SOS up.
- **Bound laws:** Rule 24 loop closure; Rules 9/11; G-1 offline-first.

---

## GAP-CLOSURE: SET-004
**Title:** Web filter category rows (VISUAL → WebFilterPolicy)

- **Owner/controller:** Father; Mother FULL. Child experiences blocks only.
- **Storage:** WFP `web_filter_policy.categories` jsonb map category→enabled.
- **Change semantics:** Toggle → persist → rebuild block decisions immediately for new navigations.
- **Cross-role propagation:** Child block page for matched categories; father preview (SET-005) uses same snapshot.
- **Offline behavior:** Child last-synced categories; parent queues.
- **Edge cases:** Category on + allow-list exception → allow wins for that URL; level “open” still respects explicit block-list.
- **Validation & limits:** Known category keys only; level ∈ {strict, balanced, open}.
- **Notification:** None unless unlock request (SET-006).
- **Acceptance criteria:**
  - Toggle persists; CSS-only path removed in Flutter.
  - Enabling “adults” blocks matching fixture URLs on child.
  - Mother PARTNER cannot edit.
- **Bound laws:** P-8; ADR-035 FULL rules.

---

## GAP-CLOSURE: SET-005
**Title:** Polite block page + father preview share policy snapshot

- **Owner/controller:** System renders; policy owned as SET-004. Father opens preview from FAT-036.
- **Storage:** Read-only view of WFP snapshot at decision time (`policy_version`).
- **Change semantics:** Block decision → child polite page; father preview simulates same evaluator.
- **Cross-role propagation:** Child sees human-language reason (G-3); father sees identical category/rule hit.
- **Offline behavior:** Child can show block from local policy; preview uses local copy.
- **Edge cases:** Policy changed while page open → refresh re-evaluates; unlock pending state shown.
- **Validation & limits:** Never blank/technical IDs in UI (G-3).
- **Notification:** Optional link to unlock request.
- **Acceptance criteria:**
  - Same URL+policy → identical allow/deny on child page and father preview.
  - Copy is Arabic human language.
  - Unlock CTA visible when permitted.
- **Bound laws:** P-8; G-3; Rule 24.

---

## GAP-CLOSURE: SET-006
**Title:** Child→parent web unlock request loop

- **Owner/controller:** Child initiates; Father or Mother ②/③ decides (approve/deny). Mother ① cannot approve.
- **Storage:** WFR `web_unlock_request`; on approve, exception row in WFP allow_list (scoped).
- **Change semantics:** Request → parent inbox → decision → exception or rejection reason → child notified.
- **Cross-role propagation:** Immediate inbox alert (tier 2); child result toast after sync.
- **Offline behavior:** Child queues request; parent decides when online; apply exception on child reconnect.
- **Edge cases:** Duplicate URL throttle; father deny + mother approve conflict → **father wins** + audit; expiry of temporary unlock if scoped.
- **Validation & limits:** URL format; throttle; mother cannot grant permanent policy beyond level rights.
- **Notification:** Parent new-request; child decision.
- **Acceptance criteria:**
  - End-to-end: request → mother② approve → site loads on child.
  - Mother① approve control absent/denied.
  - Audit row with actor.
- **Bound laws:** P-8; doc 20; ADR-035 conflict rule.

---

## GAP-CLOSURE: SET-007
**Title:** Anti-tamper invisible to mother (all levels)

- **Owner/controller:** Father OWNER only configures. Mother **must not see** surface (OBSERVER/PARTNER/FULL).
- **Storage:** AT `anti_tamper_policy` — written only under FatherSession.
- **Change semantics:** UI composition / RoleGuard **omits** anti-tamper routes and widgets for `PARENT`/`GUARDIAN`.
- **Cross-role propagation:** Child device still enforces father policy; mother UI has no greyed rows.
- **Offline behavior:** N/A for mother UI; child last-synced defenses.
- **Edge cases:** Deep link to anti-tamper → deny panel; `can('rules')` must not imply anti-tamper (split keys).
- **Validation & limits:** Permission key `ANTI_TAMPER` owner-only.
- **Notification:** None for hide rule.
- **Acceptance criteria:**
  - Widget/integration: mother FULL session — zero anti-tamper nodes in tree.
  - Father session — six switches visible.
  - Attempted API write as mother → 403 + audit.
- **Bound laws:** **ADR-035-b**; ADR-035; P-6; Rule 8.

---

## GAP-CLOSURE: SET-008
**Title:** Documented enable-effects for each anti-tamper switch

- **Owner/controller:** Father OWNER only.
- **Storage:** AT flags: `no_delete`, `no_clock_change`, `no_vpn`, `sim_alert`, `settings_pin`, `bypass_alert`.
- **Change semantics:** Each flag ON activates OS/Device-Admin/Screen-Time intent per Register P-6 “what happens when enabled” line; OFF deactivates where OS allows.
- **Cross-role propagation:** Child device applies; father receives alerts when `bypass_alert`/`sim_alert` fire.
- **Offline behavior:** Last-synced flags; alert events queue to father.
- **Edge cases:** OS permission missing → health repair path (FAT-025/026); partial apply honest UI.
- **Validation & limits:** Boolean flags; enabling may require OS permission grant first.
- **Notification:** Father alert channel on bypass/SIM (not muteable by quiet hours if classified critical — align with product urgency tiers; SOS remains P-4).
- **Acceptance criteria:**
  - Each of 6 switches has ARB “when enabled” description on screen.
  - Enabling `bypass_alert` produces father notification on simulated bypass in test.
  - Persists across restart.
- **Bound laws:** P-6; device health tables.

---

## GAP-CLOSURE: SET-009
**Title:** Mother lock vs father unlock conflict → father wins

- **Owner/controller:** Instant lock: Father + Mother FULL. Unlock supersession: Father wins.
- **Storage:** D-5 `device_lock_state` + `audit_log` supersession entry.
- **Change semantics:** Concurrent or sequential conflict → owner unlock/lock prevails; superseded action recorded.
- **Cross-role propagation:** Child ends in father-determined state; both parents see audit; mother notified if superseded.
- **Offline behavior:** Commands queue; on reconnect apply with owner-precedence resolver.
- **Edge cases:** Timer lock vs father unlock; internet-only variant; exempt chat/Quran/SOS always reachable.
- **Validation & limits:** Cannot target exempt surfaces.
- **Notification:** Father “mother locked X”; mother “father unlocked”.
- **Acceptance criteria:**
  - Test: mother lock then father unlock → child unlocked + two audit rows + supersession.
  - Exempt surfaces reachable while locked.
  - Mother ①/② cannot lock.
- **Bound laws:** ADR-035; Rule 11; D-5.

---

## GAP-CLOSURE: SET-010
**Title:** Quiet hours never silence SOS/critical (**P-4**)

- **Owner/controller:** Father sets quiet hours for **non-critical** prefs. Critical/SOS channel **not** father-disableable.
- **Storage:** NP `notification_prefs.quiet_hours_*` applies only to non-critical tiers; critical delivery path bypasses prefs.
- **Change semantics:** Quiet hours ON → mute/digest non-critical; SOS/critical still pierce silent (C-4/P-4).
- **Cross-role propagation:** Mother/Father still receive SOS; child SOS UX unchanged.
- **Offline behavior:** Local critical alert path still attempts; cloud best-effort.
- **Edge cases:** Quiet hours during SOS → siren still; subscription expired → still; no UI toggle “mute SOS”.
- **Validation & limits:** Pref schema forbids `sos_enabled=false` for guardians.
- **Notification:** Critical channel only for SOS.
- **Acceptance criteria:**
  - With quiet hours active, simulated SOS still notifies father+mother (test harness).
  - No mute-SOS control in FAT-058.
  - Unit: prefs filter excludes critical tier.
- **Bound laws:** **P-4**; Rules 9/11; C-4; S-3 tiers.

---

## GAP-CLOSURE: SET-011
**Title:** Mother notification identity ≠ father clone

- **Owner/controller:** Mother manages her non-critical prefs; SOS receipt **always on** (ungradeable). Father does not mirror her toggles.
- **Storage:** NP per `member_id`; separate rows for OWNER vs PARENT.
- **Change semantics:** Mother pref change updates only her row; R-3 / `S-AIC-029` analysis notices remain defined for mother.
- **Cross-role propagation:** Father prefs unchanged; child unaffected.
- **Offline behavior:** Last-synced prefs.
- **Edge cases:** Attempt to disable SOS receipt → control absent / rejected.
- **Validation & limits:** Cannot disable SOS/location/chat rights (doc 20 three rights).
- **Notification:** N/A.
- **Acceptance criteria:**
  - Two members → independent quiet-hours flags.
  - Mother cannot disable SOS receipt in UI or API.
  - Analysis notify still reaches mother per R-3.
- **Bound laws:** R-3; doc 20; P-4; `S-AIC-029`.

---

## GAP-CLOSURE: SET-012
**Title:** Child transparency mirrors collection toggles

- **Owner/controller:** Father OWNER privacy screens. Child views «ماذا يُجمع عني» (`S-ADM-035`).
- **Storage:** PRIV `privacy_collection_scopes` per child; child screen reads same store.
- **Change semantics:** Father flips scope → child card updates after sync (same session when online).
- **Cross-role propagation:** Child sees honest list; mother may view if exposed, cannot edit owner privacy.
- **Offline behavior:** Child last-synced scopes + “last updated” honest.
- **Edge cases:** Scope off while historical data retained — copy explains retention vs collection (no invent wipe).
- **Validation & limits:** Owner-only writes.
- **Notification:** Soft child update optional.
- **Acceptance criteria:**
  - Toggle location-collection off → child card removes location line after sync.
  - Child cannot edit scopes.
- **Bound laws:** P-7; `S-ADM-035`; Rule 8 owner privacy.

---

## GAP-CLOSURE: SET-013
**Title:** Forget vs wipe — separate confirmations

- **Owner/controller:** Father OWNER. Forget = Advisor memory only. Wipe = family data lifecycle.
- **Storage:** Forget → AI memory store only. Wipe → wipe job + **audit_log append**; never deletes audit (R10).
- **Change semantics:** Forget: single confirm → clear advisor memory. Wipe: double confirm + 7-day regret window → schedule wipe; audit entry immediately.
- **Cross-role propagation:** Mother/child notified of wipe per product copy; messages/audit untouched by forget.
- **Offline behavior:** Wipe schedule requires online confirm; forget can queue.
- **Edge cases:** Forget button must not appear on audit screen; wipe cancel within 7 days.
- **Validation & limits:** Distinct routes; RoleGuard owner-only.
- **Notification:** Owner confirmations; family notice on wipe schedule.
- **Acceptance criteria:**
  - Forget leaves `audit_log` and chat intact.
  - Wipe requires two steps + shows 7-day window.
  - Audit lists wipe request entry.
- **Bound laws:** R10; privacy wipe amendment; Rule 8.

---

## GAP-CLOSURE: SET-014
**Title:** AI stages = server flags (no local inference unlock)

- **Owner/controller:** Father views stages; **server** feature flags gate. No on-device model.
- **Storage:** Remote config / stage flags; local cache for UI only.
- **Change semantics:** Inactive stage → designed coming-soon/inactive UI; active → gateway features. Local toggle cannot enable inference.
- **Cross-role propagation:** Mother cannot open brain (SET-015); child sees transparency only.
- **Offline behavior:** Last flags + inactive UI if unknown.
- **Edge cases:** Stale cache showing active while server off → next fetch corrects; no execute path.
- **Validation & limits:** Flags enum per charter stages.
- **Notification:** None for flag fetch.
- **Acceptance criteria:**
  - With flag off, stage CTA disabled/coming-soon.
  - No on-device inference code path in architecture tests.
  - Mock AdvisorRepository still serves prototype suggestions (Rule 26).
- **Bound laws:** Rule 26; charter stages; `S-ADM-033`.

---

## GAP-CLOSURE: SET-015
**Title:** Mother cannot open brain control (any level)

- **Owner/controller:** Father only (`S-ADM-033` / doc 20).
- **Storage:** N/A — route guard.
- **Change semantics:** RoleGuard blocks `SCR-FAT-029` for PARENT/GUARDIAN/CHILD; deny panel.
- **Cross-role propagation:** Mother informed of analyses via R-3 channel, not control panel.
- **Offline behavior:** Guard still applies offline.
- **Edge cases:** Deep link → deny; FULL still blocked.
- **Validation & limits:** Server also asserts owner on AI scope APIs.
- **Notification:** None.
- **Acceptance criteria:**
  - Mother FULL navigation to brain → blocked (S5-style).
  - Father opens successfully.
- **Bound laws:** doc 20; Rule 8; `S-ADM-033`.

---

## GAP-CLOSURE: SET-016
**Title:** Platform monitoring toggles read capability table

- **Owner/controller:** Father; Mother FULL for rules where delegated. Capability matrix is system truth.
- **Storage:** Capability table (platform × feature → `full` \| `reports_only` \| `unavailable`) + user desired toggles.
- **Change semantics:** UI renders desired AND capability; effective = min(desired, capability).
- **Cross-role propagation:** Child transparency reflects effective monitoring (P-7).
- **Offline behavior:** Last capability + desired.
- **Edge cases:** iOS unavailable must not show as on (SET-017).
- **Validation & limits:** Cannot set desired above capability without honesty badge.
- **Notification:** None.
- **Acceptance criteria:**
  - Fixture iOS `unavailable` → toggle disabled + badge.
  - Android `full` → toggle works and persists.
- **Bound laws:** P-7; G1 platform honesty; P-10 adjacent.

---

## GAP-CLOSURE: SET-017
**Title:** Disabled iOS claims must not look enabled

- **Owner/controller:** Same as SET-016.
- **Storage:** Same capability + desired.
- **Change semantics:** Visual state for `unavailable`/`reports_only` uses disabled styling; not “on” green.
- **Cross-role propagation:** Honesty visible to father; child transparency matches effective.
- **Offline behavior:** Unchanged.
- **Edge cases:** Partial reports_only — show limited state copy.
- **Validation & limits:** Design tokens only (Rule 14).
- **Notification:** None.
- **Acceptance criteria:**
  - Golden/widget test: unavailable ≠ selected-on appearance.
  - Semantics announces disabled reason.
- **Bound laws:** Platform honesty; Rule 16.

---

## GAP-CLOSURE: SET-018
**Title:** School mode on FAT-085 only — never route FAT-039

- **Owner/controller:** Father; Mother FULL for modes. Router generation skips tombstones.
- **Storage:** MODE tables; services S-SEC-058/059 rebound to FAT-085 (T-1). Registry CSV untouched.
- **Change semantics:** School config/activate only via FAT-085; FAT-039 not in go_router.
- **Cross-role propagation:** Child status via SET-019; no dead nav.
- **Offline behavior:** Last active mode.
- **Edge cases:** Deep link fat-039 → 404/home; registry still lists tombstone historically.
- **Validation & limits:** CI: tombstone rows never routed (ADR-034).
- **Notification:** Father on auto-activate if configured.
- **Acceptance criteria:**
  - Router test: FAT-039 absent.
  - School schedule editable on FAT-085.
  - S-SEC-058 ops bind to FAT-085 hosts in docs/code maps.
- **Bound laws:** ADR-034; T-1; §G-2; §G-4 additive registry.

---

## GAP-CLOSURE: SET-019
**Title:** Child CHD-004/018 follow active smart-mode stream

- **Owner/controller:** Parent activates mode (FAT-085); child consumes stream.
- **Storage:** `smart_mode_activation` current row per child.
- **Change semantics:** Activate → push → child status card + focus tint update same session after sync.
- **Cross-role propagation:** Father sees active; child CHD-004 card; CHD-018 focus.
- **Offline behavior:** Last active mode locally.
- **Edge cases:** Mode end / manual off clears card; conflict stricter wins.
- **Validation & limits:** Mode id known; grace 0–5 default 2 (M-D) unless manual skip.
- **Notification:** Soft child enter/exit.
- **Acceptance criteria:**
  - Activate school → CHD-004 shows school status without relaunch after sync.
  - Deactivate clears card.
- **Bound laws:** §3 M-A…M-D; T-1; SET-003 companion.

---

## GAP-CLOSURE: SET-020
**Title:** Parents immovable on SOS ladder rung 1

- **Owner/controller:** Father edits ladder (`SCR-FAT-028`). Cannot remove father/mother from step 1.
- **Storage:** SOS ladder config; rung-1 members fixed to parents.
- **Change semantics:** UI/API reject removal/disable of rung-1 parents; backups editable below.
- **Cross-role propagation:** Mother always receives (SET-021); child SOS unchanged.
- **Offline behavior:** Last ladder; SOS still local-first (P-4).
- **Edge cases:** Attempt toggleEmergencyContact off on parent → blocked.
- **Validation & limits:** Rung-1 cardinality ≥ both parents when present in family.
- **Notification:** None on illegal attempt (inline error).
- **Acceptance criteria:**
  - Cannot remove mother from rung 1 in UI.
  - API returns validation error.
- **Bound laws:** P-5; doc 20 ungraded SOS receipt.

---

## GAP-CLOSURE: SET-021
**Title:** No SOS mute settings for mother/guardian

- **Owner/controller:** System. No member pref disables SOS receipt.
- **Storage:** Pref schema omits `sos_muted`; RoleGuard hides any such control.
- **Change semantics:** SOS always delivered to father, mother (all levels), guardian.
- **Cross-role propagation:** All guardians alerted; quiet hours irrelevant (SET-010).
- **Offline behavior:** Local critical path.
- **Edge cases:** Notification permission denied → repair path, not mute setting.
- **Validation & limits:** Forbidden fields rejected in API.
- **Notification:** Critical only.
- **Acceptance criteria:**
  - No SOS-off toggle for mother/guardian in settings tree.
  - SOS test reaches mother OBSERVER.
- **Bound laws:** **P-4**; Rule 9; doc 20.

---

## GAP-CLOSURE: SET-022
**Title:** Separate “AI suggestions” vs “My rules” UI

- **Owner/controller:** Father. Advisor proposes suggestions; father authors rules.
- **Storage:** `ai_suggestion` vs `rules_engine_rule` — distinct tables/repos.
- **Change semantics:** Two surfaces: approve/reject suggestions (no execute); enable/edit rules (deterministic).
- **Cross-role propagation:** Mother notified of analyses (R-3); cannot own RulesEngine authoring unless law says otherwise — father-only A-5.
- **Offline behavior:** Queued decisions; rules evaluate on last-synced set.
- **Edge cases:** Approving suggestion **creates** rule — never auto-executes as AiSuggestion.
- **Validation & limits:** Type system: no `AiSuggestion.execute()`.
- **Notification:** Action feed on rule fire; suggestion inbox for father.
- **Acceptance criteria:**
  - UI has two labeled sections/routes.
  - Suggestion approve → appears under My rules; suggestion object still non-executable.
  - Architecture test: RulesEngine outside three AI gateways.
- **Bound laws:** **ADR-038**; Rules 7/26; A-5.

---

## GAP-CLOSURE: SET-023
**Title:** Rule editor blocks owner-only consequents

- **Owner/controller:** Father authors rules. Consequents cannot include anti-tamper, unlock father-blocked app, delegation edit.
- **Storage:** Rule AST/actions enum excluding forbidden consequents; server validates.
- **Change semantics:** Picker omits forbidden actions; save rejected if present.
- **Cross-role propagation:** Child/parent see allowed automations only; audit on fire.
- **Offline behavior:** Invalid local draft cannot sync.
- **Edge cases:** AI-suggested rule draft containing forbidden consequent → blocked at approve (ADR-038 d).
- **Validation & limits:** Allow-list of consequents; 10-min undo still applies to allowed fires.
- **Notification:** Feed on execution.
- **Acceptance criteria:**
  - Cannot select ANTI_TAMPER / BLOCK_OVERRIDE / DELEGATION_EDIT in editor.
  - API rejects forbidden consequent payload.
  - Instant lock may remain allowed only if product allow-list says so — **default: follow ADR-038(d) explicit list** (anti-tamper, unlock blocked, delegation) as forbidden; do not expand without decision.
- **Bound laws:** ADR-038(d); ADR-035; A-5.

---

## GAP-CLOSURE: SET-024
**Title:** Wallet overflow father switch (Ruling B)

- **Owner/controller:** Father OWNER (policy). Default **off**. Mother FULL may edit if treated as rules/limits (doc 20) — **exposed as per-child policy flag on FAT-032**.
- **Storage:** D-1 `screen_time_policy.allow_wallet_overflow` bool DEFAULT false; `daily_cap_includes_wallet` DEFAULT true.
- **Change semantics:** OFF → earned wallet cannot exceed daily cap. ON → TimeEngine allows overflow per Ruling B.
- **Cross-role propagation:** Child effective remaining changes after sync; visible in countdown math.
- **Offline behavior:** Last-synced flag.
- **Edge cases:** Toggle mid-day recalculates remaining; never opens father-blocked apps.
- **Validation & limits:** Bool; per child; no hidden default on (E-2 spirit for policy honesty).
- **Notification:** None required.
- **Acceptance criteria:**
  - Default false on new child policy.
  - With overflow off, grant that would exceed cap clamps or rejects per TimeEngine rules (document clamp in implementation tests).
  - With overflow on, earned minutes usable beyond cap.
  - Blocked app still locked (Ruling A).
- **Bound laws:** Ruling **B**; S-2; Rule 24.

---

## Phase 6.5 exit

- [x] SET-001…024 each have full 10-field closure specs
- [x] Storage cites D-1…D-5 / ALTER proposals where missing
- [x] P-4 / ADR-035-b / ADR-038 / ADR-039 / T-1 bound
- [ ] GAP_LOG pointers (Part C) — **done**
- [ ] Phase 7 UI closures (Part B) — **done** in `09-ui-ux-gap-analysis.md`

**Next:** Hold local; after PR #2 merges → push Phase 6.5+7 as PR #3. Architecture = `10-system-architecture.md`.
