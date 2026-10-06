# Current execution plan — Global Super App, system by system

> **Status:** Live programme authority — 2026-10-07.
>
> **Direction:** The Global Super-App Constitution in [`../AGENTS.md`](../AGENTS.md) is binding. Family OS preserves the prototype's user promise, then builds the real engine behind it with PostgreSQL, **Node.js/Express**, Native Android services where required, and Flutter.
>
> **Global Launch Master Plan:** [`GLOBAL_LAUNCH_MASTER_PLAN.md`](GLOBAL_LAUNCH_MASTER_PLAN.md) is the execution master plan from now to launch (approved 2026-10-05 by Owner + technical partner; **comprehensive 12-section edition completed 2026-10-05**). It fixes: AI last but prepared from day one (on-device light + cloud subscription via gateway), global market from Arabic to worldwide, cloud from temporary Render to full production, pricing deferred, and target ≥$4M ARR in 2028. It now contains the full **42-system map grouped into 11 delivery waves (M0–M10)**, the detailed 2026 Q4 → 2028 Q2 schedule with per-wave exit criteria, the 10-week per-system cadence, a 9-item risk matrix, monthly cost projections, and the 7-point launch gate. This plan (`CURRENT_EXECUTION_PLAN.md`) remains the live pointer for the active system.
>
> **Active system:** **Family Entry & Children Control** — selected 2026-10-04; Cover remains governing design authority. The create-child slice is implemented, and the owner admitted the M0-locking **server-authoritative Child Context Read Model + PermissionSnapshot v1** slice on 2026-10-07.
>
> **This document:** selects the current system and its stage. Historical Foundation, staging and discovery material remains evidence, not a competing roadmap.

## 1. Product operating model

```text
Prototype user promise
→ competitive and UX-gap analysis
→ coherent control-centre / journey design
→ PostgreSQL + Node.js/Express contracts and authorization
→ Native capability where the system needs it
→ Flutter with truthful states
→ quality, privacy, accessibility and device evidence
→ lock the system, then select the next one
```

A successful endpoint, mock interaction, screen render or CI run is never the definition of a complete system. A polished system lets every relevant family member complete a meaningful job with truthful state, clear recovery and familiar navigation.

## 2. Current programme position

| Area | Current fact | Role in the active system |
|---|---|---|
| Global product direction | Global Super App / system-by-system delivery | Governs the product destination and work order. |
| Prototype | Rich UX promise and comparison baseline | Retain its user value; replace mock engines rather than deleting valuable flows. |
| Foundation backend | PostgreSQL-backed Node.js/Express family, membership and child-roster foundation | Reusable starting point, not the limit of product scope. |
| Connected roster, creation and Child Context vertical slices | Server-authoritative roster and child creation plus the active narrow Child Context + PermissionSnapshot v1 read model | M0 truth is bounded to identity, durable setup facts and expiring presentation permissions; it is not device health, policy or location authority. |
| Children parity audit | [`foundation/22_CHILDREN_CONTROL_CENTRE_PRODUCT_PARITY_AUDIT.md`](foundation/22_CHILDREN_CONTROL_CENTRE_PRODUCT_PARITY_AUDIT.md) | Completed Compare/Gaps input for the active system. |
| Cover specification and capability admission | [`real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md`](real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md) and [`real_platform/03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](real_platform/03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md) | Governing system design plus the exact admitted implementation boundary. |
| Native/device capabilities | Not yet implemented as real product capability | Added only when the admitted capability needs device evidence. |
| Production/public release | Not authorized by this plan | Requires separate release, operations, privacy and support evidence. |

## 3. Active system — Family Entry & Children Control

Family Entry & Children Control is the first Global Super-App system. It progresses through **Compare → Cover → Compete → Real Engine → Polish → Lock** before unrelated systems open.

It was selected first because it establishes real family, guardian and child context reused by every other system; its prototype-to-real gaps are already mapped; and its Node.js/Express backend has a safe starting point for roster truth and a narrow child-profile creation contract.

The system outcome is **not** merely a child list:

```text
Authorized sign-in
→ family selection or real family setup
→ child roster / honest empty setup state
→ authorised child-profile lifecycle
→ child context with truthful setup and repair states
→ role-aware control-centre entry points
```

Device telemetry, policy enforcement, location and AI remain separate subsequent capabilities unless their source, consent, authorization and verification lifecycle is explicitly admitted to this system.

## 4. Current stage — M0 lock with bounded Child Context read implementation

| Stage | Status | Required output |
|---|---|---|
| Compare | Complete | Prototype-to-real parity audit and source inventory. |
| Cover | **Governing specification complete** | [`real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md`](real_platform/02_FAMILY_ENTRY_AND_CHILDREN_CONTROL_COVER_SPECIFICATION.md): role journeys, information architecture, state matrix and source map. |
| Compete | Complete for the admitted M0 read surface | One coherent, narrow child identity/setup presentation without prototype claims. |
| Real engine | **Active for Child Context + PermissionSnapshot v1** | PostgreSQL-backed tenant-isolated Express read, expiring server-derived presentation permissions, typed Flutter source/runtime and strict response validation. |
| Polish and lock | **Active final M0 gate** | Production SCR-FAT-013 truth integration, AR/EN, RTL/LTR, accessibility, responsive quality, denial/session/network/service/invalid-response recovery and controlled evidence. |

## 5. Non-negotiable delivery rules

- A prototype control is either made real with its complete lifecycle or remains clearly unavailable; it must not impersonate a working capability.
- A user-visible fact never comes from a hidden mock, seeded family, local role selection or fabricated success path.
- Every sensitive mutation has server authorization, validation, idempotency where needed, durable state, audit/result visibility and failure/recovery handling.
- Native Android work is capability-specific. It is not added to a system that does not need it, and it is never implied by a Flutter toggle.
- The main app may not silently combine remote facts with legacy local/mock repositories.
- Every system ships Arabic and English, RTL and LTR, responsive and accessible experiences as part of the slice—not as a later visual task.
- Existing Foundation evidence, contracts and archives are retained. New strategy changes their place in the hierarchy, not the truth of what occurred.

## 6. Immediate operation — lock M0 Child Context truth

The product owner admitted **Server-authoritative Child Context Read Model + PermissionSnapshot v1** on 2026-10-07 as the final bounded read slice before M1 device completion.

1. Implement `GET /v1/families/{familyId}/children/{childId}/context` as a PostgreSQL-backed, bearer-authorized, tenant-isolated read with primary/co-guardian access and child/unrelated-principal denial.
2. Derive only durable setup facts and an expiring server-owned PermissionSnapshot v1. Permission presentation never replaces authorization on a later request.
3. Compose a strict typed remote Flutter source through `AppRuntime`; preserve explicit not-found, denial, invalid-session, service, network, invalid-response and unavailable states with recovery.
4. Route production `SCR-FAT-013` only to that source. Show child identity and confirmed device setup; omit battery, health, location, policies, tools and all other facts absent from the response.
5. Complete backend contract/authorization/isolation/store evidence and Flutter parser/runtime/widget/route evidence, including AR/EN, RTL/LTR, accessibility and responsive presentation. Native work is not required for this read model.

M1 Devices may proceed only after this M0 gate is merged and its CI evidence is green. Day Board remains deferred to M8; no public release claim follows from this slice.
