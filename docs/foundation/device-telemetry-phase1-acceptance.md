# Device Telemetry & Nervous System — Phase 1 acceptance

## Scope and truth boundary

This acceptance validates **linked child devices plus their latest stored battery/location fact**. It does **not** validate Android background GPS, device attestation, an always-on child-agent, location history, or a claim that the developer simulator is a physical device.

The temporary simulator is compiled in only with `FAMILY_OS_ENABLE_DEVELOPER_TELEMETRY=true`; its device label and on-screen copy explicitly say that it is a developer simulation.

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
3. Start the Flutter app against the **same** API and an authenticated primary-guardian Firebase session. The developer-only seam is intentionally build-time gated:

   ```bash
   cd app
   flutter run \
     --dart-define=FAMILY_OS_API_ORIGIN=https://your-node-api.example \
     --dart-define=FAMILY_OS_ACTIVE_FAMILY_ID=<synthetic-family-id> \
     --dart-define=FAMILY_OS_ENABLE_DEVELOPER_TELEMETRY=true
   ```

4. Open the parent Children Control Centre, tap **Developer: Inject Telemetry**, then let the roster refresh. The temporary seam targets the first server-roster child; pass criteria for that child card:
   - location: `Soccer Practice`;
   - battery row/icon: `78% · unplugged`;
   - green health tag: `Healthy`;
   - developer copy remains visible and says this is **not child-device telemetry**.
5. Build/run again **without** `FAMILY_OS_ENABLE_DEVELOPER_TELEMETRY=true`. Pass criterion: neither the developer simulation copy nor its button appears.

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
| Developer seam | The injection call uses the real registration and telemetry routes, labels the source as simulated, and disappears from normal builds. |

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
