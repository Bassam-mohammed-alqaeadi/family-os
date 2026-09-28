# Recovery & Support Admission Packet

> **Status:** Architecture and operational admission package. **Recovery/Support code remains blocked.**
> **Prompt discipline:** Evaluated under `05_SYSTEM_OPERATING_PROMPT.md`.
> **Updated:** 2026-09-29
> **Decision reference:** `06_RECOVERY_SUPPORT_CASE_DISCOVERY.md`

## 1. Executive decision

The platform must not implement a recovery endpoint, support ticket, operator override, attachment upload, primary-guardian restoration, case status screen or Flutter recovery claim until the evidence in this packet has an accountable owner and an accepted operational answer.

This is not paperwork for its own sake. Recovery is the one flow an attacker will deliberately choose when they cannot authenticate, cannot join a family, or cannot obtain a role through ordinary authorization. An unowned recovery path is an access-takeover product feature.

### Decisions made now

| Decision | Result |
|---|---|
| Account identity recovery | Delegated to the approved identity issuer. Family OS may consume a newly verified principal only after it matches the issuer/audience/subject contract; it may not use support requests to mint or substitute identity. |
| Normal primary-guardian handover | Remains the existing two-party, expiry-bound transfer between an active primary guardian and active co-guardian. |
| Lost/absent/disputed primary guardian | Human-governed continuity-recovery policy required. There is no automatic role promotion, support override or client flow. |
| Support intake | Design only. Until operations exist, the application may offer static/public help but must not claim case submission, human review or response availability. |
| Sensitive evidence/documents | Prohibited from product storage and support intake until separate classification, legal/retention, access-control and deletion policy approval. |
| Firebase Admin credentials | Prohibited from identity recovery, family authorization, case operations and support access. |

## 2. Admission evidence register

An entry is *accepted* only when a named accountable owner, dated evidence source, decision version and review/expiry date are recorded outside a fixture or implementation comment. An Owner role must not be invented by the codebase.

| ID | Required evidence | Minimum accepted answer | Accountable owner required | Status |
|---|---|---|---|---|
| RS-ADM-01 | OIDC issuer selection | Exact issuer, audience, JWKS endpoint, issuer/sub stability, key rotation, revocation behavior and supported identity factors. | Identity/security owner | Open — blocks code. |
| RS-ADM-02 | Account recovery threat model | Lost device, credential compromise, changed email/factor, account merge, issuer outage, revocation and recovery-rate-limit behavior. | Identity/security owner | Open — blocks code. |
| RS-ADM-03 | Family continuity policy | Eligibility, alternate guardian pre-enrollment, absence/dispute/coercion/custody boundaries, independent review and non-automatable denial/escalation rules. | Family-trust/policy owner | Open — blocks code. |
| RS-ADM-04 | Privacy/data classification | Case categories, legal basis/purpose, child-data boundary, field minimization, evidence/attachment prohibition or handling, retention/deletion/legal-hold policy. | Privacy/data owner | Open — blocks code. |
| RS-ADM-05 | Support operating model | Availability statement, language/accessibility coverage, staffing/queue, response truth, case ownership, quality review, separation of duties and escalation route. | Support operations owner | Open — blocks code. |
| RS-ADM-06 | Incident response model | Security severity, containment, identity compromise, family-safety concern, breach/escalation, customer communication and evidence-preservation runbooks. | Incident/security owner | Open — blocks code. |
| RS-ADM-07 | Render operational ownership | Region/residency, project/database ownership, cost budget/alerts, backups, restore drill, deploy/rollback owner, secrets access and monitoring route. | Infrastructure/cost owner | Open — blocks connected deployment. |
| RS-ADM-08 | Abuse controls | Rate limits, enumeration resistance, duplicate/replay handling, coercion/harassment handling, unsafe-device/shared-device guidance and appeal path. | Security/trust owner | Open — blocks public intake. |
| RS-ADM-09 | Controlled verification environment | Non-production OIDC and PostgreSQL, test identities/families, audit/outbox review, no real child/family data and a test operator boundary. | QA/release owner | Open — blocks integration testing. |

## 3. Identity and recovery architecture decision

### 3.1 Principle: identity recovery cannot imply family recovery

```text
Identity issuer establishes a verified principal
    ↓
Render validates issuer + audience + signature + subject
    ↓
Render evaluates the principal's current account/membership authority
    ↓
Family access is granted only if the existing authoritative relationship permits it
```

A recovered login may restore access to the **same verified account relationship**. It may not:

- map a new identity to a historical account because of a support narrative;
- reactivate a removed/revoked membership;
- create a family membership;
- promote a guardian;
- disclose whether a family/member exists; or
- bypass a current policy, case decision or review.

### 3.2 Recommended baseline before provider selection

The approved issuer must provide standards-compatible OIDC token validation with stable subject semantics and documented incident/key rotation. The Render API remains provider-neutral and verifies the issuer/audience/JWKS server-side.

Firebase Authentication can be evaluated only as an optional token issuer after a separate current no-cost/pricing/quota/privacy/fallback review. Phone/SMS and any billing-required flow are excluded unless a distinct decision reverses that boundary. A Firebase Admin service account is neither required nor accepted for the standard OIDC verification path.

### 3.3 Recovery containment states

Until RS-ADM-01 and RS-ADM-02 are accepted, Family OS has only these truthful conditions:

| State | Meaning | Forbidden claim |
|---|---|---|
| `identity_provider_not_configured` | No approved issuer is connected. | “Sign in,” “reset password,” or “recover account” works. |
| `recovery_not_available` | A requested account/guardian recovery path has no operating policy. | “A request was sent,” “support will help,” or “access can be restored.” |
| `recovery_needed` | A known account/family condition needs an approved future process. | Any implied automatic recovery or authority change. |
| `security_review_required` | A future verified risk process blocks ordinary action. | A user is compromised, guilty or permanently denied. |

## 4. Family continuity and authority policy baseline

### 4.1 Normal versus exceptional continuity

| Scenario | Authorized path now | Exceptional path status |
|---|---|---|
| Active primary voluntarily transfers to active co-guardian | Existing two-party Guardian Transfer. | Implemented locally only; no connected/OIDC/Flutter claim. |
| Invitation expires/revokes/fails | Existing membership lifecycle rejects stale acceptance. | User-facing delivery/retry remains unimplemented. |
| Primary loses access but an active co-guardian exists | No automatic recovery. Co-guardian retains only existing co-guardian authority. | Requires `guardian_continuity_recovery` policy and independent decision. |
| Primary absent, disputed or unsafe | No ordinary role mutation. | Human/legal/policy escalation required; no code path. |
| Co-guardian requests self-promotion | Denied. | May only create an eligible future case, never a grant. |
| Child requests help | Child-safe help request only in a future support system. | Cannot expose adult recovery, audit, billing or custody details. |

### 4.2 Minimum policy questions that cannot be answered by code

Before exceptional continuity exists, the policy owner must determine:

1. Who can submit a case, and what limited status can each party see?
2. What constitutes a policy-eligible alternate guardian versus a claim by an unknown adult?
3. What evidence is acceptable, who evaluates it, where is it held, and how is it deleted or retained?
4. Which decisions require two independent reviewers, legal/custody escalation or a cooling-off period?
5. What happens when guardians disagree, a child is at risk, a guardian is coercing another, or no qualified reviewer is available?
6. How are incorrect approvals reversed, and how are affected family members safely informed without leaking sensitive case details?

## 5. Support operations: truthful service boundary

### 5.1 Product language before an operations team exists

Until RS-ADM-05 is accepted, the app may offer localized static help and a clearly labelled unavailable state. It may not offer a form that appears submitted, an estimated response time, a “case number,” a “support agent,” a diagnostic upload, or a “resolved” outcome.

### 5.2 Minimum support model after admission

A real support case must have:

- a published capability/availability statement, including language/accessibility limitations;
- requester authorization and family/child visibility boundaries;
- an explicit, revocable diagnostic preview containing only approved IDs, state/version/error class and consent scope;
- status semantics separated into `submitted`, `queued`, `received`, `in_progress`, `waiting_for_requester`, `resolved`, `closed`, `reopened`, `failed` and `unavailable`;
- a case owner, escalation rule, retention class and quality/audit review;
- no default access to child content, device data, audit detail, billing receipts, location history, credentials or identity evidence; and
- no authority to change family membership or recovery state except through a separately approved, scoped CaseDecision/CaseExecution transition.

## 6. Incident and abuse containment baseline

### 6.1 Required incident categories

| Category | Immediate safe behavior | Future operating requirement |
|---|---|---|
| Suspected account compromise | Do not grant recovery or disclose family state. Preserve minimum correlation evidence. | Identity containment/revocation runbook, user communication and re-verification policy. |
| Guardian takeover/coercion attempt | Refuse direct role change and retain audit/outbox evidence. | Trust/safety escalation policy, independent review and legal/custody boundary. |
| Case enumeration/replay | Return non-enumerating denial and avoid status disclosure. | Rate limits, abuse signals, monitoring and appeal path. |
| Support data over-collection | Do not collect/upload diagnostics. | Approved diagnostic profile, consent, retention and redaction process. |
| Render/database incident | Fail readiness/operations closed; preserve minimal evidence. | Backup/restore drill, rollback owner, incident commander and post-incident review. |
| Identity provider outage | Do not replace OIDC verification with local/session bypass. | Provider outage policy, availability language and recovery communications. |

### 6.2 Invariants

- An emergency, support or migration label never expands authorization.
- A case ID is opaque and non-enumerable, but opacity is not authorization.
- A rate limit may delay a request; it must not silently convert to denial or remove safety/privacy rights.
- Operators and automation must not receive raw credentials, access tokens or permanent account impersonation rights.
- Every sensitive decision/execution is independently auditable and can be placed behind a kill switch.

## 7. Future implementation sequence — deliberately gated

The following is the only safe order once all admission evidence is accepted:

1. Record accepted policies/owners and threat model versions; create no public UI yet.
2. Implement additive case schema with state/version/expiry/idempotency/audit/outbox invariants.
3. Implement server-only intake that reveals no family enumeration data and exposes no support claim beyond accepted runtime state.
4. Implement review/decision separation in a controlled non-production environment; no generic operator override.
5. Implement a narrowly scoped execution transaction for one approved case type, with post-execution verification, reversal/appeal strategy and independent audit.
6. Add truthful Flutter pending/unavailable/error states only after connected integration proves the service state.
7. Pilot with consentful test/limited users only when staffed operations, incident response and privacy handling are real.

A missing step re-blocks the next step. Code coverage does not substitute for policy, human ownership or data protection operations.

## 8. Admission outcome

```text
Recovery/Support implementation: NOT AUTHORIZED
Connected Render deployment: NOT AUTHORIZED
Flutter recovery/support claim: NOT AUTHORIZED
Local architecture/design work: AUTHORIZED AND COMPLETE FOR THIS CARD
```

The next output is an owned decision record satisfying RS-ADM-01 through RS-ADM-09. Until then, the correct technical behavior is restraint, documented limitations and existing fail-closed authorization.
