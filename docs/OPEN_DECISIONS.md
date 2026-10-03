# Open decisions and external blockers

> **Status:** Current only. Historical questions and completed campaign backlogs are preserved in [`archive/`](archive/).

## Resolved current decision

The controlled synthetic Children Roster staging release passed on 2026-10-03. Its minimal evidence is preserved in [`foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md`](foundation/18_CHILDREN_ROSTER_STAGING_EXECUTION_EVIDENCE.md). The Owner separately authorized one isolated Flutter roster read, with no mutation or broader client expansion, in [`foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md).

## Remaining external verification boundary

No additional code-policy decision is open for the approved roster read. The following protected steps remain Owner-operated and must not be bypassed in source or CI:

| Item | Owner | Why it is required | Prohibited workaround |
|---|---|---|---|
| Local-only approved staging origin and Firebase Android client configuration | Owner | The isolated Android-emulator build needs controlled client metadata, never server credentials. | Committing, pasting, attaching or logging configuration/project values; using a database/Render-internal/localhost origin. |
| Synthetic Android-emulator roster verification after focused CI | Owner | Proves the client renders server truth and failure/denial states without retaining sensitive data. | Using a real account/family, screenshots/raw logs, physical-device distribution or CI-held credentials. |
| Minimal status-only emulator evidence and later synthetic-data cleanup decision | Owner | Preserves the current data-retention and traceability boundary. | Retaining identities, tokens, URLs, IDs, responses or diagnostic payloads in Git/chat/evidence. |

The exact implementation and evidence labels are in [`foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md`](foundation/19_FLUTTER_CONNECTED_CHILDREN_ROSTER_SLICE.md). These are protected verification prerequisites, not permission to expand scope.

## Explicitly deferred pending separate authorization

- Flutter roster mutations, a third Flutter/API read, default-app migration, broader client behaviour, provider/Firebase expansion or real-data testing.
- Device registration, policy delivery/enforcement, GPS/location truth, recovery/support operations and production/public release.

See [`CURRENT_EXECUTION_PLAN.md`](CURRENT_EXECUTION_PLAN.md) and [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md).
