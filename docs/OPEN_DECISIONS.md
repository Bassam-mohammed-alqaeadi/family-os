# Open decisions and external blockers

> **Status:** Current only. Historical questions and completed campaign backlogs are preserved in [`archive/`](archive/).

## No code-policy decision is currently open

The approved Foundation/Children Roster source work is complete and its narrow staging procedure is documented. The remaining blockers are intentionally external and must not be bypassed in code.

## Controlled staging prerequisites

| Item | Owner | Why it blocks the live evidence | Prohibited workaround |
|---|---|---|---|
| Isolated synthetic Render web service and PostgreSQL environment | Staging Owner | The release must target a known synthetic-only service and database. | Using a legacy, customer or production resource. |
| Protected OIDC configuration and four fresh synthetic principals | Staging Owner | The verifier proves role boundaries only with real signed synthetic identities. | Checking tokens, subjects, emails or project identifiers into source/evidence. |
| Short-lived protected migration/readonly database access | Staging Owner | Migration `005` and durable audit/outbox confirmation require controlled database access. | Startup migrations, public `0.0.0.0/0` access, CI migrations or direct history edits. |
| Minimal operator evidence record | Staging Owner | Prevents a source/CI result being mistaken for live staging fact. | Retaining URLs, tokens, IDs, payloads, database values or logs. |

The operating procedure is [`foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md`](foundation/17_CHILDREN_ROSTER_STAGING_RELEASE.md). These are execution prerequisites, not a request to expand scope.

## Explicitly deferred pending separate authorization

- Flutter connection to the roster API or any remote-authoritative user-facing claim.
- A second Flutter/API read, broader client behaviour, provider/Firebase expansion or real-data testing.
- Device registration, policy delivery/enforcement, GPS/location truth, recovery/support operations and production/public release.

See [`CURRENT_EXECUTION_PLAN.md`](CURRENT_EXECUTION_PLAN.md) and [`product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md`](product_refinement_v2/92_EXECUTION_AUTHORIZATION_GATE.md).
