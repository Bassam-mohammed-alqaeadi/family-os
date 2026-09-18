# Cursor Constitution — 22 Absolute Rules
**Any violation = the task is rejected and redone. No exceptions.**
(Source: doc 43 §2, owner-approved. Mirror this file into `.cursor/rules/constitution.mdc` of the Flutter repo.)

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

## E · Workflow Constitution
19. **One task = one system (or one screen).** "Convert ten screens at once" is forbidden. Each task card provides: system number, screen list, original HTML snippet, relevant policy clauses.
20. Every task ends with: code + green tests + one line in `CONVERSION_LOG.md` (screen ID, commitments honored, any declared deviation).
21. Cursor MUST NOT modify: `core/policy/`, `tokens.dart`, `.cursor/rules/` — changes there require a logged owner decision.
22. Any commit touching more than one feature is rejected (except `core/` under an explicitly declared task).
