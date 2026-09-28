# Administration, Trust & Operations Screen & State Map — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define the approved administration surface inventory before implementation. Existing Flutter onboarding, identity, device, Today, notification, privacy, audit, billing and help screens are evidence/candidates—not proof of remote family, device, payment, delivery or support capability.

## 1. Primary guardian surfaces

| ID | Surface | Primary job | Existing evidence relationship |
|---|---|---|---|
| P-ADM-01 | Welcome, Sign In & Recovery | Enter a real account safely, choose create/join/recover path and understand unauthenticated state. | `SCR-SHR-001` to `SCR-SHR-003`, `SCR-SHR-007` evidence; no production authentication/recovery yet. |
| P-ADM-02 | Family Entry & Setup Queue | Create/join/resume family setup and see each task’s real completion/limitation. | `SCR-FAT-001`, `SCR-FAT-002`, `SCR-FAT-007` onboarding/trial evidence. |
| P-ADM-03 | Add/Manage Child Context | Add or update a child under verified authority and understand member/device/data impact. | `SCR-FAT-003`, child list/profile evidence. |
| P-ADM-04 | Family & Members | See active/pending members, roles, children and family authority. | `SCR-FAT-027`, `n12_devices/family_members_*` evidence. |
| P-ADM-05 | Invitation & Role Review | Invite, preview, resend/revoke and resolve scoped co-guardian membership. | `SCR-FAT-008`, `SCR-FAT-009`, `SCR-FAT-031`, adult-invite/mother-level evidence. |
| P-ADM-06 | Guardian Continuity | Propose/manage alternate guardian and recover safely under explicit conditions. | New approved surface for `S-ADM-013`; no existing complete journey. |
| P-ADM-07 | Device Center | See child device lifecycle, feature-specific health/capability and actionable repair state. | `SCR-FAT-025`, device-health list evidence. |
| P-ADM-08 | Pair Device | Begin/cancel/retry secure pairing with child/device/permission/capability explanation. | `SCR-FAT-004`, linking/QR/permission screens evidence. |
| P-ADM-09 | Device Detail & Repair | Understand freshness, permissions, capability, replacement, pause or unlink lifecycle. | `SCR-FAT-026`, device-health detail evidence. |
| P-ADM-10 | Today | Understand real family context, one priority, decisions, people/day context and confirmed changes. | `SCR-FAT-010`, `n02_day/day_board_screen.dart` local projection evidence. |
| P-ADM-11 | Today Attention Queue | Resolve eligible requests, invite/device/privacy/support issues without generic alert counts. | Reconciles day pending/request inbox and alert surfaces. |
| P-ADM-12 | Notifications & Attention | Set role-scoped urgency, channel, quiet/digest and fatigue preferences with delivery truth. | `SCR-FAT-058`, notification prefs/alert catalogue evidence. |
| P-ADM-13 | Privacy & Data | Inspect/change authorized data scope and submit access/export/correction/forget/delete requests. | `SCR-FAT-059`, privacy-data evidence. |
| P-ADM-14 | Family Activity & Audit | Review permitted membership/device/policy/privacy/plan/support history and outcomes. | `SCR-FAT-060`, audit-log evidence. |
| P-ADM-15 | Plans & Eligibility | Understand genuinely available plans, limits, terms and trial/renewal implication. | `SCR-FAT-056`, plan screen evidence; fixture values are not commercial truth. |
| P-ADM-16 | Manage Subscription | Change/cancel/restore/review an actual entitlement with provider/receipt state. | `SCR-FAT-057`, in-memory entitlement screen evidence. |
| P-ADM-17 | Trust & Settings | Navigate platform-wide family, device, attention, data, plan, language, recovery and help controls. | Refines `SCR-FAT-025` settings hub and scattered settings routes. |
| P-ADM-18 | Language, Accessibility & Help | Change display/accessibility preferences, read localized help and initiate support safely. | `SCR-FAT-061`, language/help/localization evidence. |
| P-ADM-19 | Support Request & Status | Preview diagnostics, submit a real case and track truthful request state. | New organizing surface over help/support candidates; no live ticketing evidence. |

## 2. Co-guardian surfaces

Co-guardians use the same Trust & Settings architecture only within their explicit scope. They never receive a visually identical “full control” shell merely because they can open a shared screen.

| ID | Surface | Co-guardian job | Required boundary |
|---|---|---|---|
| CG-ADM-01 | Invitation & Role Preview | Understand exactly what membership grants before accepting. | No self-upgrade or hidden data preview. |
| CG-ADM-02 | My Today | See role-relevant priorities, family context and support actions. | No restricted child/private/primary-only source visibility. |
| CG-ADM-03 | My Notifications | Set personal attention preferences within emergency and family policy. | Does not alter another member’s preferences or source outcome. |
| CG-ADM-04 | Permitted Device Help | Repair/view only devices and capabilities explicitly delegated. | No ownership transfer/unlink/pair unless granted. |
| CG-ADM-05 | Shared Activity & Help | Understand relevant changes, seek help and route primary-only matters. | Audit is filtered; billing/recovery/privacy changes stay role-gated. |

## 3. Child-facing surfaces

| ID | Surface | Child job | Existing evidence relationship |
|---|---|---|---|
| C-ADM-01 | Join & Connection Explanation | Understand a guardian-initiated device link, permissions/data visibility and available help. | `SCR-CHD-001` to `SCR-CHD-003`, child QR/transparency evidence. |
| C-ADM-02 | My Day | See own real routines, responsibilities and available next actions in supportive language. | `SCR-CHD-004`, child day-board evidence. |
| C-ADM-03 | My Data & Transparency | See approved data categories/purpose/visibility and ask for clarification/help. | `SCR-CHD-010`, `S-ADM-035` evidence. |
| C-ADM-04 | My Device Help | Understand a visible device/permission limitation and ask a guardian for repair/support. | New child counterpart to device repair; no adult device controls. |
| C-ADM-05 | My Support Request | Ask for help with an app/family/device issue and see truthful submitted/response state. | New child-safe support route; never exposes account recovery, billing or adult diagnostics. |

## 4. Shared and capability-gated surfaces

| Surface | Current approved treatment |
|---|---|
| Isolated Demo / No-Data Preview | Clearly marked learning route with no real family/device/action/audit/entitlement state. It must not appear once an active real family context is selected. |
| QR / secure pairing | Approved surface only when a real code, identity match, expiry, device attestation and capability flow exist. Existing local QR UI remains evidence/preview. |
| Notification channel management | In-app preference UI may exist; individual push/email/etc. channel controls stay limited/unavailable until transport/consent/token lifecycle is real. |
| Purchase / trial / restore / refund | Available only after actual regional catalog, provider/store, receipt verification and Render entitlement reconciliation. Existing plan/entitlement UI cannot represent a completed purchase. |
| Export / delete / forget | Request/status UI must show limited/unavailable until the Render data inventory and propagation job exist. Existing local lifecycle cannot stand in for distributed data action. |
| Intelligence control panel | Merged into Intelligence Source & Scope Desk; local mock/flag controls cannot be exposed as production administration switches. |
| Human support status | Help content may be available when current; “submitted/received/resolved” case state appears only after a real support system exists. |

## 5. Mandatory states

Each applicable administration surface must handle:

- Unauthenticated, account recovering, no verified family, family switch/context loading, verified family, and clearly isolated demo/no-data states.
- Primary guardian, scoped co-guardian, child, pending invite/recovery, expired/revoked/removed membership and insufficient authority states.
- Setup not started, draft, in progress, pending verification, complete, deferred, limited, failed and recovery-needed states.
- Device unlinked, pairing, code expired, verifying, active/current, limited, permission-needed, stale/offline, unsupported, repairing, replacing, unlinking, unlinked and compromised/recovery-needed states.
- Today source-loading, empty/no eligible data, fresh/partial/stale/restricted source, actionable/attention/history-only, deferred/dismissed/expired/superseded item states.
- Notification preference draft/validation/saved/effective, channel unavailable/permission-needed, queued/attempted/client-receipt/open/action/failure/expiry/retry states where supported.
- Privacy scope enabled/pending/limited/disabled; export/delete/forget request draft/review/queued/partial/completed/retention-limited/failed/retry states.
- Entitlement catalog unavailable, trial eligible/active/ending, checkout/restore pending, verified active, change scheduled/effective, cancelled, failed, expired, refunded/disputed states.
- Help content loading/offline/outdated; diagnostic consent; support draft/submitted/queued/received/in-progress/resolved/closed/reopened/failed/unavailable states.
- Local/offline cache source/freshness/reconciliation status distinct from Render-authoritative state.

## 6. Screen reconciliation rule

Each existing administration surface is assigned later to **Retain, Refine, Merge, Defer or Retire** only with a closed journey and documented replacement:

- **Retain:** The surface already matches an approved job and can be hardened around real authority/source/lifecycle states.
- **Refine:** It retains its purpose but receives the G2 information architecture, role, truth and accessibility model.
- **Merge:** It moves under Today, Trust & Settings or an owning domain without breaking the user journey or hiding history.
- **Defer:** It remains registered but waits on a payment, transport, device, identity, support or data-lifecycle capability.
- **Retire:** It is removed only with an explicit replacement and decision.

Existing father/mother labels, local repositories, in-memory entitlement, local audit rows, local QR/progress or demo data do not determine the final V2 role model or prove a production capability.

## 7. G2 completion test

Administration UX is locked when every Core or capability-gated action has:

1. a guardian/co-guardian/child entry appropriate to authority and dignity;
2. family, role, child/device, purpose/consent and time/freshness context where relevant;
3. a truthful lifecycle from intent through verified/pending/failed/recovery outcome;
4. Today/notification/audit/privacy/support connection without duplicating domain ownership;
5. no-data/demo/local-cache state that cannot be mistaken for a real family result;
6. accessibility, RTL/LTR and global language/time/currency implications; and
7. an explicit unavailable/deferred state whenever authentication, pairing, delivery, export/delete, payment, entitlement, human support or remote truth is not implemented.
