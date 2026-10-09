# Administration, Trust & Operations Data & Event Contracts — Gate G3

> **Status:** Product-readiness technical design complete
> **Purpose:** Define authoritative Render contracts for the shared family platform spine. No API, remote store, payment, notification transport or device enrollment is implemented by this document.

## 1. Canonical lineage

```text
Account → verified session/recovery posture
        → Family → membership/role → child relationship → device relationship
                                      │
           setup / consent / capability / preference / entitlement / data request
                                      │
  source-domain event → Today/notification/audit/support projection → user recovery/outcome
```

Every administration record carries a family context when it relates to a family, an authorized actor, version/times, visibility/retention classification and causal/audit links. Account identity alone never establishes family access.

## 2. Canonical entities

| Entity | Required contract |
|---|---|
| Account | `accountId`, verified identity references, locale/accessibility preference, status, session/recovery metadata references and deletion lifecycle; no plaintext credential/secrets in product records. |
| Family | `familyId`, lifecycle, display metadata, primary-guardian continuity reference, locale/timezone baseline, privacy/retention policy version and audit links. |
| Membership | `membershipId`, account/family, role, explicit child/domain/action scope, status, effective period, invitation/recovery origin, author/version and audit. |
| ChildProfile | `childId`, family relationship, age/communication profile, guardian authority links, visibility/consent policy references and lifecycle. |
| Invitation / RecoveryCase | Intended family/role/scope, sender, secure token/reference, expiry, verification/acceptance/decline/revoke/dispute state and audit. |
| GuardianContinuity | Primary/alternate relationship, eligibility, trigger conditions, verification, activation/pause/revocation/expiry and recovery audit. |
| SetupTask | Family/account context, task type/version, purpose, required authority/capability, state, source proof, deferred/resume and completion/limitation reason. |
| ConsentRecord | Purpose, subject, policy/terms version, authority/acknowledgement type, time, scope, expiry/revocation and evidence reference. |
| ManagedDevice | `deviceId`, account/device credential reference, family/child assignment, platform/app/version, enrollment lifecycle, integrity/last-seen state and audit. |
| CapabilityEvidence | Device/feature, capability state, observed/received time, source/integrity/quality, version/permission prerequisites, expiry and remediation link. |
| DeviceHealthEvidence | Device component/status, source, freshness, observed time, severity, repair status and user-visible explanation reference. |
| TodayItem | Projection reference to an authorized source event/state, family/viewer scope, relevance/priority/freshness, display lifecycle, owning-domain route and audit. |
| NotificationPreference | Member/family/domain scope, category/urgency/channel/quiet/digest/fatigue settings, timezone, effective/pending state, author/version and audit. |
| NotificationAttempt | Underlying event reference, recipient/device endpoint, channel, minimised payload class, queue/attempt/receipt/open/action/fail/expiry state and audit. |
| DataInventoryItem | Purpose, category/source/store/processor, subject/family scope, visibility, retention class, current use and data-lifecycle policy reference. |
| DataRequest | Access/export/correction/forget/delete type, requester/authority, target scope, impact preview, eligibility, job/progression/status, retention-limited result and audit. |
| AuditEvent | Append-only actor/action/resource/before-after reference/outcome/time/correlation/visibility/retention record. |
| ProductCatalogSnapshot | Provider/store/region/currency/tax/disclosure version, eligible products/offers and display validity period; not an entitlement. |
| PurchaseReference | Provider/store transaction reference/token hash, account/family link, product, observed/verified times, raw state, reconciliation id and fraud/replay status. |
| Entitlement | Family/account scope, product/capability/limit, provider verification basis, lifecycle/effective times, source receipt version and audit. |
| SupportCase | Requester/family/resource reference, category, permitted diagnostic/attachment references, consent, state, assigned/response timestamps, resolution/reopen and audit. |

## 3. Family and authority contracts

### Membership lifecycle

```text
Draft → validated → invitation/recovery request sent
→ verified → accepted → active
           ↘ declined | expired | revoked | failed | disputed
→ paused / scope changed / removed / recovered
```

```text
Membership
- membershipId, accountId, familyId, role
- childScope[], domainScope[], actionScope[]
- status, authorityBasis, initiatedBy, effectiveFrom/Until?
- invitationId?/recoveryCaseId?/continuityId?
- version, createdAt, updatedAt, auditId
```

Rules:

- A server-side authorization decision evaluates active membership plus explicit scope; client role text and invitation possession are insufficient.
- Changes are versioned and idempotent. A revoke/removal immediately constrains future reads/mutations while allowed audit/retention follows policy.
- An invitation accepts into its original, still-valid scope only; acceptance cannot upgrade the role or add children/domains.
- Primary-guardian continuity uses a separate record and policy, never an ordinary `Membership.role` update.

### Setup task contract

```text
SetupTask
- taskId, familyId?/accountId?, type, version, affected childId?/deviceId?
- requirement: optional | capability-required | policy-required
- status: not_started | in_progress | pending_verification | complete | limited | deferred | failed | recovery_needed
- evidenceReferences[], reasonCode?, resumeRoute, completedAt?
- createdAt, updatedAt, auditId
```

A task is `complete` only when its stated evidence is authoritative. UI visitation, local preference write or request dispatch cannot independently satisfy it.

## 4. Device and capability contracts

### Enrollment lifecycle

```text
Unlinked → pairing initiated → code/identity/authority validation
→ registered → capability assessed → active/current
                         ↘ limited | unsupported | attention needed
→ stale/offline → repair / replace / pause / unlink request
→ unlinked / replaced / recovery-needed
```

```text
ManagedDevice
- deviceId, credentialReference, familyId, childId?, ownerMembershipId?
- platform, appVersion, enrollmentState, assignmentVersion
- registeredAt?, lastSeenAt?, revokedAt?, replacedByDeviceId?
- capabilityProfileVersion, healthSummary, auditId

CapabilityEvidence
- evidenceId, deviceId, feature, state: supported | limited | unavailable | needs_setup | unknown
- reasonCode, observedAtDevice?, receivedAtRender, expiresAt?
- source: native_adapter | device_client | server_verification
- integrity: verified | reported | stale | rejected
- app/os/version/permission prerequisite references, auditId
```

A device feature becomes current only through non-expired capability/health evidence accepted for the device’s current family/child assignment. It cannot report a state for a device after credential revocation or reassignment.

## 5. Today, notification and activity contracts

### Source-to-Today relationship

```text
Authorized Security / Learning / Connection / Intelligence / Administration event
→ family/role/purpose/visibility/freshness evaluation
→ Today projection item | notification eligibility | activity/audit entry
→ viewer opens / defers / dismisses presentation
→ owning domain independently changes outcome
```

```text
TodayItem
- todayItemId, sourceDomain, sourceEventId/resourceId, familyId
- viewerScope, subjectScope, priority/relevance reason, freshness/dataQuality
- state: eligible | shown | opened | deferred | dismissed | expired | superseded | archived
- owningRoute/actionType?, createdAt, expiresAt?, auditId
```

Today visibility/action state does not mutate the underlying safety alert, task, report, device policy, support case or privacy request unless the owning domain has a separately authorized operation.

### Notification contract

```text
NotificationAttempt
- notificationId, sourceEventId, familyId, recipientMembershipId, endpointId?
- category, urgency, channel, payloadClassification/reference
- preferenceVersion, scheduledFor?, queuedAt?, attemptedAt?
- state: queued | attempted | provider_accepted | device_receipt? | opened? | actioned? | failed | expired | suppressed
- providerMessageReference?, failureReason?, retryOf?, auditId
```

- `provider_accepted`, `device_receipt`, `opened` and `actioned` are distinct optional facts, each accepted only when a supported channel reports them.
- They do not prove a guardian understood, accepted or resolved the underlying source event.
- A non-delivery/expired/suppressed state preserves an in-app source route and recovery where relevant.
- FCM registration token/endpoints are operational device data; they cannot be used as identity, membership authorization or family read state.

## 6. Privacy, audit and data-request contracts

```text
DataRequest
- requestId, type: access | export | correction | forget | delete
- requesterAccountId/membershipId, familyId, authorityScope
- target: dataInventoryItem/category/source/subject/time/store scope
- reason?, impactPreviewReference, retentionEligibility
- state: draft | review | accepted | queued | partial | completed | retention_limited | failed | retry_needed
- propagationTargets[], resultSummary, createdAt, resolvedAt?, auditId
```

Rules:

- A DataRequest is evaluated by authority, family/subject scope, purpose, retention/legal policy and downstream impact before work starts.
- Propagation targets name the eligible Render store/index/cache/provider/storage class without exposing secrets or other members’ data.
- `completed` means the recorded eligible targets completed; `retention_limited` identifies what remains and why. Local deletion confirmation is not this result.
- Audit metadata is minimally retained according to policy and does not defeat the purpose of forget/delete by retaining a hidden behavioural copy.

## 7. Catalog, purchase and entitlement contracts

```text
CatalogSnapshot
- catalogVersion, provider/store, region, currency/tax/disclosure context
- product/offer identifiers, eligibility/availability, fetchedAt, expiresAt

PurchaseReference
- purchaseId, provider/store, transactionReferenceHash, productId
- accountId/familyId?, observedAtClient?, receivedAtRender, verifiedAt?
- rawState: initiated | pending | purchased | cancelled | expired | refunded | restored | disputed
- verificationState: unverified | verified | rejected | replay | reconciliation_needed
- linkedPurchaseReference?, auditId

Entitlement
- entitlementId, familyId/accountId, productId, capability/limit scope
- state: pending | active | scheduled_change | grace | cancelled_active_until | expired | revoked | disputed
- effectiveFrom/Until?, verificationBasis, sourcePurchaseId, version, auditId
```

Rules:

- Flutter is permitted to report a provider/store result as `observedAtClient`; only Render verification/reconciliation may activate/evolve `Entitlement`.
- Pending/unverified/replayed/failed purchase references never unlock a capability.
- A product catalog is time/region/currency/disclosure-bound; pricing copied into design fixtures is never a production offer.
- Product limits must link to their entitlement/version and return an understandable alternative without blocking safety, privacy or recovery rights.

## 8. Support and audit event envelope

```text
AdministrationEvent
- eventId, eventType, schemaVersion, eventVersion
- accountId?, familyId?, membershipId?, childId?, deviceId?
- actorAccountId?/membershipId?, authorizationBasis
- resourceType/id, sourceDomain?, visibilityClass, retentionClass
- occurredAt, observedAt?, receivedAtRender, processedAt?
- sourceTrust: server_verified | device_reported | user_submitted | provider_reported | local_cache
- dataQuality: fresh | stale | partial | unavailable
- correlationId, causationId, idempotencyKey, auditId, traceId
```

Examples: family created, invitation accepted/expired, role scope changed, device enrolled/capability limited, setup task verified, Today item shown, notification suppressed/attempted, privacy request partial, export ready/expired, entitlement verified/expired, support case received/resolved, account deletion request initiated.

## 9. Contract acceptance checks

An Administration service is acceptable only when it proves: Render family/role/child/device authorization; durable/versioned/idempotent state; source/freshness/capability truth; invitation/recovery/revocation safety; device credential lifecycle; Today/notification separation from source outcome; governed data-request propagation; verified entitlement over client/store display; least-privilege support/audit; and explicit local/offline/demo limitation states.
