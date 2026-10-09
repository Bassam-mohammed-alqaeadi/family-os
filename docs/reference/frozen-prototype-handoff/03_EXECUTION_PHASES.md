# Execution Phases F0 → F7 (each with an owner gate)
(Source: doc 43 §3. No phase opens before the previous gate is signed by the owner — same governance as the polish stations.)

| Phase | Scope | Inspectable output | Gate |
|:-:|---|---|---|
| **F0 · Foundation** | Flutter project + Cursor constitution in `.cursor/rules/` + `tokens.dart` (literal port of 06) + the 10 core components (Btn/Card/RowTile/Tag/Banner/Prog/Sheet/Toast/Tabs/HubGrid) + ARB skeleton + CI checks | An app showing a "component gallery" in both themes (parent / child) | Owner: does it look like the prototype? |
| **F1 · Backbone** | Router generated from `screens.csv` (129 placeholder routes) + RoleGuard + tab shells (5 parent / 4 child) + family state providers + mock family (Register §10) | Full navigation across 129 skeletons | Owner navigation tour |
| **F2 · Policy engine** | `core/policy/`: Register §1 (Minutes, five channels) + §2 (time rulings A/B/C/D) + §3 (smart modes) — **a unit test per constitutional clause** | 100% coverage on `policy/` | Test report |
| **F3 · Father's first journey** | System n01 linking (FAT-001→007) + today dashboard FAT-010 + children list + child profile **parametric** (opens for Khaled, Noura, Saad) | Scenarios S1+S2 (05_ACCEPTANCE_SCENARIOS) run on device | Owner walks it |
| **F4 · Management tools** | Systems 9–23 (per-child tools, screen time, filtering, instant lock, time requests) + **ios_reality badges live** | S3 + Android/iOS capability matrix visible | Owner walks it |
| **F5 · Child's world** | All 37 CHD screens: my-day, learning, Quran, minutes wallet, focus⇄sounds loop, SOS (long-press), gentle time-expiry | S4 complete on device | Owner lives it as Khaled |
| **F6 · Intelligence & edges** | Family Advisor (suggest→approve) + reports + subscription/privacy/audit/router screens + double-confirm wipe | S5 complete | Owner walks it |
| **F7 · Hardening** | i18n audit (zero hardcoded strings) + a11y (full screen-reader pass) + performance (60fps mid-range device) + golden tests for critical screens | Readiness report + "Gulf beta" decision | 🏁 |

**Ordering law**: F2 before ANY screen with rewards — no UI is written before its law is tested.

## CI — the seven prototype checks become permanent
| Prototype check | Flutter CI mirror |
|---|---|
| Render 129/129 | Test pumps every route; asserts build without exception |
| Zero dead destinations | Static check: every push target exists in the route table |
| Zero deaf buttons | Widget test per screen: every interactive element has a non-null action |
| Minutes only | Type check: no raw int in reward APIs + grep bans "points/XP" |
| Five channels alive | `policy/` §1 tests |
| Design-token discipline | Custom lint: no raw `Color` in features |
| Role guarding | Test: child role on owner routes ⇒ redirect |
| **+ two new** | Zero hardcoded strings (ARB) · zero child names outside `mock/` |

## First three task cards (ready to paste into Cursor)

### CARD F0-A — Design tokens
> Create `lib/core/design/tokens.dart` porting EXACTLY the values in `handoff/06_DESIGN_TOKENS.md` (colors, shadows, gradients, radii, fonts). Expose them via ThemeExtension. Build a `GalleryScreen` that swatches every token. Constitution rules 14, 18 apply. Acceptance: visual diff vs prototype screenshots of the same colors.

### CARD F0-B — The ten components
> In `lib/core/design/components/`, implement: PrimaryBtn (variants: primary/teal/sec/ghost/coral), AppCard, RowTile (icon+title+subtitle+trailing), Tag (g/t/p/a variants), Banner (t/p/a), ProgressBar, BottomSheetHost, AppToast, TabsBar (parent 5 / child 4), HubGrid (tcard grid). Match the prototype's `.btn/.card/.row/.tag/.banner/.prog/.tabs/.tgrid` CSS behavior 1:1 (padding, radius, shadow, press states). Constitution rules 14–17. Acceptance: gallery screen renders all variants in both themes; widget tests prove every variant taps.

### CARD F1-A — Route generation + RoleGuard
> Write `tool/gen_routes.dart` that reads `_REGISTRY/screens.csv` and generates `lib/app/router.dart` with 129 typed routes (placeholder screens showing ID+title). Implement `RoleGuard` as a go_router redirect: child role is blocked from owner screens (subscription/billing/privacy/audit) exactly as rule 8. Acceptance: the CI "render 129/129" and "role guarding" tests pass.
