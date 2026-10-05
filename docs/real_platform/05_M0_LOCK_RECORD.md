# M0 Lock Record — Phase 0 foundation

> **Status:** Open — awaiting the verification evidence listed in §4. It becomes **Locked** only when every gate in §5 is green on the same commit.
>
> **Scope:** Wave M0 of [`../GLOBAL_LAUNCH_MASTER_PLAN.md`](../GLOBAL_LAUNCH_MASTER_PLAN.md) — the three Phase 0 deliverables. It does **not** lock the wider Family Entry & Children Control system, and it opens no later wave.
>
> **Authority:** [`../../AGENTS.md`](../../AGENTS.md), [`../CURRENT_EXECUTION_PLAN.md`](../CURRENT_EXECUTION_PLAN.md), [`03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md`](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md).

## 1. The three M0 deliverables

The master plan fixes M0's exit as: **close the `create child` slice + `AiEvent v1` + `PermissionSnapshot v1`**, with API/unit/widget tests green.

| # | Deliverable | State | Where it lives |
|---|---|---|---|
| 1 | Primary-guardian create-child vertical slice | Implemented and covered (client, controller, widget) | `app/lib/foundation_gate/`, `backend/src/store/postgres-foundation-store.js` |
| 2 | `AiEvent v1` — fact envelope emitted from the first mutation | Implemented in this phase | `backend/src/ai-events.js`, `backend/db/migrations/009_ai_events.sql` |
| 3 | `PermissionSnapshot v1` — server-owned permission explanation | Implemented in this phase | `backend/src/permission-policy.js`, `GET /v1/families/{familyId}/permission-snapshot` |

## 2. What each deliverable guarantees

### 2.1 Create child (deliverable 1)
Already governed by its own admission record. The boundary is name, age and the two presentation facts; the server authorizes, persists and answers, and the client only reloads the confirmed roster. No local success, no client-side authority.

### 2.2 AiEvent v1 (deliverable 2)
- A **registered** fact type only. `family.child.created` is the single v1 type; an unregistered type is refused rather than stored (`aiEventDefinition` throws).
- Written **inside the same transaction** as the mutation it describes, so a committed change always has its fact and a rolled-back change never leaves one.
- **One fact per logical mutation**: an idempotent replay confirms the mutation but writes no second roster row and no second fact (proved by test).
- The envelope separates **facts from suggestions**: `source='server'` forces `confidence=1` and `reject_path IS NULL`. A suggestion with an un-rejectable outcome cannot be stored by this schema at all.
- The read surface (`GET /v1/families/{familyId}/ai-events`) is guardian-scoped, identifier-only, capped at 100 and carries no typed family content, token or correlation context.

### 2.3 PermissionSnapshot v1 (deliverable 3)
- A **versioned, expiring explanation** (`permission.v1`, 300-second window, `freshness: 'live'`), never a durable grant.
- The role is re-resolved from the durable membership on every call, so a client cannot ask for another role's explanation and a cached document cannot outlive a role change.
- Every capability is declared exactly once with an explicit `allowed` flag and a machine-readable `reason`, so denial is rendered from the same document as permission rather than inferred from a missing entry.
- **Enforcement drift is a CI failure.** `permission-policy` binds each declared capability to its real endpoint and probes it for `primary_guardian`, `co_guardian` and `child`; if enforcement and explanation ever disagree the suite fails.

## 3. Deliberate non-goals

The following are **not** part of this lock and were refused rather than half-built:

- No Flutter consumption of the snapshot or of AiEvent — the client keeps explaining only what it currently shows, and a typed client arrives with the system that needs it.
- No AI suggestion, inference, score or autonomous action. v1 stores observations.
- No device, location, policy, notification or billing surface — those are M1+ and each needs its own admission.
- No production, staging or provider activation. No secret, credential or real family data is involved anywhere in this phase.

## 4. Verification evidence

| Evidence | Command / artifact | Result |
|---|---|---|
| Backend contract, authorization, idempotency, audit/outbox and AiEvent suite | `cd backend && npm ci && npm test` | **93 passing, 0 failing** |
| Backend source syntax gate | `cd backend && npm run check` | Passed |
| Schema manifest integrity (every migration, immutable SHA-256) | `backend/test/schema-manifest.test.js` | Passed for `001`–`009` |
| OpenAPI contract enumerates every operation, security and idempotency | `backend/test/openapi-contract.test.js` | Passed for the two new operations |
| Permission/enforcement drift gate | `backend/test/permission-snapshot.test.js` | Passed for all three roles |
| AiEvent emission inside the mutation transaction | `backend/test/postgres-foundation-store.test.js` | Passed |
| Flutter analyzer + widget/unit suite | GitHub Actions `Flutter CI` (workspace network blocks `pub.dev`, so the local machine cannot run Flutter) | See §4.1 |

### 4.1 Flutter verification
The Flutter toolchain cannot be installed in the current workspace (`storage.googleapis.com`, `pub.dev` and `dl.google.com` are unreachable). Flutter evidence is therefore taken from the repository's own CI, which runs `flutter analyze --fatal-infos`, `flutter test` and the generated-source check on Flutter 3.35.7.

| Run | Scope | Result |
|---|---|---|
| Flutter CI on `arena/6233f1a1-family-os` | Two new widget guarantees: retry-stable idempotency key, and pending-state lock-out | Recorded in §4.2 once the run completes |

### 4.2 Run ledger
_Run identifiers are appended here after the workflow finishes; the lock is not declared before they are green._

## 5. Lock gates

| # | Gate | State |
|---|---|---|
| 1 | All three M0 deliverables implemented and reviewed | ✅ |
| 2 | Backend suite green on the locking commit | ✅ 93/93 |
| 3 | Flutter analyze + test green on the locking commit | ⏳ pending run ledger |
| 4 | No mock, seed or local-authority fallback on the normal path | ✅ (unchanged from the admitted slice) |
| 5 | Admission boundary reconciled, including presentation facts | ✅ [`03` §6](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md) |
| 6 | No secret, credential or real family data introduced | ✅ |
| 7 | Next wave selectable without reopening M0 | ✅ M1 (system 37, Devices) |

## 6. What Lock authorizes, and what it does not

**Authorizes:** opening **M1 — Devices** (system 37) under its own Compare → Cover → Compete → Real Engine cadence.

**Does not authorize:** device pairing as a product capability, any Native service, provider use, staging/production release, or the claim that the wider Family Entry & Children Control system is complete. Each remains conditional on its own admission.
