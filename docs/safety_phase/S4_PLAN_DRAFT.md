# Stage S4 Plan Draft: Live Map & Truthful Location Stream

> **Governance Guard**:
> Stage S4 implementation is strictly gated until Stages S0–S3 are verified and signed off by the owner (**Taha**).
> **No implementation code is written or committed for Stage S4 in this turn.**

---

## 1. Scope & Objective

Stage S4 delivers an honest, live family location map for the guardian interface (`SCR-FAT-014`) and child profile view:
1. **Eliminate Synthetic Origin Fallback**: Permanently remove hardcoded geographic fallbacks (the duplicated Riyadh coordinate `24.7136` in `location_server_authority.dart` and `location_ux_bridge.dart`).
2. **Honest Map Experience**: Integrate interactive mapping (Google Maps SDK for Flutter) with an explicit degraded schematic view (`CapabilityHonestyBadge`) if an API key is unconfigured. Production never fakes a map when keys or network are absent.
3. **Read-Time Freshness & Accuracy**:
   - Location freshness is computed at read time (`now() - fix.recorded_at`) rather than in-memory tick intervals, ensuring accuracy across server sleep cycles (e.g., Render free tier idling).
   - Display humanized Arabic/English freshness badges (e.g., «منذ ٣ دقائق» / "3m ago") and accuracy circles when GPS accuracy is degraded (> 50m).
4. **Realtime Hints**: Provide live updates over `/v1/realtime` using lightweight family-scoped **hints only** (announcing a new fix is available without broadcasting raw geographic coordinates over plain socket envelopes). The client fetches the signed fix via authenticated HTTPS.
5. **On-Demand Location Ping**: Guardian can request an immediate coordinate fix; the backend dispatches a high-priority spine command/push to wake the child handset's native service.
6. **Consent Enforcement**: If child location consent has been withdrawn, the guardian map transitions to an explanatory state linking directly to `SCR-CHD-003` (Prominent Disclosure) rather than showing a generic network failure.

---

## 2. Technical Risks & Mitigation

| Risk | Impact | Mitigation Strategy |
|---|---|---|
| **Render Free Tier Dormancy** | First location request after 15 min idle takes up to 60s; timers drift | Freshness state is evaluated purely at read-time against server-stamped UTC clock (`ServerTimeOffset`); UI displays truthful loading skeleton rather than timeout crash. |
| **Google Maps Billing / API Keys** | Missing API key could crash map widget or breach policy | Built-in fallback to a high-contrast schematic card showing truthful text coordinates, accuracy radius, and "الخرائط غير مُعَدّة" badge without crashing. |
| **Child Battery Exhaustion** | Constant GPS tracking drains battery | Rely on native `ResilientFixQueue` adaptive intervals; on-demand active GPS pings are throttled to a minimum interval of 60 seconds per child. |
| **Privacy Leak in Socket Payloads** | Raw coordinates exposed in transit | `/v1/realtime` socket transmits solely `{ "event": "location_available", "child_id": "...", "timestamp": "..." }`. Coordinates are retrieved exclusively via authenticated HTTPS `GET /v1/devices/{id}/latest-fix`. |
| **Widget Test Regressions** | Rewriting map breaks existing test harness | All existing `LocationMapKeys` widget keys and accessibility semantics must be preserved verbatim. |

---

## 3. Protected Systems Affected

The S4 implementation touches the following registered systems from `docs/safety_phase/PROTECTED_SYSTEMS.json`:

1. **`w2_child_device_lifecycle`**:
   - Files: `app/lib/foundation_gate/native_child_telemetry_bridge.dart`, `backend/src/location-telemetry.js`.
   - Impact: Integration of on-demand ping handler and verification of native fix ingestion.
2. **`w2_w3_child_consents`**:
   - Files: `backend/src/child-consents.js`, `app/lib/core/policy/child_consents.dart`.
   - Impact: Map query endpoint must enforce that active `location` consent exists before returning points.
3. **`w3_location_retention_erasure`**:
   - Files: `backend/src/data-erasure.js`, `backend/migrations/116_location_retention_erasure.sql`.
   - Impact: Map markers must filter out points older than 90 days or marked as erased.
4. **`s1_notification_delivery`**:
   - Files: `backend/src/notification-dispatcher.js`.
   - Impact: Outbox dispatcher used for high-priority location request push.
5. **`app_shell_and_gate`**:
   - Files: `app/lib/app/router.dart`, `app/test/app/router_routes_test.dart`.
   - Impact: Routing to `SCR-FAT-014` must maintain active route coverage without regressions into placeholder widgets.

---

## 4. Required Contract & Registry Changes

Before any implementation code is modified for S4:
1. **Document Change in `docs/safety_phase/CONTRACT_CHANGES.md`**:
   - Add entry detailing modifications to `location_server_authority.dart` and `SCR-FAT-014`.
2. **Update `docs/contracts/w2_child_device_lifecycle.md`**:
   - Add Invariant: *"Live map coordinates are strictly sourced from verified server fixes and never fall back to hardcoded geographic coordinates (Riyadh constant elimination)."*
3. **Run Pre-Push Harness**:
   - Execute `node tools/harness/check_protected.mjs` to ensure zero undocumented diffs in protected system files.

---

## 5. Execution Preconditions (Stop Gate)

Implementation of S4 shall **NOT** commence until:
- [ ] Owner completes verification of baseline F1 items on `emulator-5554` and `emulator-5556`.
- [ ] Owner completes and signs off Stage S1–S3 smoke checks in `docs/harness/EMULATOR_RUNBOOK.md`.
- [ ] Owner decides on Maps provider configuration (API key provision vs. degraded schematic mode).
