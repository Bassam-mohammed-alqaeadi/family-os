# Recovery & Support Case System — Architecture Discovery and Guardrails

> **Status:** Design only; no Recovery/Support runtime, schema, API, Flutter flow, operator console or provider integration is implemented by this document.
> **Prompt discipline:** Produced under `05_SYSTEM_OPERATING_PROMPT.md` after the pre-response audit protocol.
> **Updated:** 2026-09-29
> **Authority:** Foundation Wave authorization permits recovery/service evaluation, but connected identity, Render ownership, retention/legal policy, support operations and Flutter production integration remain open prerequisites.

## 1. Audit conclusion and decision

The existing primary-guardian transfer is deliberately narrow: a current primary guardian and an active co-guardian voluntarily complete an expiry-bound, two-party handover. It does **not** solve lost access, coercion, disputed guardianship, custody/legal authority, account compromise, a missing primary guardian, support escalation or human recovery.

The best next architectural move is therefore **not to create a generic “recovery” button, role-edit endpoint, operator override or service-account path**. It is to design a case-governed recovery/support boundary where a request never grants authority by itself.

```text
claim/request ≠ identity proof ≠ evidence ≠ reviewer decision ≠ privileged execution ≠ verified recovery
```

Until every required stage is operationally owned, the user experience must remain `unavailable`, `pending_review`, `verification_required`, `blocked`, `expired`, `failed` or `recovery_needed`—not “recovered.”

## 2. Scope split: cases before recovery execution

### In scope for the design phase

- A durable, least-privilege **RecoveryCase** and **SupportCase** model.
- A state machine, authorization matrix, evidence/data-minimization model, audit/outbox semantics, abuse/race analysis and operational admission criteria.
- A precise boundary between normal guardian transfer, recovery request, support request, verified decision and future privileged execution.
- A future test contract and migration/rollout requirements.

### Explicitly out of scope now

- Email/phone/social login or account recovery implementation.
- Firebase Auth, Firebase Admin service accounts, Firestore, Cloud Functions, FCM or any Firebase data path.
- A support inbox, operator dashboard, human SLA, customer-facing case submission, attachments, messaging, identity-document handling or emergency intervention.
- Automatic promotion, custody adjudication, account takeover, family read access, data export/deletion, device recovery or role/scope edits driven by a case.
- Native pairing/location/device control, notifications, billing, AI or public release claims.

## 3. Core architectural distinction

| Object | What it is | What it can never do alone |
|---|---|---|
| Guardian transfer | Two active guardians voluntarily hand over primary responsibility through the existing case. | Recover a lost account, settle a dispute, prove custody or grant access to a stranger. |
| RecoveryCase | A controlled record that a person/system reports a continuity or access problem. | Authenticate someone, prove identity, change a role, restore access or override a family boundary. |
| SupportCase | A bounded request for help/diagnosis with consented, minimal metadata. | Expose raw family/child data, impersonate a guardian, alter authority or prove a human response. |
| Verification evidence | A reference to approved, time-bound proof evaluated under policy. | Become a reusable credential or a raw document/log copied into product analytics. |
| Decision | An independently authorized, versioned review outcome. | Execute a privileged action without its own transaction, approval scope and audit. |
| Execution | A future, specific server-side action under an approved decision. | Be performed by a generic operator or service account outside normal policy. |

## 4. Proposed case taxonomy

The taxonomy is deliberately small. Each type has a distinct authority policy, retention rule and execution allowlist; a free-text “other recovery” route is prohibited.

| Type | Eligible requester | Intended result | Current result |
|---|---|---|---|
| `account_access_issue` | Verified account holder with no family authority implication. | Diagnose/coordinate identity-provider recovery after provider is selected. | Design only; no account recovery implementation. |
| `guardian_continuity_recovery` | Existing active guardian or an already-known, policy-eligible alternate. | Request review when normal two-party transfer cannot begin or finish. | Design only; cannot change primary authority. |
| `membership_dispute` | Existing affected adult member; child may only request safe help without adult-case details. | Record disputed membership/revocation/continuity outcome for review. | Design only; cannot reactivate a membership. |
| `security_compromise_report` | Verified account holder or authorized guardian. | Trigger containment/revocation assessment, never an automatic recovery grant. | Design only; no session provider is integrated. |
| `support_request` | Any authenticated member within their allowed visibility scope. | Obtain documented product help with minimal diagnostics. | Design only; no human support channel is claimed. |

A caller without a verified principal may receive only public, non-account-specific guidance. It cannot create a family-scoped recovery case, learn whether a target family exists, or receive a status that leaks membership information.

## 5. RecoveryCase state machine

```text
Draft (local, non-authoritative)
  → submitted
  → intake_validated
  → verification_required
  → evidence_pending
  → review_pending
  → decision_recorded
      ├─ denied
      ├─ cancelled
      ├─ expired
      ├─ blocked_policy
      └─ approved_for_specific_execution
            → execution_queued
            → execution_applied
            → post_execution_verified
            → completed

Any state → abuse_suspected | dispute_open | recovery_needed | failed
```

Rules:

1. `submitted` proves only that Render accepted a request; it does not prove delivery, human review, identity, eligibility or outcome.
2. `verification_required` and `evidence_pending` are intentionally non-authoritative. Evidence references must be scoped, expiry-bound and never treated as client credentials.
3. Only an independent policy-authorized decision can reach `approved_for_specific_execution`; approval binds one target, one allowed action, one version and an expiry.
4. Execution must perform its own current-state authorization check in a transaction. It must fail closed if family membership, target, policy, evidence, time or approver authority changed after decision.
5. `completed` requires post-execution verification and durable audit, not an operator click or client confirmation.
6. A case cannot silently reopen, reactivate an old approval, replace an audit record or transform to another case type. A new related case/audit link is required.

## 6. Required data contract (not yet implemented)

A future migration must introduce versioned, Render-owned records rather than embedding recovery data in memberships or support notes.

| Record | Minimum authoritative fields | Prohibited content |
|---|---|---|
| `RecoveryCase` | id, type, requester account/membership reference, family reference if authorized, state/version, purpose, policy version, safe reason code, timestamps/expiry, related-case links, visibility/retention class, audit links. | Plaintext credentials, provider tokens, broad free-text family narratives, raw child data. |
| `SupportCase` | id, requester scope, category, consented diagnostic profile/reference, lifecycle/version, status/availability truth, timestamps, retention and audit links. | Hidden raw diagnostics, location history, notification payloads, billing receipts or child content by default. |
| `CaseVerification` | case reference, verifier policy/version, evidence reference/hash, observed/verified/expiry times, outcome and audit link. | Reusable identity secrets, unredacted government documents in general product storage. |
| `CaseDecision` | case, decision type, narrowly scoped allowed execution, independent decision authority/policy, expiry, version, rationale code and audit link. | A blanket “support override,” unrestricted operator access or mutable approval. |
| `CaseExecution` | decision, exact resource/action, transaction/correlation/idempotency key, pre/post state reference, outcome, rollback/recovery link and audit/outbox references. | A hidden direct database mutation or a client-provided role/family assertion. |
| `CaseAbuseSignal` | minimal rate-limit/risk/duplicate/conflict signal, classification, retention and audit reference. | Surveillance profile or unexplained automated denial of safety/recovery rights. |

## 7. Authorization and separation of duties

| Actor | May do | Must never do |
|---|---|---|
| Flutter client | Present truthful local/request state and send an authorized request. | Select a family role, verify evidence, approve itself, expose private case details or execute recovery. |
| Requester | Submit/cancel own eligible case; view only permitted status. | Learn hidden family/member existence, approve own case or acquire authority from a request. |
| Existing primary guardian | Initiate normal guardian transfer; participate in policy-allowed cases. | Unilaterally recover a disputed/absent guardian case through an ordinary role mutation. |
| Co-guardian | Accept normal transfer or participate in explicitly eligible review. | Self-promote, access another adult’s private case evidence or bypass a blocked state. |
| Child | Request age-appropriate help/report a problem. | Access adult recovery/support, billing, legal/custody, audit or other member data. |
| Support operator | View only case-approved metadata and act in a bounded workflow after operations exist. | Impersonate users, read raw family data, grant broad authority, access secrets or execute own approval. |
| Recovery approver | Record a scoped policy decision under separation-of-duties rules. | Be the sole unchecked requester, verifier and executor for a sensitive authority change. |
| Automation/outbox worker | Deliver deterministic, least-privilege state projections. | Decide custody, identity, primary authority or override policy. |

High-risk actions—primary authority recovery, family access restoration, account compromise containment and child-related scope change—must require policy-defined independent review and, where applicable, human/legal escalation. The product must not invent legal authority.

## 8. Edge cases and race conditions to prove before implementation

The eventual design/test plan must cover at least:

- concurrent normal transfer, recovery case and membership revoke/remove;
- candidate acceptance after expiry, removal, account compromise, role change or a new primary transfer;
- duplicate/replayed submissions and idempotency-key reuse with changed intent;
- a primary guardian returning after a case begins, or a family becoming archived/suspended;
- a requester whose verified identity changes/revokes during case review;
- cross-family identifiers, guessed case IDs, stale case links and unauthorized status polling;
- staff/automation outage, lost outbox delivery, partial migration, restart, failed verification provider and schema rollback;
- coercion/dispute signals, unsafe shared device use, minors attempting adult recovery and data-minimization failures;
- cancelled/expired/denied case replay, reapproval after policy version changes and execution after decision expiry; and
- recovery/support case impact on account deletion, retention limitation, safety/privacy access and incident evidence.

## 9. Operational admission gate before any Recovery/Support code

No RecoveryCase/SupportCase migration or API may begin until all of the following are named and accepted:

1. Approved identity issuer and account/session/revocation/recovery threat model.
2. Render region/database/cost/backup/restore/incident owner.
3. Privacy, retention, deletion, dispute, child-safety and legal-escalation policy owner.
4. Support operating model: availability statement, staffing/queue owner, case handling, independence/separation of duties, escalation and response truth.
5. Data classification and storage rules for diagnostics/evidence; attachment/document handling is prohibited until separately approved.
6. Case abuse controls, rate limit, safe public guidance and an appeal/review policy.
7. A controlled non-production environment with verified OIDC, PostgreSQL migrations, audit/outbox inspection and no real family data.

## 10. Design decision

The next implementation card is **not authorized yet**. The project should complete the admission gate and produce an exact Recovery/Support policy and operations record before introducing tables, endpoints or Flutter screens.

This is the deliberate safe choice: recovery must remain available as a trustworthy path, but it must never become the platform’s most powerful unaudited privilege-escalation route.
