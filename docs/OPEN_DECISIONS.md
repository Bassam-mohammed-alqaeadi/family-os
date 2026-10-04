# Open decisions and external blockers

> **Status:** Current only — 2026-10-04.
>
> **Authority:** [`../AGENTS.md`](../AGENTS.md) and [`CURRENT_EXECUTION_PLAN.md`](CURRENT_EXECUTION_PLAN.md). Historical Foundation decisions remain evidence, but do not replace the active system plan.

## 1. Resolved portfolio decision — active system selected

**Family Entry & Children Control** was selected on 2026-10-04 as the first Global Super-App system. It now progresses through **Compare → Cover → Compete → Real Engine → Polish → Lock** before unrelated systems open.

The Cover specification is [`real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md`](real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md). It preserves the prototype's full control-centre promise while making every capability conditional on a real source and lifecycle.

Device/Screen Time, Learning & Minutes, Family Connection, and Safety/Location/SOS remain sequenced after this system unless an explicit portfolio decision changes the order.

## 2. Resolved capability admission — create child profile

The product owner admitted **primary-guardian create child profile** for real implementation on 2026-10-04. The exact name-and-age-only contract, ownership and recovery boundary are in [`real_platform/03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](real_platform/03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md).

| Resolved item | Binding boundary |
|---|---|
| Mutation | `POST /v1/families/{familyId}/children`; only `displayName` and `ageYears`; bearer principal and idempotency key required. |
| Authorization | Node.js/Express verifies primary-guardian scope. Flutter role data controls only action visibility. |
| Result | Server `201` is required, then Flutter reloads the roster. Audit/outbox remain backend-owned. |
| Fault handling | Validation, unauthenticated, denied, conflict, service/network and roster-refresh failure are intentional states without raw error data or local success. |
| Exclusions | No child detail/edit/delete, device/policy/location/AI/provider capability, default-route migration or release admission. |

## 3. Remaining decisions after this vertical slice

| Decision | Why it matters | Cannot be inferred from prototype/UI |
|---|---|---|
| Child detail/control-centre admission | Needs an authorized read model, source/freshness and repair story | A roster card or route name |
| Edit/delete profile admission | Needs lifecycle, safeguarding, conflict/reversal, audit and role policy | The existence of create |
| Native capability admission | Required for device links, enforcement, GPS, background services or applied/verified receipts | A Flutter toggle or local device record |
| Provider admission | Required for AI, voice, image, maps, messaging or other external providers | A prototype label, source badge or generated-looking result |
| Release admission | Required for real data, production, public/beta access, operations and support | Passing CI or a synthetic staging run |

## 4. Retained Foundation evidence and protected verification

The Node.js/Express/PostgreSQL Foundation and controlled synthetic roster evidence remain valid technical inputs. They do not prove a market-ready Children Control Centre or admit unrelated system work.

| Item | Owner/role | Boundary |
|---|---|---|
| Foundation staging and isolated roster evidence | Preserve as technical evidence | No secrets, raw payloads, identifiers or production claim. |
| Local protected configuration and synthetic emulator checks | Owner-operated when an admitted capability needs them | Never commit/paste configuration, identities, tokens, URLs or screenshots containing data. |
| Children parity audit and Cover specification | Product/design input | Define what must become real and the exact exit gate before implementation. |

## 5. Not decisions to bypass

- Do not use a mock, local role fallback or fixed sample state to make a production capability appear available.
- Do not start unrelated systems while Family Entry & Children Control is incomplete.
- Do not treat a narrow backend endpoint as permission to expose the entire prototype as connected.
- Do not expose or request secrets, raw family data or sensitive diagnostic payloads.
