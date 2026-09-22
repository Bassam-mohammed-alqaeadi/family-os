# Skills map — right skill, right time

Orchestrator rule: **read the skill file before the matching step**. Do not load the entire library every tick.

Skills live under `C:\Users\bassa\.agents\skills\<name>\SKILL.md`.

## Active / soon (Stage 1 · F0)

| When | Skill | Card |
|---|---|---|
| Scaffold `app/` + folders | `flutter-app-architecture`, `architecture-feature-first`, `flutter-expert` | F0-0 |
| ARB / RTL day one | `flutter-setup-localization`, `inclusive-design` | F0-0 |
| Layout primitives | `flutter-use-column-row-first` | F0-0 gallery, F0-B |
| Analyze / format | `dart-run-static-analysis`, `effective-dart` | every Ship |
| Widget tests | `flutter-add-widget-test`, `flutter-testing` | F0-B+ (smoke only on F0-0) |
| A11y semantics | `accessibility` | gallery onward |
| Design polish | `flutter-improve-design`, `flutter-best-practices` | F0-A / F0-B |

## Later (do not load yet)

| When | Skill | Earliest |
|---|---|---|
| Riverpod | `flutter-riverpod-expert`, `riverpod` | F1 |
| go_router | `flutter-setup-declarative-routing` | F1 |
| Unit tests / TDD | `dart-add-unit-test`, `tdd`, `mocktail` | F2 policy |
| Integration / Patrol | `patrol-e2e-testing`, `flutter-add-integration-test` | F3+ scenarios |
| Store listing | `store-listing-assets` | F7 / Stage 4 |

## Forbidden until Stage 3+

| Skill family | Why |
|---|---|
| `firebase*`, `flutterfire-configure`, `firebase-ai` | Mock-first · Rule 25 seam · backend is Stage 3 |
| `revenuecat-testing` | Billing Stage 3/4; SOS never gated |
| `bloc` | Architecture locks Riverpod, not BLoC |

## GapClose / settings (owner priority 2026-09-20)

| When | Skill / doc | Card |
|---|---|---|
| Any SET-* or settings UI | `harness/10_COMPETITIVE_LENS.md` + P11 in `07_COMPLETENESS_AND_LOOPS.md` | SET-001…024, UI-008…010 |
| Control type wrong | ControlFit workflow in `03_WORKFLOWS.md` | replaces unfit toggle/label |
| Spec authority | `docs/project-plan/08-gap-closure-specs.md` | every SET |

## Harness tick reminder

Before spawning Builder on a card, Orchestrator checks this map and lists which skills the Builder must read.
