# Open decisions and external blockers

> **Status:** Current only — 2026-10-04.
>
> **Authority:** [`../AGENTS.md`](../AGENTS.md) and [`CURRENT_EXECUTION_PLAN.md`](CURRENT_EXECUTION_PLAN.md). Historical Foundation decisions remain evidence, but do not replace the active system plan.

## 1. Resolved portfolio decision — active system selected

**Family Entry & Children Control** was selected on 2026-10-04 as the first Global Super-App system. It now progresses through **Compare → Cover → Compete → Real Engine → Polish → Lock** before unrelated systems open.

The Cover specification is [`real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md`](real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md). It preserves the prototype's full control-centre promise while making every capability conditional on a real source and lifecycle.

Device/Screen Time, Learning & Minutes, Family Connection, and Safety/Location/SOS remain sequenced after this system unless an explicit portfolio decision changes the order.

## 2. Next capability-admission decision

| Decision | Why it matters | Cannot be inferred from prototype/UI |
|---|---|---|
| **Admit or reject primary-guardian create child profile** | It is the recommended first real capability: high user value, existing backend foundation, and no premature device/provider claim | Whether this mutation enters the active system now and its exact role/data boundary |
| Exact data and role contract | Defines source truth, visibility, authorization, audit and recovery | Child profile fields; primary/co-guardian/child experience; consent/retention rules |
| Native capability admission | Required for device links, enforcement, GPS, background services or applied/verified receipts | A Flutter toggle or local device record |
| Provider admission | Required for AI, voice, image, maps, messaging or other external providers | A prototype label, source badge or generated-looking result |
| Release admission | Required for real data, production, public/beta access, operations and support | Passing CI or a synthetic staging run |

## 3. Retained Foundation evidence and protected verification

The Node.js/Express/PostgreSQL Foundation and controlled synthetic roster evidence remain valid technical inputs. They do not prove a market-ready Children Control Centre or admit unrelated system work.

| Item | Owner/role | Boundary |
|---|---|---|
| Foundation staging and isolated roster evidence | Preserve as technical evidence | No secrets, raw payloads, identifiers or production claim. |
| Local protected configuration and synthetic emulator checks | Owner-operated when an admitted capability needs them | Never commit/paste configuration, identities, tokens, URLs or screenshots containing data. |
| Children parity audit and Cover specification | Product/design input | Define what must become real and the exact exit gate before implementation. |

## 4. Not decisions to bypass

- Do not use a mock, local role fallback or fixed sample state to make a production capability appear available.
- Do not start unrelated systems while Family Entry & Children Control is incomplete.
- Do not treat a narrow backend endpoint as permission to expose the entire prototype as connected.
- Do not expose or request secrets, raw family data or sensitive diagnostic payloads.
