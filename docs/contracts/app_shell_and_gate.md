# Contract: App Shell & Foundation Gate (`app_shell_and_gate`)

## Scope
The App Shell and Foundation Gate govern application lifecycle bootstrapping, role-based navigation routing via `GoRouter`, authentication session orchestration, and staging environment harness integration. They guarantee that production and staging paths boot cleanly without silent mock fallbacks, that routes strictly adhere to the designated product screens catalogue, and that user credentials and role-specific permissions are cleanly isolated and preserved across app state lifecycles.

## Invariants
1. **Unconfigured Isolation**: Unauthenticated entry begins unconfigured with no hardcoded mocks, zero network access, and zero synthetic bypasses.
2. **Credential Clearing**: Authentication forms purge input fields immediately upon dispatch before initiating discovery calls.
3. **Role-Enforced Presentation**: Route navigation restricts views based on the active authenticated role (`father`, `mother`/`co_guardian`, `child`); co-guardians see read-only controls without access to child-addition or mutation flows.
4. **Catalogue Routing Completeness**: The route table comprehensively maps all active screen IDs without regressions into `PlaceholderScreen` or orphaned route definitions.
5. **Static Import Hygiene**: No forbidden, circular, or unregistered dependencies cross the boundary between Foundation Gate modules and the production application runtime.

## Owned Files
- `app/lib/main.dart`
- `app/lib/app/router.dart`
- `app/lib/core/runtime/app_runtime.dart`
- `app/lib/foundation_gate/main_app_foundation_runtime.dart`

## Enforcing Tests
- `app/test/foundation_gate/foundation_gate_app_test.dart`:
  - `tracked Foundation Gate entry starts unconfigured without network or legacy mock data`
  - `configured gate clears local form fields before discovery`
  - `guardian roster renders only server profile facts and no mutation action`
- `app/test/app/router_routes_test.dart`:
  - `generatedScreenIds covers every active CSV screen_id (no tombstones)`
  - `route table length matches active screens (+ gallery)`
  - `SCR catalog: live routes build real screens (zero PlaceholderScreen)`
- `tools/harness/check_dart_imports.mjs`:
  - static import guard enforcing zero unresolved or circular dependencies across Dart modules.

## Phone Evidence
- F1.1, F1.9 (emulator-verified on `emulator-5554` and `emulator-5556`).

## Change Rule
- Modifying `app/lib/main.dart` boot callbacks or `app/lib/app/router.dart` route guards requires green runs of `app/test/foundation_gate/foundation_gate_app_test.dart` and `app/test/app/router_routes_test.dart`.
- Any addition or deletion of routes must reflect an approved change to the screen catalog and requires owner confirmation.
