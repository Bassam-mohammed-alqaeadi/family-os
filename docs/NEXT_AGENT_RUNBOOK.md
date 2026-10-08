# Next Agent Runbook (concise)

## Read first (in order)
1. `AGENTS.md`
2. `docs/00_MASTER_PLAN.md`
3. `docs/CURRENT_EXECUTION_PLAN.md`
4. `docs/RELEASE_READINESS.md`
5. `PROJECT_EXECUTION_PLAN.md`

## Current execution frame
- Active function/stage: see `docs/CURRENT_EXECUTION_PLAN.md` (live pointer only).
- Readiness/claims: see `docs/RELEASE_READINESS.md` (single readiness authority).

## Non-negotiable claim boundaries
- Do not claim production readiness.
- Do not claim native enforcement, push/SMS/call transport, outbox consumer processing, or public release unless code + tests in this branch prove it.
- Keep authorization server-owned; never promote client defaults into remote authority.

## Checks to run before reporting completion
- Backend:
  - `npm ci --prefix backend`
  - `npm run check --prefix backend`
  - `npm test --prefix backend`
- Flutter (targeted first, then broader only if needed):
  - `cd app && flutter pub get`
  - `cd app && flutter test test/foundation_gate/main_app_foundation_runtime_test.dart test/foundation_gate/family_creation_api_client_test.dart`

If PostgreSQL/remote infra is unavailable in the agent environment, state that explicitly; never claim those checks passed.

## Session close rule
- Save work using `engine-tools-report_progress` with checklist updates and commit pushes before ending the session.
