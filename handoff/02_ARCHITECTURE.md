# Architecture Decision — Feature-First + Riverpod + Offline-First
(Source: doc 43 §1, ADR-031. Binding.)

## Stack & why (reasoned from THIS product, not fashion)
| Layer | Choice | Why for this product specifically |
|---|---|---|
| State | **Riverpod 2** (with codegen) | The app is "one family state" branching into dozens of screens (like `S` in the prototype): derived providers, precise rebuilds, context-free testability. BLoC = too much ceremony for a small team; GetX rejected by governance (hidden magic). |
| Folder structure | **Feature-First** (`features/nXX_<system>/`) | Our 54 audited systems are the natural units of work. Each sealed system in the audit board becomes one feature folder with the same number — system→code traceability stays literal. |
| Local DB | **Drift** (SQLite) | Offline-first is constitutional (Policy Register §9). `_CONTRACTS/schema.sql` already exists; Drift ports it with type safety, and Stream APIs mirror "last synced family state". |
| Sync | Local op-queue; server merge later | First code milestone has NO real backend (mock repos), but **Repository interfaces are written from day one** so Mock → API swap never touches UI. |
| Navigation | **go_router** (typed) | 129 screens need a route table GENERATED from `screens.csv`; role guards (rule 8) implement as `redirect`. |
| Models | **freezed** + json_serializable | Immutability prevents "state mutation by stealth" — literally our economy law. |
| i18n | flutter_localizations + **ARB from line one** | Rule 12. Arabic first, RTL default, English skeleton filled later. Cost today ≈ 0; retrofitting after a year ≈ rewrite. |
| Accessibility | Mandatory `Semantics` | Rule 16; enforced by widget tests. |
| One app or two? | **ONE app, role-based** | Frozen decision (two-app model cancelled). Child experience = same code, different theme+role (`child-ui` in prototype). |

## Mandatory project structure
```
family_os/
├─ .cursor/rules/            ← constitution.mdc (mirror of 01_CURSOR_CONSTITUTION.md)
├─ lib/
│  ├─ core/
│  │  ├─ design/             ← tokens.dart (06_DESIGN_TOKENS.md, literal) · components/ (Btn, Card, RowTile, Tag, Banner, Prog, Sheet, Toast, Tabs, HubGrid)
│  │  ├─ domain/             ← value types: Minutes (NOT raw int), ChildId, Role, TrustLevel
│  │  ├─ policy/             ← policy_engine.dart — Register §1–§9 as pure, unit-tested functions
│  │  ├─ platform/           ← ios_reality.dart: declared capability table per tool (full / reports-only / unavailable)
│  │  ├─ compliance/         ← age×region consent matrix — schema ready even if dormant
│  │  └─ i18n/               ← app_ar.arb (source) + app_en.arb (skeleton)
│  ├─ features/
│  │  ├─ n01_linking/        ← system 1 (FAT-001..007, CHD-001..003)
│  │  ├─ n08_home_network/   ← … one folder per audited system, numbered like the audit board
│  │  └─ …
│  ├─ app/                   ← router.dart (GENERATED from screens.csv) · role_guard.dart · shell (parent 5 tabs / child 4 tabs)
│  └─ mock/                  ← reference family (Register §10): Abdullah (father), Nawal (mother), Khaled 14, Noura 11, Saad 8 + mock repos
├─ test/                     ← CI mirrors of the seven prototype checks (see 03 §CI)
└─ tool/                     ← gen_routes.dart · check_hardcoded_strings.dart · check_minutes_type.dart
```

## Where each global gap is closed structurally (from doc 42)
| Gap | Structural closure |
|---|---|
| G8 Parametric contract | Child screens take `ChildId`; CI rejects child names outside `mock/`. Preview must work for Khaled(14), Noura(11), Saad(8). |
| G2 Language | ARB from day one (above). |
| G1 iOS reality | `core/platform/ios_reality.dart` — every tool screen reads it and renders the honesty badge (full on Android / reports-only on iOS) automatically. No promise the platform can't keep. |
| G5 Compliance (COPPA/GDPR-K) | Consent/age/region columns in the Drift schema from the FIRST table. Activation later, structure now. |
| G4 Sovereign emergencies | `SovereigntyRepository` interface (account recovery / ownership transfer) defined now as a contract; screens after the owner decision session. |
| G3 Two-household families | Out of scope for first code milestone; empty `guardianship` table reserved in schema. |
