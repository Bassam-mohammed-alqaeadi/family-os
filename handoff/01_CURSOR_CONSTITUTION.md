# Cursor Constitution — 24 Absolute Rules
**Any violation = the task is rejected and redone. No exceptions.**
(Source: doc 43 §2, owner-approved; amended 2026-09-18 with rules 23–24 by logged owner decision. Mirror this file into `.cursor/rules/constitution.mdc` of the Flutter repo.)

## A · Authority & Boundaries
1. **Single source of truth**: `family_os_app.html` (frozen v1.0) + `04_POLICY_REGISTER_EN.md` + `_REGISTRY/screens.csv` + `_CONTRACTS/schema.sql`. **No design improvisation**: every screen is ported as-is — text, order, and behavior.
2. On ambiguity or conflict: **STOP and ASK**. Write the question in `QUESTIONS.md` and halt the task. Guessing is a violation.
3. Never generate screens or features outside the registry (exactly 129 screens). Never resurrect cancelled items: OTP flows, the old green v1 design, the two-app model, the role-picker screen (SCR-SHR-004).

## B · Economy Constitution (highest sanctity)
4. The ONLY currency is **minutes**. The `Minutes` value object is mandatory — raw `int` for any reward/balance/request is FORBIDDEN. No "points", "coins", or "XP" in any string, variable, or comment.
5. The five earning channels (tasks, Quran, learning, challenges, gifts) flow EXCLUSIVELY through `PolicyEngine.earn()` — direct balance writes are forbidden.
6. The father sets the reward value at task creation — no hidden defaults.

## C · Sovereignty & Safety Constitution
7. All intelligence **suggests, never executes** — every AI action ends with a parent-approval button.
8. Role guarding happens ONLY via `RoleGuard` in the router (no scattered `if` checks). Owner-only screens: subscription, billing, privacy, audit log.
9. SOS button, location, and family chat: **never depend on subscription, never disabled**. Any code gating them behind a plan is rejected.
10. Audit log is append-only: its repository interface must not even contain `update`/`delete` methods.
11. Time expiry NEVER locks: family chat, Quran, SOS.

## D · Code Constitution
12. No user-facing string literals inside Widgets — **all texts come from ARB files** (Arabic is the source `app_ar.arb`; `app_en.arb` mirrors the keys). The `check_hardcoded_strings` CI script rejects violating PRs.
13. No child names hardcoded outside `mock/` — every child screen is a function of `ChildId` (parametric contract).
14. Colors, shadows, radii come from `tokens.dart` ONLY — raw `Color(0x…)` inside features is forbidden.
15. Every new visual component goes into `core/design/components/` once — duplicating a local button/card is forbidden.
16. `Semantics` label on every interactive element. Touch targets ≥ 48dp.
17. Every feature ships with: unit tests for logic + a widget test proving (a) it renders, (b) **every button has a working action**, (c) loop closure (toast / state change / navigation — no screen may pretend nothing happened).
18. `flutter analyze` with zero warnings + `dart format` before every commit.

## D2 · Data & Completeness Laws
23. **DATA DYNAMISM LAW**
Every value displayed in the frozen prototype is a SAMPLE RENDERING, never content. The prototype's mock data (names, streaks like "9 days", counts like "12 devices", notification cards, wallet balances, chart figures) exists only to show what a populated UI looks like. Therefore:
- Every displayed value binds to state/providers/repositories — zero hardcoded display data inside widgets.
- Every screen renders its FULL state range: empty, loading, one item, many items, error — not just the prototype's happy snapshot (SHR-005/006 templates define the look).
- Notifications seen in the prototype define notification TYPES and appearance — each must be emitted by a real event pipeline, never planted statically.
- The mock family (Register §10) lives exclusively in `mock/` repositories behind the same Repository interfaces the real backend will implement. Deleting `mock/` must leave the app compiling and functional.
- CI/review flag: widget code containing literal numerals/names mirroring prototype sample values.

24. **GAP-CLOSING MANDATE (settings completeness & loop closure)**
The prototype is the visual/behavioral reference, but some settings in the father and child dashboards are visually complete while functionally shallow. When converting any screen you MUST:
- Make every setting REAL: every toggle/slider/choice binds to state, persists, and is enforced through `core/policy/` (a switch that changes nothing is a violation).
- Close every loop: every principal action produces visible feedback (toast/state change/navigation) AND its downstream effect actually occurs (e.g., approving a time request must deposit minutes via PolicyEngine and reflect on the child's side).
- Detect and record: any incomplete setting, dead-end, or unclosed circle you discover goes into `GAP_LOG.md` (screen ID, gap, proposed closure). Close it within the task if it's within the screen's scope and consistent with the Policy Register; otherwise flag it for the owner in QUESTIONS.md.
- Additive only: closures never remove or alter frozen behavior; they complete it. All closures follow the design tokens and the Policy Register (supreme law).

## E · Workflow Constitution
19. **One task = one system (or one screen).** "Convert ten screens at once" is forbidden. Each task card provides: system number, screen list, original HTML snippet, relevant policy clauses.
20. Every task ends with: code + green tests + one line in `CONVERSION_LOG.md` (screen ID, commitments honored, any declared deviation).
21. Cursor MUST NOT modify: `core/policy/`, `tokens.dart`, `.cursor/rules/` — changes there require a logged owner decision.
22. Any commit touching more than one feature is rejected (except `core/` under an explicitly declared task).
