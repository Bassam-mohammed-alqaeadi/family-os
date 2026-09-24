# Verify tiers — Q-VERIFY-TIERED (2026-09-22)

Owner-approved speed/quality balance for P9 ship gate.

## Modes

| Mode | When | What runs |
|---|---|---|
| **scoped** | Default on ships 1–2 of each cycle | `flutter analyze` + feature tests + shared seams (`router_routes`, `role_guard`) |
| **full** | Every **3rd** ship (`FOS_VERIFY_FULL_EVERY`, default 3); end of wake; `--full`; Phase 1.5 / merge / Stage 3 | `flutter analyze` + entire `flutter test` |

`--skip-test` remains an emergency analyze-only escape — **not** a normal ship path.

## CLI

```bash
python .cursor/hooks/verify_ship.py verify              # auto tier
python .cursor/hooks/verify_ship.py verify --scoped     # force scoped
python .cursor/hooks/verify_ship.py verify --full       # force full
python .cursor/hooks/verify_ship.py check               # predicate + tier counter
```

Env:

- `FOS_VERIFY_MODE=scoped|full` — override auto
- `FOS_VERIFY_FULL_EVERY=3` — full cadence
- `FOS_VERIFY_TIMEOUT_SCOPED=180` / `…_TEST=480` / `…_ANALYZE=240`

## Scope resolution

1. Optional map: `.verify/scope_map.json` → `{ "SCR-CHD-023": ["test/features/..."] }`
2. Parse `*Screen` names from the newest `CONVERSION_LOG` summary → `*_test.dart`
3. Always add shared seams when present
4. If no feature test found → **safe escalate to full**

## Counter

`.verify/_tier_state.json` tracks `ships_since_full`. Full verify resets to `0`.

## Hard full gates (agents must pass `--full`)

- Entering **Phase 1.5** UX completeness gate
- Opening a **merge PR** to main
- Starting any **Stage 3** card

## Quality note

Scoped ships can miss cross-feature regressions until the next full. Cadence ≤2 ships of exposure. Do not weaken pillars P1–P12 or skip widget tests for the card itself.
