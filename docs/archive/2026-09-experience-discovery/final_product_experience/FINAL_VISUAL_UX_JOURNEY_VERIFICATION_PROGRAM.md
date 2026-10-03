# FINAL VISUAL · UX · JOURNEY VERIFICATION PROGRAM

**Date:** 2026-09-25
**Type:** DOCS-ONLY planning. No production code, tests, policy, tokens or rules changed.
**Owner:** Bassam · **Prepared as:** Product UX audit + frontend architecture + interaction design + QA strategy.
**Companions:** `FINAL_VISUAL_UX_JOURNEY_FINDINGS.md` · `FINAL_VISUAL_UX_JOURNEY_MATRIX.md` / `.json` · `FINAL_VISUAL_UX_JOURNEY_EXECUTION_PLAN.md`

---

## 1. Governance position

| Field | Value |
|---|---|
| CURRENT PHASE | Frontend + Local product hardening — FULL FRONTEND CLOSURE COMPLETE; CE-B0→B5 COMPLETE with STOP (per `AGENTS.md`) |
| TASK PHASE | Final Visual · UX · Journey Verification — **planning only** |
| STATUS | **ALIGNED** for these planning docs (docs are authorized work). **Execution batches are not yet authorized**: `PROJECT_EXECUTION_PLAN.md` has no marker for CE-B0→B5 or for this gate, and the CE master plan ends with STOP. |
| REQUIRED GATE | Owner authorizes a plan marker (or says `CHANGE PHASE`) naming this gate before VX-B1 starts. |
| PRODUCTION CODE CHANGE | NO |
| Out of bounds (unchanged) | Native, Backend, FCM, AI Gateway, chat relay, Render, Firestore; `core/policy/`, `tokens.dart`, `.cursor/rules/`; `harness/BACKLOG.md`, `LOOP_STATE.md`. |

The work proposed here is inside the plan's already-authorized frontend list (UI, state, local bind, states, RBAC, AR/RTL, honesty, focused tests, real-device UI checks). It adds no capability class. It is a **verification + residue-fix** pass, not a new campaign of features.

## 2. Verified ground truth

| Item | Docs say | Repo shows | Note |
|---|---|---|---|
| Systems | 42 | 42 `(domain, subsystem)` pairs in `services.csv` | FS-008 (S-PAR-030) has no CSV row (registry gap) |
| Services | 240 | 240 rows | 18 services on no journey |
| Journeys | 73 | 73 (FAT 45 · MOT 9 · CHD 18 · SHR 1) | — |
| Screens (catalog) | 130 = 128 live + 2 OOS | 130 rows: FAT 86 · CHD 37 · SHR 7 (no SHR-004) | Register G-2 "129 official" = 130 minus deleted FAT-039 |
| Routed catalog screens | "OOS unrouted" | 129 generated routes; only FAT-039 tombstoned; **FAT-077 is routed** (deep link only, no hub/link) | discrepancy FVX-D-02 |
| Live product screens | 128 | 128 + FAT-077 reachable by URL | — |
| Non-catalog surfaces | — | 14 identity routes in `sys3_routes.dart` + `/gallery` dev screen | included in matrix §4 |
| Shell | — | 5 parent tabs (FAT-010/012/021/040/025), 4 child tabs (CHD-004/012/007/010), hub strip, AI FAB, SOS FAB | `app/lib/app/family_shell.dart`, `shell_config.dart` |
| Initial route | — | `/scr-shr-001` | — |

Evidence limitation: the shell tool failed in this session (no exit status), so `git status` provenance, `flutter analyze` and test runs could not be produced. Every claim is file:line from reads/greps. The first execution batch starts by running `flutter analyze` to establish a baseline.

## 3. Result standard (no numeric scores)

Every check and every matrix cell resolves to exactly one of:

| Result | Meaning |
|---|---|
| **PASS** | Checked with evidence (test, screenshot, or device note) and meets the standard. |
| **FAIL** | Checked and does not meet the standard → a finding ID is required. |
| **NOT APPLICABLE** | Criterion does not apply to this surface (e.g., no list → no "many items" state). |
| **BLOCKED-NATIVE** | Criterion needs native capability that is closed; the honest closed state itself must still PASS. |
| **BLOCKED-REMOTE** | Criterion needs backend/remote; the honest closed state itself must still PASS. |
| **OWNER-DECISION** | Cannot be judged without an Owner policy choice (OD-nn). |

Working markers before evidence exists: **PENDING-RENDER** (needs a rendered look), **PENDING-DEVICE** (needs a physical phone). A pending marker is never counted as PASS.

## 4. Layer sequence (refined)

Baseline asked for L0–L10. Evidence from the static pass shows two things that force a reorder: (1) **context errors** (wrong child / wrong family / wrong SOS actor) invalidate every later control and journey check — a screen can look perfect and still configure the wrong child; (2) **shared shell/components/RTL mechanics** cascade into all 128 screens, so fixing them late means re-auditing everything.

| Layer | Name | Contents | Why here |
|---|---|---|---|
| **L0** | Global product language & trust residue | debug instrumentation, dev landing, false-success toasts, engineering jargon, numerals, server-error copy | Trust defects are the cheapest and most damaging; language rules must be fixed before judging any screen's copy. |
| **L1** | Context spine *(moved up from L9)* | one child resolver, one family scope, route `childId` pass-through, SOS actor, device ID | Every control/journey verdict depends on "is this the right child?". |
| **L2** | App shell, navigation & shared components *(includes RTL mechanics moved up from L8)* | tabs, hub labels/context, FABs, back behavior (`go` vs `push`), toast system, empty/error/loading components, chevrons, directional alignment, token colours | Shared fixes cascade; do once, then screens inherit. |
| **L3** | Dashboard & family orientation | FAT-010, CHD-004 | Orient → Prioritize → Act → Drill down depends on L1+L2. |
| **L4** | System homes | tab roots and system entry screens (FAT-012, 021, 025, 040, 019, CHD-012, 007, 010 …) | Where each system is "opened". |
| **L5** | System control surfaces | settings/limits/filters/locks/zones/permissions | Control completeness (§8). |
| **L6** | Core journeys | all 73 journeys, father↔child loops | Journey audit (§9). |
| **L7** | Secondary, review & history | logs, history, reports, timelines | Review/Recovery criteria. |
| **L8** | Edge & closed-capability states | offline/stale/pending/unavailable/native-closed/remote-closed | State audit (§11). |
| **L9** | Rendered Arabic/RTL & device | screenshots at 360/412/600 dp, font scale 1.0/1.3, physical phone checklist | Needs the UI to be final. |
| **L10** | Cross-system consistency re-audit & certification | final re-audit + Final Frontend Certification + STOP | Only after all layers PASS or are classified. |

## 5. Visual audit standard

A screen PASSES visual when all apply (checked on a rendered screenshot, not only code):

1. **Hierarchy** — one clear primary action per screen; title → key status → actions → detail. No two competing hero cards.
2. **Layout** — no overflow/clipping at 360 dp width and 1.3 font scale; scroll reaches the last item above the tab bar/FAB; safe areas respected.
3. **Typography** — only theme text styles; Arabic line-height not clipped; long Arabic labels wrap (no ellipsis on actions); secondary text readable (see FVX-G-14 / OD-03).
4. **Components & states** — uses shared components (`AppCard`, `PrimaryBtn`, `RowTile`, `BannerNote`, `AppToast`, `AppEmptyState`, `AppErrorState`, badges); no local duplicates (rule 15).
5. **Interaction** — every interactive element ≥ 48 dp and has a Semantics label (rule 16); pressed/disabled states visible; **destructive actions confirm** (remove member, delete zone, forget data, end session).
6. **Feedback** — one toast system (`AppToast`); feedback text says what happened and where ("saved on this device").
7. **Tokens** — colours, radii, shadows only from tokens (rule 14); no `Colors.white`/hex literals.
8. **Prototype residue = FAIL** if any of:
   - fake numerals or names that are not bound to data (rule 23);
   - decorative cards that look tappable and lead nowhere;
   - controls that do nothing or fake a selection;
   - the same honesty banner repeated more than once on one screen;
   - awkward toasts (success claimed for something that did not happen);
   - technical / debug language (Native, Remote, FCM, MOCK, IDs like `child_3fa2`);
   - inconsistent mock presentation (demo data without the LOCAL_DEMO banner, or banner without demo data).

## 6. UX standard (seven questions per screen)

| Step | Question the user must be able to answer | FAIL example |
|---|---|---|
| **Understand** | What is this screen for? | Title is a registry name or a code. |
| **Orient** | Whose data (which child/family/device) and how fresh? | No child name on a per-child tool. |
| **Decide** | What can I do and what will it change? | Toggle with no consequence text. |
| **Act** | Can I do it in one obvious step? | Primary action hidden in overflow. |
| **Confirm** | Do I see what happened? | Silent save; toast claims device enforcement. |
| **Recover** | Can I undo / retry / get out? | Error with no retry; Back leaves the app. |
| **Continue** | Is the next step obvious? | Dead end after success. |

## 7. Honesty standard (applies to every layer)

- Capability class shown matches reality: REAL_LOCAL · LOCAL_DEMO · NATIVE_CLOSED · REMOTE_CLOSED.
- Closed capabilities: control may **save a preference** but must never claim enforcement/delivery.
- Honesty text is **human language** (OD-02 glossary), one line, not repeated; child tone on child screens.
- No debug, network, or file-system code in `app/lib` (FVX-G-01).

## 8. Control completeness standard (per system)

For each of the 42 systems, check these ten properties and record PASS/FAIL/N-A/BLOCKED/OD:

| Property | Question |
|---|---|
| Configure | Can the right parent set it up? |
| Operate | Can it be used day-to-day (turn on/off, run)? |
| Adjust | Can values be changed later without redoing setup? |
| Exceptions | Are exceptions/overrides possible (extra time, allow-list)? |
| Scope | Is it clearly per-child / per-family / per-device, and the right one? |
| RBAC | Owner / father / mother level / child restrictions correct (RoleGuard + level)? |
| State | Is current state visible (on/off, remaining, last change)? |
| Review | Is there history / log of what changed? |
| Recovery | Can a mistake be undone or reset? |
| Consequence | Does the UI say what the control does — and honestly what it does not do yet? |

**Trace** each control: Capability → Domain/Policy owner → Service (S-xxx) → Control surface → Screen → User action → Result/State (and, for loops, the child-side reflection).
**Flag** controls that are: missing · duplicated (two places change one value) · misplaced (per-child control on a global hub) · no-consequence (saves nothing) · native-implying (claims enforcement) · wrong-role.
System-level results are recorded in `FINAL_VISUAL_UX_JOURNEY_MATRIX.md §5`.

## 9. Journey audit standard (all 73 journeys)

Walk each journey: **Entry → Context → Action → Decision → Result → Feedback → Next → Recovery**.

Mandatory checks:
- `childId` / family / device context preserved at each hop (route query or resolver) — ties to L1.
- Back behaviour returns to the previous screen (drill-downs use `push`).
- No dead ends (every success has a Next).
- No misleading success (toast matches what really happened).
- Father↔child loops close: parent action → local state → child screen reflects it (same device, role switch via SHR-008), e.g. JRN-FAT-15 ↔ JRN-CHD-06 (time request), JRN-FAT-34 ↔ JRN-CHD-13 (friend approval), JRN-FAT-35 ↔ JRN-CHD-14 (Quran).
Journey results are recorded in `FINAL_VISUAL_UX_JOURNEY_MATRIX.md §3`.

## 10. Dashboard and system-home audit

**Dashboard (FAT-010, CHD-004):** Orient (who is where, how is each child — honest demo banner) → Prioritize (pending decisions: time requests, app approvals, friend requests, learning results, SOS) → Act (one tap to the decision, with child context) → Drill down (profile / system home, Back returns to Today). Last-synced line per G-1 in honest local wording.

**System homes:** each home shows (a) current state summary, (b) the one primary action, (c) links to its control surfaces with context, (d) empty/error/loading designed states, (e) honest capability line once.

## 11. State audit

Each screen is checked for the states it can reach: **loading · empty · one item · many items · error · offline · stale · pending · success · unavailable · native-closed · remote-closed**. Empty/error use SHR-006/SHR-005 components; loading uses a shared component (to be added — FVX-G-14). Unreachable states are NOT APPLICABLE with a one-word reason.

## 12. Local reality audit

Check, per system: production singleton bound at boot (`main.dart` `tryBindStage1…`) or still an empty in-memory default · duplicate authorities (two repos holding one fact) · screen-local mutable state used as persistence · silent memory fallback when SQLite/KV fails · copy that implies durability it does not have · stale projections (dashboard vs source) · parent/child divergence (different child IDs — FVX-G-03). Known unbound defaults: conversations, conversation, child chats, alerts hub/detail, call history/active call, location map/history, child profile (roster fallback), device-user switch, rules-engine rules.

## 13. Arabic/RTL (rendered) and device audit

**Rendered Arabic/RTL (screenshot per screen, 360 dp + 412 dp, font scale 1.0 and 1.3):**
- Direction: text, icons (chevrons, arrows), progress bars, sliders, steppers, swipe directions mirror correctly.
- Numerals: one system per OD-05; dates/times localized; units ("د", "س") placed correctly.
- No English leakage (labels, badges, rule titles, hub names); grammar/gender agreement correct.
- Mixed-direction strings (Arabic + URL/number/brand) don't scramble.
- If OD-01 enables English: same screens in EN (LTR) — alignment literals and FAB placement re-checked.

**Device checklist (physical Android phone, one pass per batch + final):**
1. Cold start → welcome → login → Today loads without errors, no debug files/requests.
2. Tab switching; Back from every drill-down returns to origin.
3. Keyboard: forms (add child, safe zone, event, task) are not covered; submit reachable.
4. Touch: small links (login forgot/invite), chips, stepper buttons hit reliably.
5. Kill & relaunch: settings, roster, tasks, time requests persist (Local claims).
6. Role switch (SHR-008) father → child: father's change is reflected on child screens.
7. SOS from child and parent: alert shows the correct person.
8. Outdoors glance test for secondary text contrast (OD-03).
9. Small (≤ 360 dp) and large phone: map illustrations, hub strip, FABs don't overlap content.

## 14. Finding classification and fix decision tree

Scope: **GLOBAL / SYSTEM / SCREEN**. Nature: **CONTROL · UX · VISUAL · NAVIGATION · STATE · DATA · HONESTY · RTL · DEVICE · NATIVE_CLOSED · REMOTE_CLOSED · OWNER_DECISION**.

Decision tree (apply in order; stop at the first "yes"):
1. Is there an explicit Owner decision / Register rule that covers it? → apply it (KEEP + REFINE).
2. Is a product policy needed and missing? → **OWNER_DECISION** (list; do not guess).
3. Does the proper fix need native? → **NATIVE_CLOSED** (verify the honest closed state instead).
4. Does it need backend/remote? → **REMOTE_CLOSED** (verify honest closed state).
5. Does an existing Local capability already exist but isn't bound? → **bind it** (no new authority).
6. Is a control missing for an existing local capability? → add the smallest control on the existing surface.
7. Is it a UX flow problem? → UX fix (copy, order, feedback, navigation).
8. Is it visual only? → visual fix via shared component/token.
9. Otherwise → **NO ACTION** (record why).
Add **HONESTY** to any finding where the UI claims a capability that does not exist.
Prefer **shared → system → screen**: if the same defect appears on ≥ 3 screens, fix the shared cause once.

## 15. Evidence standard

| Claim | Minimum evidence |
|---|---|
| Code fact | file:line in the finding |
| Behaviour PASS | focused widget/unit test name + command + result recorded in `.verify/VX-*.json` |
| Visual PASS | screenshot (golden or device) referenced by screen ID, both 360 dp and 412 dp |
| RTL PASS | Arabic rendered screenshot; EN only if OD-01 |
| Device PASS | device checklist row with date, device model, Android version, tester |
| Loop PASS | test that writes on parent side and reads on child side with the same resolver |
| Honesty PASS | ARB diff + rendered screenshot showing the human wording |

`.verify/VX-*.json` shape: `{ "card": "VX-B2-CONTEXT", "status": "passed", "tier": "focused", "commands": [...], "results": [...], "screens": [...], "findings_closed": [...], "date": "…" }`.

## 16. Regression protection

- **Before any shared change** (shell, component, resolver, ARB key rename): list affected surfaces via grep (component usages / route users) in the batch notes.
- Run the **representative screen tests** for each affected system (at least one per system touched), plus existing CE-B0→B5 tests (they are the regression net for prior closures).
- New tests are **guard tests** where possible (e.g., "no `HttpClient` in `lib/`", "every PERCHILD route forwards `childId`", "no English-only ARB value in `app_ar.arb` outside allow-list").
- Owner-locked Q-CEX-001..004 behaviour must be unchanged — their tests are in every batch's regression list.

## 17. Test-speed policy

- Default: `flutter analyze` on touched files + **focused** tests for touched features and the guard tests.
- Broad (`flutter test` full) only at: end of VX-B4 (shared layer), before FINAL DEVICE PASS, and at FINAL CERTIFICATION.
- Never use skip flags to pass a gate.

## 18. Owner test-gate protocol

1. Cursor prepares the focused tests and states: exact command (run from `app/`), what it proves, expected result.
2. Owner runs the command (or authorizes Cursor to run it).
3. **PASS** → record `.verify/VX-*.json`, one line in `CONVERSION_LOG.md`, update the matrix cells to PASS.
4. **FAIL** → stop the batch, fix, reissue the same command; never proceed on a failing gate.
5. Device gates follow the §13 checklist; Owner (or delegate) signs the device row.

## 19. Final re-audit and Final Product Gate criteria

The gate PASSES only when all ten areas PASS (or are BLOCKED-NATIVE/REMOTE with a passing honest state, or OWNER-DECISION explicitly deferred by the Owner):

| Area | PASS condition |
|---|---|
| UX | Every live screen passes the seven UX questions. |
| Control | 42 systems: no no-consequence, duplicate, misplaced or wrong-role controls. |
| Local | No unbound empty default on a surface that claims local data; no silent fallback claims. |
| Visual | All screens pass §5 on rendered screenshots; zero prototype residue. |
| Journeys | 73 journeys pass Entry→Recovery; father↔child loops close. |
| States | Reachable states designed on every screen. |
| Arabic/RTL | Rendered pass clean; numerals consistent; no English leakage. |
| Honesty | Human wording; no false success; no debug code. |
| Device | Device checklist PASS on at least one small and one normal Android phone. |
| Evidence | `.verify/VX-*.json` for every batch + final; matrix fully resolved (no PENDING). |

## 20. STOP rule

After FINAL FRONTEND CERTIFICATION: **STOP**. No new visual campaign, no VX-B8+, no native/backend start without a new Owner `CHANGE PHASE`. Residual items go to QUESTIONS.md (policy) or GAP_LOG.md (deferred), never silently into new batches.

## 21. Model / reasoning strategy

- **Strongest reasoning model** for: this audit design, context-spine changes (L1), shared-component changes (L2), cross-system loop tests, re-audit, and every gate review.
- **Lighter/faster models** only for mechanical, fully specified work: ARB wording application from an approved glossary, colour-literal → token mapping, SnackBar → AppToast replacement, chevron swaps — always followed by a strong-model diff review.
- Subagents may parallelize read-only inventory by system group; synthesis and verdicts stay with one reviewer.
