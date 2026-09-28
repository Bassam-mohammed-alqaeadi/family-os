# Administration, Trust & Operations Evidence Map — ADMIN-G1-DISCOVERY

> **Status:** Evidence baseline complete; product decisions are documented in G1 direction.
> **Inspected:** 2026-09-29
> **Purpose:** Separate existing Flutter administration UI/local-domain seams from real account, membership, device, entitlement, notification, privacy, support and cross-device runtime behaviour.

## 1. Evidence rules

| Label | Meaning |
|---|---|
| **Observed UI/domain evidence** | A Flutter screen, model, repository seam, local runtime or policy is present in the repository. |
| **Observed local persistence** | A local preference/SQLite/in-memory adapter may survive some app restarts; it is not remote identity, family synchronization, payment, device truth or delivery proof. |
| **Not evidenced** | The inspected repository does not demonstrate the production integration required for the behaviour. |
| **Product decision** | Registry/status/screen existence does not decide the V2 release position. |

## 2. Current technical reality

- The Flutter app is explicitly mock-first and exposes onboarding, identity/family, child/device linking, device health, Today, notification preferences, privacy/data, audit, billing and language/help surfaces.
- Core/runtime code uses local SQLite/preference/in-memory style adapters, local projection/repository seams and test fixtures. Several UI comments explicitly name Stage-1, local, mock or no-Firebase behavior.
- `SetupWizardScreen` stores cached onboarding flags locally and intentionally permits skipping. It does not establish a remote account/family/device setup.
- `DayBoardScreen` obtains a local/mock projection and visibly includes local-demo/offline/error seams; its cards are useful UX evidence but not an authoritative family summary.
- Device-health screens subscribe to a Stage-1 seam and label local demo conditions. They do not prove device attestation, heartbeat, permission health, remote pairing or repair.
- Notification preferences use local key-value storage; existing in-process sync buses simulate updates. They do not prove push registration, channel delivery, quiet-hour enforcement, notification read or emergency receipt.
- Privacy/data UI models local collection preferences, local advisor-memory forget and a local lifecycle/wipe flow. They do not prove Render retention, export, cross-device deletion, provider propagation or durable production audit.
- Billing screens use an in-memory entitlement service. No App Store/Google Play/web payment SDK, receipt verification, Render entitlement, tax/currency, restore-purchase or refund integration was found.
- No production HTTP, Firebase Auth/Firestore/Cloud Messaging, remote support/ticketing, payment, QR/device-attestation, camera scan or account-recovery integration was evidenced in Flutter source. Existing comments that mention Firebase explicitly state absence or future work.
- Flutter tests were not run because the SDK is intentionally not installed in this workspace; test files are source evidence only.

## 3. System-by-system evidence

| System | Observed UI/domain evidence | Current truth gap |
|---|---|---|
| Initial setup | Shared welcome/login/account/device-mode screens; `n01_linking` family creation, child add, setup wizard, QR, permissions explainer, trial and onboarding-progress seams. | Production auth/recovery/verification, account/family creation, QR/code issuance/expiry, real device enrollment, cross-device resume, consent/terms/versioning and truthful initial-value receipt. |
| Family and members | Identity runtime/context, family-members screen/repository/mock, adult-invite and mother-permission repositories/screens, local user switch and role guard seams. | Render membership/ownership, invitation delivery/acceptance/expiry, role changes/conflicts, alternative guardian/recovery, age/consent lifecycle and cross-family isolation. |
| Devices | Link/QR screens, child-device management seam, device-health list/detail/seam, local identity context and health repair UX. | Device registration/ownership proof, attestation, secure pairing, remote heartbeat/capability/permission reporting, lost/replaced/unlink lifecycle and native platform connection. |
| Subscription and billing | Plans and manage-subscription screens; entitlement model/service; owner-only view and safety-not-gated wording. | Storefront/web checkout, server receipt validation, trial/renewal/refund/restore, pricing/tax/currency, Render entitlement, account/platform reconciliation, support/refund operations. |
| Notifications | Notification preference screen/model/repository; family alert catalogue; quiet hours, summary and urgency UI; local in-process policy seams. | Render recipient/priority orchestration, device token lifecycle, approved FCM transport, delivery/open/action receipts, retry/expiry/deduplication and emergency escalation contract. |
| Privacy and data | Privacy/data, child “what is collected,” audit screens/models/local persistence; collection policy, data lifecycle and advisor-memory concepts. | Render data inventory/purpose/consent/retention, actual access/export/delete/forget jobs, multi-store/provider propagation, durable audit/support controls and legal/region policy. |
| Today dashboard | Parent/child day boards, projection models/local seeds, priority/pending/advisor routes, child list/profile integration. | Render-authoritative aggregation/ranking, role/permission/relevance, source freshness, dismissal/defer synchronization, delivery truth and no-data family state. |
| Settings and support | Settings Hub, language/help screen/models/repository, localization/locale controller and shared empty/network templates. | Hosted/localized help-content lifecycle, support case/request channel, status/diagnostics consent, response SLA/availability, account-safe recovery and cross-device preference synchronization. |

## 4. Shared foundation evidence

| Foundation | Observed evidence | Discovery implication |
|---|---|---|
| Role and identity | `sys3_identity`, `identity_runtime`, `identity_scope`, role guards, family/member/permission local repositories. | Valuable vocabulary/UI for V2; not server-enforced membership or recovery. Legacy father/mother naming cannot become a V2 hard-coded authority model. |
| Setup/linking | Wizard/progress flags, create family/child, QR, transparency/permission screens, camera-permission seam. | Preserve progressive/truthful onboarding posture; replace local/mock pairing success with verified lifecycle later. |
| Day/Tabs | Day board and child board projections; cross-pillar routing to safety, learning, connection and advisor surfaces. | Today can be the shared front door only when it consumes authorized, source-qualified platform states. |
| Notification language | Preference structures, alert catalogue, urgency/quiet/digest UI and local buses. | The product has a clear attention-design foundation but no actual transport/orchestrator. |
| Privacy/audit | Collection scopes, family data lifecycle, audit logs and child transparency UI. | Strong intent foundation; must be generalized to Render, sources, providers, export/delete propagation and least-privilege support. |
| Billing/entitlement | Plan, trial and owner-only management UI with an in-memory service. | Commercial UX exists but no real purchase/receipt/entitlement truth. |
| Localization/help | Arabic/English localizations, locale controller and language/help surfaces. | Arabic-first/global UX foundation exists; help/support content and account recovery need real operations design. |

## 5. Journey reconciliation

Four registered administration services lack a registered journey:

| Service | G1 reconciliation direction |
|---|---|
| `S-ADM-012` — package-based graduated limits | Merge into child-add/family capacity and subscription-change journeys. A plan limit cannot silently block a child/device or be a static entitlement label. |
| `S-ADM-013` — alternate guardian | Add a recovery/guardian-continuity journey: proposal, verification, acceptance, role scope, primary-guardian absence/revocation and audit. |
| `S-ADM-033` — intelligence control panel | Merge into the approved Intelligence Source & Scope Desk. Existing brain-control mock/flag UI is not an independent administration capability. |
| `S-ADM-035` — child “what is collected” | Merge explicitly into the child transparency journey with `S-ADM-004`; it must explain actual enabled categories/source/capability rather than static labels. |

## 6. Discovery implications

1. Administration surfaces contain a large share of the app’s trust UX, but nearly every visible cross-device, payment, delivery or recovery outcome is local/mock evidence rather than a production capability.
2. Initial setup, members, devices, privacy, notifications, Today and support are not separate utilities; they form the shared platform contract on which Security, Learning, Connection and Intelligence depend.
3. Existing gender-specific father/mother/child UI and permission code is implementation evidence, not a governing V2 role policy. The final model must use an explicit primary-guardian/co-guardian/child authority system with localized presentation.
4. A demo must be clearly marked, isolated from production family state and unable to generate false alerts/insights/receipts. It is a learn-before-link route, not a synthetic family claim.
5. Billing is a trust and continuity flow, not merely a paywall. It requires honest entitlement/receipt states and must preserve critical safety, privacy and recovery paths.
6. Administration G2 must unify these surfaces into a coherent Trust Hub/Today/Settings architecture and prevent duplicated hidden settings across prior pillars.
