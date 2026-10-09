# Administration, Trust & Operations Settings Desk & State Model — Gate G2

> **Status:** Accepted under standing Owner trust
> **Purpose:** Define shared family authority, setup, device, attention, data, commercial and support controls before any Backend, payment, notification transport or Native/device implementation is built.

## 1. Shared settings pattern

Every platform-wide setting uses the same understandable sequence:

```text
Purpose and current truth
  → family / member / child / device / domain scope
  → normal rule or preference
  → authority, consent and affected people
  → capability, delivery and time/freshness context
  → history, pause, change, recovery or support
```

A local preference, UI toggle, generated QR, demo entry, billing label or cached status cannot create a remote family authority, connected device, purchased entitlement, delivery receipt or completed data-lifecycle outcome.

## 2. Authority and policy hierarchy

```text
1. Lawful safety/emergency, child-protection, accessibility and required-retention obligations
2. Verified family ownership, primary-guardian continuity and account recovery authority
3. Explicit membership role, child/device relationship, consent and visibility boundary
4. Supported device/platform capability and source freshness/integrity
5. Primary-guardian family policy and child/domain-specific rule
6. Eligible co-guardian/member preference within granted scope
7. Personal notification/display/accessibility preference
8. Product baseline and clearly labelled local/demo default
```

The effective authority/policy and reason must be inspectable. A co-guardian preference, plan limit, client cache or intelligence suggestion may not silently override a verified safety/emergency, privacy, membership, accessibility or device-capability boundary.

## 3. Key settings desks

### A. Account, family and recovery desk

| Section | Required controls |
|---|---|
| Account | Verified sign-in state, available authentication/recovery methods, session/device list where supported, locale and account-security changes. |
| Family context | Create, join, leave where eligible, active family switch only when real multiple-family membership exists, family display labels and ownership explanation. |
| Primary guardian continuity | Recovery contact/alternate guardian proposal, condition/scope, verification, expiry, revoke and audit. |
| Setup | Real setup tasks, benefit, child/device scope, completed/pending/limited state, skip/resume and recovery action. |
| Consent and terms | Applicable version/date/locale, required acknowledgement, child explanation/acknowledgement where relevant, and change history. |
| Recovery | Lost account/device, membership dispute, unsafe invitation, guardian absence and support escalation path. |

### B. Family members and role desk

| Section | Required controls |
|---|---|
| Roster | Active/pending/declined/expired/revoked members, child/guardian relationship and verified identity state. |
| Invite | Intended person, role template, child/domain scope, expiry, delivery method/capability and revoke/resend state. |
| Role scope | View/support/manage permission groups, visible children/domains, prohibited actions, effective scope and preview of impact. |
| Changes | Propose, verify, accept where needed, activate, pause, remove/revoke or recover with affected-person explanation. |
| Conflict | Concurrent changes, primary-guardian decision requirement, dispute/support path and audit/history. |
| Child relationship | Add/update a child only with authorized guardian context; changes explain device/data/learning/safety impact and cannot be a silent permission expansion. |

### C. Device and connection-health desk

| Section | Required controls |
|---|---|
| Device identity | Owner/child relationship, type/platform/OS/app version only when verified, registration date and current device lifecycle state. |
| Pairing | Supported device type, code/QR expiry, initiator/recipient/account match, child explanation, permission prerequisites and cancel/retry path. |
| Capability | Per-feature supported/limited/unavailable state with reason; do not compress into one “protected” badge. |
| Health | Last verified contact, freshness, permission/setting condition, battery/connectivity where genuinely reported, source/time and repair action. |
| Lifecycle | Pending pair, verified active, attention required, stale/offline, replaced, paused, unlinking, unlinked or compromised/recovery-needed. |
| Ownership and removal | Who may repair/pause/unlink/replace, consequences for policy/data/alerts, handoff/reset process, audit and recovery. |

### D. Today and attention desk

| Section | Required controls |
|---|---|
| Family context | Active family/member role/child context and honest empty/no-family/limited state. |
| Priority policy | Eligible source domains, urgency/relevance threshold, role visibility, duplicate grouping and expiry. |
| Attention items | Source, action owner, deadline/freshness, status, defer/dismiss/acknowledge meaning and link to domain detail. |
| Child cards | Authorized profile/status summary, selected child context, freshness/capability/permission notes and no ranking/comparison default. |
| Recent changes | Only confirmed, meaningful source transitions; show actor/time/owning domain and audit route where permitted. |
| Preferences | Personal layout/detail preferences only; they cannot manufacture or hide a safety/emergency/domain outcome. |

### E. Notification and attention desk

| Section | Required controls |
|---|---|
| Audience | Member, role, child/domain relevance, device/channel eligibility and authoritative source of each category. |
| Urgency | Critical/emergency, needs-action, informative/digest semantics with explicit exceptions; never colour-only. |
| Channel | In-app, approved push, email or other later supported transport; actual availability/permission/token state and fallback. |
| Timing | Local time zone, quiet hours, digest cadence, daylight-saving/travel behaviour, schedule validation and effective policy. |
| Fatigue | Grouping, cooldown, duplicate suppression, category pause and summary; excluded emergency/SOS path clearly named. |
| Lifecycle | Saved preference, pending sync, effective policy, transport queued/attempted, client receipt/open/action only where independently proven, failure/expiry/retry. |

### F. Privacy, data and audit desk

| Section | Required controls |
|---|---|
| Data map | Purpose, category/source, subject, visibility, capability, retention class, provider/processor role where relevant and current use. |
| Collection/sharing | Family/child/domain source scope, consent/authority, enabled/pending/limited/unavailable state, impact preview and audit. |
| Child transparency | Age-appropriate active categories, reason, who may see, how long/what limits apply and support/request route. |
| Access/export | Request scope/format, authority check, collection/packaging/availability/expiry/failure and secure retrieval state. |
| Correction/forget/delete | Target/scope, downstream impact, policy eligibility, queued/partial/completed/retention-limited/failed result and recovery. |
| Audit | Authorized view of meaningful actor/action/time/outcome; append-only operational record with access control and no raw-content dossier. |

### G. Plan and subscription desk

| Section | Required controls |
|---|---|
| Plan context | Current entitlement source/state, included capability, family limits, regional availability and truthful price/currency/tax terms. |
| Trial | Eligibility, start/end/time-zone, charge/renewal terms, cancel state and post-trial capability impact; never invented countdown/success. |
| Change | Upgrade/downgrade/plan comparison, effective time/proration only after provider/store confirmation, affected family/device scope and receipt. |
| Purchase/restore | Store/provider handoff, pending/verified/failed/cancelled/restored/refunded state, Render reconciliation and retry/support route. |
| Limits | Explain what a plan limit affects before a child/member/device action; preserve existing safety/privacy/recovery rights. |
| History/support | Receipts/history where real, billing contact/refund policy, cancellation and dispute/support lifecycle. |

### H. Language, accessibility and support desk

| Section | Required controls |
|---|---|
| Language/format | App language, RTL/LTR, time/date/calendar, numeral, locale and content availability/fallback behavior. |
| Accessibility | Text size, screen-reader semantics, reduced motion, contrast, keyboard/input and age-appropriate language preferences where supported. |
| Help | Current localized article/help topic, capability/support boundary, no-data/offline state and safe link handling. |
| Diagnostics | Exact optional data categories to include, redaction/preview, consent, expiry and transmission state. |
| Support request | Topic, affected family/member/device reference, permitted attachments, submitted/queued/received/in-progress/resolved/closed/reopened/failed state. |
| Account-safe recovery | Identity verification, limited support access, no sensitive information disclosure before authority is confirmed and audit. |

## 4. Core state machines

### A. Family setup and membership

```text
No verified family
→ create / join invitation / recovery request / isolated demo
→ verification and authority checks
→ family context established | rejected | expired | needs support
→ progressive setup task: not started | in progress | pending verification
→ verified complete | limited | deferred | failed / recovery needed
```

A setup task contributes to progress only after its defined authoritative outcome. A demo is a separate state and cannot transition itself into a verified family.

### B. Invitation, role and guardian-continuity lifecycle

```text
Draft proposal → authorized/validated → invitation or recovery request sent
→ viewed/verified → accepted → active membership/scope
               ↘ declined | expired | revoked | failed | disputed
→ paused / changed / removed / recovered
```

Role change requires impact preview and durable author/audit state. Primary-guardian continuity has its own verification and cannot be triggered by ordinary co-guardian role editing.

### C. Device lifecycle and health

```text
Unlinked → pairing initiated → code/identity/permission validation
→ registered → capability assessed → active and current
                         ↘ limited / unsupported / attention needed
→ stale/offline → repair / replace / pause / unlink request
→ unlinked / replaced / recovery-needed
```

“Active and current” is feature-specific and time-bound. A device may be registered while a particular capability is unavailable, permission-limited or stale.

### D. Today item lifecycle

```text
Authorized source event/state
→ relevance/visibility/freshness check
→ eligible priority | attention item | history-only | not eligible
→ viewed / action opened / deferred / dismissed where allowed
→ linked domain outcome changes independently
→ expires / superseded / re-evaluated / archived
```

Dismissing a Today card affects its presentation, not the source event, safety response, notification receipt or domain responsibility unless the linked domain explicitly supports the action.

### E. Notification preference and delivery lifecycle

```text
Preference draft → authority/time-zone/channel validation → saved/effective policy
→ event eligible → recipient/relevance/fatigue evaluation
→ in-app/push/email transport queued → attempted → client/device receipt where supported
→ opened/actioned/expired/failed/retried
```

Transport attempt and client receipt are distinct from the underlying event’s delivery, guardian understanding or resolution. Emergency/SOS follows its separate domain escalation contract.

### F. Privacy/data request lifecycle

```text
Request drafted → authority/scope/retention/impact validation
→ accepted | rejected/not eligible | needs review
→ collection/propagation/export/deletion work queued
→ completed | partial | retention-limited | failed / retry-needed
→ permitted audit and user explanation retained
```

The lifecycle identifies exactly which stores/indexes/providers are in scope when real. It never uses a local UI confirmation as evidence of distributed deletion/export.

### G. Subscription and entitlement lifecycle

```text
Plan catalog available → eligible selection / trial start
→ provider/store checkout or restore request
→ pending verification → active entitlement
                     ↘ cancelled | failed | declined | expired | refunded | disputed
→ change scheduled/effective → Render reconciliation and family capability update
```

An app-store/storefront event is not sufficient alone: Render must verify/record effective entitlement before a family feature is presented as available.

### H. Support request lifecycle

```text
Self-help / diagnostic preview → request draft
→ submitted | queued | failed
→ received → in progress → resolved / closed
                     ↘ needs information | reopened | unavailable
```

Human support availability, response time and resolution are not implied by a form submission or local toast.

## 5. Failure and recovery rules

| Scenario | Required product response |
|---|---|
| Account/family context cannot be verified | Preserve safe sign-in/recovery state; show no family data or seed fallback; explain next recovery/support action. |
| Invitation/role change conflicts or expires | Show current authority/author/time, protect existing access, allow authorized resend/revoke/support path and audit outcome. |
| Device pairing/health fails or becomes stale | Show specific capability/permission/last-known limitation, preserve safe local context, guide repair/retry/replace/unlink; never show healthy by default. |
| Today has no eligible source data | Show an honest first-use/no-data state and the next setup action; never fabricate a pulse, child card or intelligence recommendation. |
| Notification cannot be delivered | Preserve authoritative item and failure/expiry state in-app; offer retry/alternative where real; never mark it received/resolved. |
| Privacy request is limited by retention or propagation | Explain scope, what completed/remains, why and recheck/support path; stop future eligible use as policy requires. |
| Billing provider/store is unavailable or receipt conflicts | Preserve selected intent and current verified entitlement; show pending/failed/retry/support state; do not change access on an unverified client result. |
| A plan/lower tier affects an action | Explain before the person loses/tries an action, offer permitted alternative/support, and do not gate emergency/privacy/recovery rights. |
| Help/support is unavailable | Show current self-help/offline path and honest unavailable/request failure state; no fictional agent or resolution message. |
| Local/demo cache is displayed | Label it with source/freshness/non-synchronized status and prevent it from writing production family state. |
