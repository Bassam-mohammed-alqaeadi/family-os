# Device Telemetry & Nervous System — Phase 1 acceptance

## Scope and truth boundary

This acceptance validated **linked child devices plus their latest stored battery/location fact**. It did **not** validate Android background GPS, device attestation, an always-on child-agent, or location history. The owner has accepted Phase 1 after a verified Staging run.

## One comprehensive live acceptance run

Use four **distinct, short-lived synthetic Firebase/OIDC user tokens**. Do not paste tokens into tickets, terminal recordings, or repository files.

1. Deploy the Node/Express service with `007_device_telemetry.sql` applied and wait for `/health/ready` to return `200`.
2. In `backend`, run the API/evidence portion below. It creates an isolated synthetic family and child, so it never needs a production family ID:

   ```bash
   export STAGING_BASE_URL='https://your-node-api.example'
   export STAGING_PRIMARY_GUARDIAN_TOKEN='…'
   export STAGING_CO_GUARDIAN_TOKEN='…'
   export STAGING_CHILD_TOKEN='…'
   export STAGING_UNRELATED_TOKEN='…'
   npm run verify:staging:device-telemetry
   ```

   Pass criteria: command exits `0` and prints all check names plus opaque server correlation IDs. It must not print bearer tokens or decoded subjects.
3. The Phase 1 Flutter rendering was verified against the same authenticated Staging family during the owner acceptance run.

4. Phase 1 has been accepted after the owner-completed Staging verification. The temporary developer injector was removed from the production Flutter codebase after acceptance; it is not a valid acceptance path for any later phase.
5. Phase 2 native telemetry must use the real child-device pairing and Android foreground-service path instead of any injected location or battery data.

## API cases covered by the one run

| Test item | Expected result |
| --- | --- |
| Migration/readiness | Schema manifest includes migration 007; protected device operations run only when readiness is true. |
| Link device | Active primary guardian receives `201`; linked record initially has null latest telemetry. |
| Link idempotency | Same key/body returns the original device; same key/different label returns `409 idempotency_key_reused`. |
| Ingest latest telemetry | Primary guardian receives `200`; battery `78`, status `unplugged`, label `Soccer Practice`, coordinates, and `lastSeenAt` are stored. |
| Guardian read | Primary guardian and co-guardian receive the same family-scoped latest device record. |
| Write authority | Co-guardian cannot ingest (`403 family_access_denied`) in this deliberately narrow Phase 1 design. |
| Read authority | Child membership gets `403 device_telemetry_access_denied`; unrelated principal gets `403 family_access_denied`. |
| Audit/outbox evidence | Exactly one correlated `family.child_device_linked` event and exactly one correlated `family.device_telemetry_received` event exist. |
| Flutter real-read rendering | The card renders remote `GET /v1/families/{familyId}/devices` facts; it does not invent battery/location before a response exists. |
| Production data boundary | No developer telemetry injector remains in Flutter production code; Phase 2 uses a real paired-device capability. |

## Repeatable local checks

```bash
cd backend
npm ci
npm run check
npm test

# When Flutter SDK is available:
cd ../app
flutter format lib/foundation_gate/family_device_api_client.dart \
  lib/foundation_gate/main_app_foundation_runtime.dart \
  lib/foundation_gate/foundation_gate_configuration.dart \
  lib/core/runtime/family_device_source.dart \
  lib/features/n02_day/children_list_screen.dart \
  lib/main.dart \
  test/foundation_gate/family_device_api_client_test.dart \
  test/foundation_gate/main_app_foundation_runtime_test.dart
flutter analyze
flutter test test/foundation_gate/family_device_api_client_test.dart \
  test/foundation_gate/main_app_foundation_runtime_test.dart
```
