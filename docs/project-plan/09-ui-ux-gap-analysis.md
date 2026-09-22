# 09 — UI/UX Completeness Gap Analysis
**Mission:** Discovery phase 7 · Branch `discovery/master-plan`  
**Date:** 2026-09-20 · **Authority:** Section A · Policy Register · frozen HTML = UI ground truth · **Do not redesign**  
**Counting:** 129 active screens + 1 tombstone (ADR-034)  
**Numbering:** Owner override — Phase 6.5 occupies `08-gap-closure-specs.md`; this file is **09**. Future architecture = `10-system-architecture.md`.  
**Note:** Local until PR #2 merges — not in phase-6 PR.

---

## 0. Freeze & method

| Constraint | Status |
|---|---|
| Audit existing screens only — no arbitrary redesign | **Honored** |
| VISUAL/mock toggles = Rule 23 sample rendering, not defects | **Honored** |
| SET-001…024 full specs in [`08-gap-closure-specs.md`](08-gap-closure-specs.md) | **Honored** |
| Every `UI-*` gap has a **full GAP-CLOSURE** (§8 annex) — not one-line only | **Honored** |
| Tombstone FAT-039 never routed | **Honored** |

**Checklist (Master Command Phase 7):** navigation · hierarchy · actions · forms · validation · feedback · loading · errors · empty · confirmations · destructive · permissions · a11y · responsive · localization · consistency · reusable components · state transitions.

**Status codes:** `OK-PROTO` · `GAP` · `LAW` · `SET-n` · `UI-n`

**Shared templates:** SHR-005 error · SHR-006 empty (G-6 event-invoked).  
**A11y / i18n floors:** Rule 16 (≥48dp + semantics) · Rule 12 (ARB).

---

## 1. Spine / high-traffic screens (row-level)

### 1.1 Pairing & onboarding

| Screen | Nav | Forms/valid | Empty/load/err | Confirm | Perm | Gaps |
|---|---|---|---|---|---|---|
| FAT-001 | OK-PROTO | name required | GAP | — | owner | **UI-001** |
| FAT-002 | OK-PROTO | steps | OK-PROTO | — | — | **UI-002** |
| FAT-003 | OK-PROTO | required | GAP | — | owner | Parametric N children (S3) |
| FAT-004 | OK-PROTO | — | loading rotate | — | OWNER | Expired → rotate (UF-01) |
| CHD-002 | OK-PROTO | camera | camera-denied | — | child | **UI-003** |
| FAT-005 | OK-PROTO | — | — | — | — | Keep WHY (G-3) |
| FAT-006 / CHD-003 | OK-PROTO | — | — | — | — | Transparency ack |

### 1.2 Day boards & requests

| Screen | Gaps |
|---|---|
| FAT-010 | **UI-004** · Advisor FAB suggest-only |
| CHD-004 | **UI-005** · SET-003/019 streams · SHR-006 empty |
| FAT-033 inbox | **UI-006** · ADR-039 ceiling UI |
| CHD-020 | Exclusive duration highlight (S4); mother over-ceiling denied |

### 1.3 Safety & lock

| Screen | Gaps |
|---|---|
| CHD-005/006 · FAT-018 | LAW **P-4** |
| Instant lock | Confirm; exempts; mother FULL; father wins |
| Anti-tamper | SET-008 effects; mother **omitted** (ADR-035-b) |

### 1.4–1.7 Chat, economy, owner surfaces, settings

Unchanged audit conclusions from prior draft: chat never locked; minutes-only tasks; brain/audit/privacy/billing owner-gated; settings presentation **UI-008…010** + SET specs in `08-…`.

---

## 2. Cluster audit (remaining)

| Cluster | Top missing UI | IDs |
|---|---|---|
| B · Expiry CHD-021 | Explicit chat+Quran still open | **UI-011** |
| K · Device health | Permission repair round-trip | **UI-012** |
| M · Coming soon FAT-075 | Honest non-dates | **UI-013** |
| N · SHR-005/006 | Event-invoked reuse | LAW G-6 |
| C · Router FAT-078 | Post-setup verify | Phase 4 cluster |
| Others | See prior cluster table — Proto OK / inherit SET | SET-* |

---

## 3. Cross-cutting UI laws

RoleGuard owner-only · **ADR-035-b** invisible anti-tamper · **ADR-039** grant ceiling UI · **P-4** never mute SOS · ADR-038 two surfaces · Rule 23 state range · Rules 12/16 · tokens · G-5 parametric ChildId.

---

## 4. Index of UI gaps → full specs

| ID | One-line reminder | Full spec |
|---|---|---|
| UI-001…018 | See §8 below | `#UI-00N` anchors in this file |
| SET-001…024 | Settings conversion | [`08-gap-closure-specs.md`](08-gap-closure-specs.md) |

**Import (A5):** Phase 13 imports `UI-*` + `SET-*` — extend `GAP_LOG.md`, do not fork.

---

## 5. Reusable components (F0 preview)

`AppEmptyState` ← SHR-006 · `AppErrorState` ← SHR-005 · `AppLoading` · `AppConfirmSheet` · `MinutesText` · ChildId header · RoleGuard deny panel. Once in `core/design/components/` (Rule 15).

---

## 6. Phase 7 exit criteria

- [x] Checklist; no redesign
- [x] Spine + clusters audited
- [x] Cross-cuts bound
- [x] **UI-001…018 each have full GAP-CLOSURE (§8)**
- [x] SET items point to Phase 6.5 specs
- [x] Numbering: this file = **09**

**Next:** Phase 8 — system architecture (`10-system-architecture.md`).

---

## 8. Annex — GAP-CLOSURE specs for UI-001…018

### GAP-CLOSURE: UI-001
**Host:** `SCR-FAT-001` create family  
- **Owner/controller:** Father OWNER creating family.  
- **Storage:** `family` / `account` rows on success; error is ephemeral UI state.  
- **Change semantics:** Create fail (network/server) → show **SHR-005** composition with retry; success → navigate wizard.  
- **Cross-role propagation:** N/A until family exists.  
- **Offline behavior:** Show SHR-005 offline variant; queue not required for create (must be online) OR honest “needs network”.  
- **Edge cases:** Timeout vs 4xx validation — distinct copy.  
- **Validation & limits:** Required family name; ARB strings.  
- **Notification:** None.  
- **Acceptance criteria:** (1) Forced network fail renders SHR-005. (2) Retry re-invokes create. (3) Success path unchanged. (4) Semantics on retry CTA.  
- **Bound laws:** G-6; Rule 23 error state; Rule 16.

### GAP-CLOSURE: UI-002
**Host:** `SCR-FAT-002` completeness wizard  
- **Owner/controller:** Father.  
- **Storage:** Onboarding progress flags (non-blocking).  
- **Change semantics:** Completeness items are **suggestions**, never forced gates (doc 20 invite principle).  
- **Cross-role propagation:** None.  
- **Offline behavior:** Show cached progress.  
- **Edge cases:** Skip mother invite still allowed.  
- **Validation & limits:** No hard-block on “incomplete”.  
- **Notification:** None.  
- **Acceptance criteria:** (1) Can proceed without completing every row. (2) Copy reads as suggestion. (3) Mother invite remains optional.  
- **Bound laws:** doc 20; G-3.

### GAP-CLOSURE: UI-003
**Host:** `SCR-CHD-002` QR scan  
- **Owner/controller:** Child device claiming token.  
- **Storage:** None until claim; OS camera permission state in `device_permission`.  
- **Change semantics:** Camera denied → repair UI (explain + deep-link OS settings) — not dead end.  
- **Cross-role propagation:** Father QR remains valid until TTL.  
- **Offline behavior:** Claim may queue; camera permission still local.  
- **Edge cases:** Permanently denied on iOS — show manual instructions.  
- **Validation & limits:** UF-01 token rules.  
- **Notification:** None.  
- **Acceptance criteria:** (1) Deny camera → repair CTA visible. (2) After grant, scan resumes. (3) ≥48dp CTA.  
- **Bound laws:** UF-01; R-4; device_permission.

### GAP-CLOSURE: UI-004
**Host:** `SCR-FAT-010` morning board  
- **Owner/controller:** Father views; data from repos.  
- **Storage:** Dashboard projections from tasks/requests/alerts repos — **no hardcoded sample numerals** in widgets.  
- **Change semantics:** Each card binds to provider; empty/loading/error/one/many.  
- **Cross-role propagation:** Child actions (thikr, requests) appear via real events (Rule 23).  
- **Offline behavior:** Last-synced cards + honest banner.  
- **Edge cases:** Advisor FAB → suggest only (no execute).  
- **Validation & limits:** CI flags sample literals.  
- **Notification:** Cards reflect notification-sourced events.  
- **Acceptance criteria:** (1) Empty family → empty cards not fake Khaled. (2) Pending request card opens real inbox. (3) Advisor cannot apply silently.  
- **Bound laws:** Rule 23; Rule 7; S2 walkthrough.

### GAP-CLOSURE: UI-005
**Host:** `SCR-CHD-004`  
- **Owner/controller:** Child views; parent policy drives.  
- **Storage:** Streams from screen_time_policy + smart_mode_activation.  
- **Change semantics:** Parent edits → child countdown/mode status update after sync (SET-003/019).  
- **Cross-role propagation:** Matches Phase 6.5 SET specs.  
- **Offline behavior:** Last-synced + SHR-006 if no day data.  
- **Edge cases:** Mode + expiry together.  
- **Validation & limits:** ChildId parametric.  
- **Notification:** Soft mode enter.  
- **Acceptance criteria:** (1) Cap change reflects without relaunch post-sync. (2) Empty day uses SHR-006. (3) No planted prototype minutes.  
- **Bound laws:** Rule 23; SET-003; SET-019.

### GAP-CLOSURE: UI-006
**Host:** Request inbox / FAT-033  
- **Owner/controller:** Father; Mother ②/③ approve within **ADR-039** ceiling.  
- **Storage:** time_request / time_grant (D-3).  
- **Change semantics:** Empty → SHR-006; decide → child sees reason; mother UI clamps grant ≤ active ceiling.  
- **Cross-role propagation:** UF-05 loop.  
- **Offline behavior:** Queue decisions.  
- **Edge cases:** Over-ceiling control hidden/disabled for mother.  
- **Validation & limits:** ADR-039.  
- **Notification:** Child decision toast.  
- **Acceptance criteria:** (1) Empty inbox template. (2) Mother cannot submit > ceiling. (3) Child sees reject reason.  
- **Bound laws:** ADR-039; UF-05; G-6.

### GAP-CLOSURE: UI-007
**Host:** `SCR-FAT-056/057` billing  
- **Owner/controller:** Father OWNER only.  
- **Storage:** Entitlement service — **must not** be read by SOS/chat/location modules.  
- **Change semantics:** Plan cancel / trial UI never disables safety.  
- **Cross-role propagation:** Child SOS/chat unaffected by plan state.  
- **Offline behavior:** Safety works offline per P-4.  
- **Edge cases:** Expired subscription + SOS test must PASS.  
- **Validation & limits:** RoleGuard; architecture boundary test.  
- **Notification:** Billing reminders non-critical.  
- **Acceptance criteria:** (1) Mother/child blocked from billing. (2) Expired plan SOS still fires. (3) Chat usable when expired.  
- **Bound laws:** Rule 9; P-4; SET-PAYWALL-RISK; S5.

### GAP-CLOSURE: UI-008
**Host:** Settings spine toggles  
- **Owner/controller:** Per SET owner.  
- **Storage:** Per SET-001…024 stores.  
- **Change semantics:** On convert, every former VISUAL toggle shows loading → success/error feedback (not silent CSS).  
- **Cross-role propagation:** Per linked SET spec.  
- **Offline behavior:** Error/pending honest.  
- **Edge cases:** Rapid toggle debounce.  
- **Validation & limits:** Rule 24.  
- **Notification:** Per SET.  
- **Acceptance criteria:** (1) Save failure shows error state. (2) Success toast/ack. (3) No CSS-only path in Flutter.  
- **Bound laws:** Rule 24; SET-VIS; `08-gap-closure-specs.md`.

### GAP-CLOSURE: UI-009
**Host:** FAT-036 + child block page  
- **Owner/controller:** Father preview; child page.  
- **Storage:** Shared WFP `policy_version` snapshot.  
- **Change semantics:** Preview button opens evaluator UI identical to child block decision.  
- **Cross-role propagation:** SET-005.  
- **Offline behavior:** Local snapshot.  
- **Edge cases:** Stale preview after edit → refresh.  
- **Validation & limits:** G-3 copy.  
- **Notification:** Optional unlock CTA.  
- **Acceptance criteria:** (1) Same URL verdict both UIs. (2) Preview reachable from FAT-036.  
- **Bound laws:** SET-005; P-8.

### GAP-CLOSURE: UI-010
**Host:** `SCR-FAT-058` quiet hours  
- **Owner/controller:** Father.  
- **Storage:** Non-critical prefs only.  
- **Change semantics:** UI copy states SOS/critical excluded; no mute-SOS control.  
- **Cross-role propagation:** SET-010/021.  
- **Offline behavior:** N/A.  
- **Edge cases:** Attempted hidden flag → absent.  
- **Validation & limits:** Schema forbids sos mute.  
- **Notification:** Critical bypasses quiet hours.  
- **Acceptance criteria:** (1) Copy visible. (2) No SOS mute switch in tree. (3) Quiet+on SOS test PASS.  
- **Bound laws:** P-4; SET-010.

### GAP-CLOSURE: UI-011
**Host:** `SCR-CHD-021` time expiry  
- **Owner/controller:** System lock UI; child views.  
- **Storage:** TimeEngine lock state.  
- **Change semantics:** Expiry screen explicitly states family chat & Quran remain available; SOS reachable.  
- **Cross-role propagation:** Parents may see locked status.  
- **Offline behavior:** Local expiry still shows exempts.  
- **Edge cases:** Instant lock + expiry messaging consistent.  
- **Validation & limits:** ARB copy sealed.  
- **Notification:** None required.  
- **Acceptance criteria:** (1) Chat & Quran CTAs visible/enabled. (2) Entertainment locked. (3) S4 walkthrough step PASS.  
- **Bound laws:** Rules 9/11; C-1.

### GAP-CLOSURE: UI-012
**Host:** `SCR-FAT-025/026` device health  
- **Owner/controller:** Father (and mother if viewing health).  
- **Storage:** `device_permission`, `device_health`.  
- **Change semantics:** Missing permission → actionable repair → OS settings → return → re-check stream updates card.  
- **Cross-role propagation:** Child device prompts as needed.  
- **Offline behavior:** Show last health.  
- **Edge cases:** Permanently denied.  
- **Validation & limits:** Per-permission repair.  
- **Notification:** Optional health alert.  
- **Acceptance criteria:** (1) Deny→repair→grant updates UI green. (2) Round-trip without app reinstall.  
- **Bound laws:** Device tables; Phase 4 cluster.

### GAP-CLOSURE: UI-013
**Host:** `SCR-FAT-075` coming soon  
- **Owner/controller:** System.  
- **Storage:** None / remote “soon” flags without fake dates.  
- **Change semantics:** Honest coming-soon; **no** fake ship dates; no pretend toggles.  
- **Cross-role propagation:** Same for all roles who see it.  
- **Offline behavior:** Static honest.  
- **Edge cases:** Must not look like working settings.  
- **Validation & limits:** No date literals unless real.  
- **Notification:** None.  
- **Acceptance criteria:** (1) No concrete fake dates. (2) Toggles absent or clearly non-interactive.  
- **Bound laws:** Rule 23 honesty; G-3.

### GAP-CLOSURE: UI-014
**Host:** Spine interactive CTAs  
- **Owner/controller:** Engineering standard.  
- **Storage:** N/A.  
- **Change semantics:** Every primary CTA has `Semantics` label (ARB).  
- **Cross-role propagation:** N/A.  
- **Offline behavior:** N/A.  
- **Edge cases:** Icon-only buttons.  
- **Validation & limits:** Rule 16 CI/lint.  
- **Notification:** N/A.  
- **Acceptance criteria:** (1) Semantics analyzer clean on spine. (2) Screen reader announces approve/SOS/lock.  
- **Bound laws:** Rule 16.

### GAP-CLOSURE: UI-015
**Host:** SOS, lock, approve, grant controls  
- **Owner/controller:** Engineering standard.  
- **Storage:** N/A.  
- **Change semantics:** Min touch target 48×48 dp.  
- **Cross-role propagation:** N/A.  
- **Offline behavior:** N/A.  
- **Edge cases:** Dense lists.  
- **Validation & limits:** Widget tests measure size.  
- **Notification:** N/A.  
- **Acceptance criteria:** (1) SOS hit target ≥48. (2) Grant approve ≥48.  
- **Bound laws:** Rule 16.

### GAP-CLOSURE: UI-016
**Host:** All FAT/CHD/SHR  
- **Owner/controller:** Engineering standard.  
- **Storage:** ARB files.  
- **Change semantics:** No hardcoded user-facing literals in Dart; RTL layout.  
- **Cross-role propagation:** N/A.  
- **Offline behavior:** N/A.  
- **Edge cases:** Plural/minutes formatting.  
- **Validation & limits:** Rule 12 hooks.  
- **Notification:** N/A.  
- **Acceptance criteria:** (1) `flutter analyze` / custom lint bans literals. (2) AR+EN smoke.  
- **Bound laws:** Rule 12; G-3.

### GAP-CLOSURE: UI-017
**Host:** Day boards  
- **Owner/controller:** Engineering standard.  
- **Storage:** N/A.  
- **Change semantics:** Honor reduce-motion / large text without overflow.  
- **Cross-role propagation:** N/A.  
- **Offline behavior:** N/A.  
- **Edge cases:** Long Arabic strings.  
- **Validation & limits:** Smoke on FAT-010/CHD-004.  
- **Notification:** N/A.  
- **Acceptance criteria:** (1) Large text no clip on primary cards. (2) Reduce-motion disables nonessential motion.  
- **Bound laws:** a11y best practice; Rule 16 spirit.

### GAP-CLOSURE: UI-018
**Host:** Platform monitoring (FAT-067/068)  
- **Owner/controller:** Father / Mother FULL.  
- **Storage:** Capability matrix (SET-016/017).  
- **Change semantics:** Honesty badge; disabled ≠ look “on”.  
- **Cross-role propagation:** Child transparency matches effective.  
- **Offline behavior:** Last capability.  
- **Edge cases:** reports_only intermediate state.  
- **Validation & limits:** Design tokens.  
- **Notification:** None.  
- **Acceptance criteria:** (1) Unavailable styling test. (2) Semantics states reason.  
- **Bound laws:** SET-016; SET-017; P-7.
