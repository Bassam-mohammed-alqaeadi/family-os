# M0 Lock Record — Phase 0 foundation

> **Status:** **LOCKED — 2026-10-05 on commit `3d7ff18`.** Every gate in §5 is green on that commit: the backend suite passes locally (93/93), and Flutter CI acquired a runner and passed analyze, the full widget/unit suite and the generated-source check. Two pre-existing repository failures were found and fixed to get there (§4.1.1, §4.1.2).
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
| Flutter analyzer + widget/unit suite | GitHub Actions `Flutter CI` (workspace network blocks `pub.dev`, so the local machine cannot run Flutter) | ⏳ blocked — see §4.1 |
| Secret/credential guard | GitHub Actions `Credential Guard` | ✅ passed (run `37366768433`) |

### 4.1 Flutter verification — first real evidence
The Flutter toolchain cannot be installed in the current workspace (`storage.googleapis.com`, `pub.dev` and `dl.google.com` are unreachable), so Flutter evidence must come from the repository's own CI, which runs `flutter analyze --fatal-infos`, `flutter test` and the generated-source check on Flutter 3.35.7.

**The runner-acquisition failures in §4.2 were transient.** Run `37369340887` for commit `84c6831` acquired a runner, executed every step, and produced a real result:

| Step | Result |
|---|---|
| Resolve packages, generate localization, **Analyze** | ✅ passed — `flutter analyze --fatal-infos` is clean, including the new widget tests |
| Run tests | ❌ `1784` passing, **2 failing** — both pre-existing, both now fixed (§4.1.1, §4.1.2) |

Foundation Gate CI (`37371273564`, commit `f110422`) narrowed its own scope to the same files and reported **43 passed, 1 failed** with the analyzer green, which is where the failing test was finally named. Both failures are now addressed and the next run is the verification.

**Canary comparison — did this phase break anything?**

| Commit | Passing | Failing |
|---|---|---|
| `4bb4337` (baseline, before this session's work) | 1781 | 2 |
| `84c6831` (this phase) | 1784 | **2** |

Three added tests, three added passes, and the failure count is unchanged. **Every failure is pre-existing on the baseline commit; this phase introduced none.** The same comparison holds for a sibling branch of the same repository (`arena/01a10887-family-os`), whose Flutter CI is green.

### 4.1.1 Pre-existing Flutter failures found and fixed in this phase
`AC1: features/ has no banned user-facing string literals` (UI-016 / Rule 12, `check_hardcoded_strings`) reported **exactly 3 violations**, reproduced locally by porting the checker's rule:

| Location | Literal | Fix |
|---|---|---|
| `native_device_pairing_screens.dart:525` | `hintText: 'ABC DEF'` | `copy.pairingCodeHint` — a real localized hint added to `NativeChildPairingCopy` |
| `create_account_screen.dart:118` | hardcoded Arabic account-failure message | `FoundationGateCopy.createAccountFailed` |
| `create_account_screen.dart:344` | hardcoded Arabic "already have an account?" CTA | `FoundationGateCopy.alreadyHaveAccountSignIn` |

The rule is now reproduced at **0 violations** locally. The exact Arabic wording is preserved verbatim in the new getters, so no user-visible copy changed; only its ownership moved out of the widget. A repository-wide grep confirms no test asserted the removed literals.

### 4.1.2 The second pre-existing failure — identified and fixed
Foundation Gate CI acquired a runner for commit `f110422` and named it:

```
Foundation Gate rejects unsafe origins and roster path values before networking
  Expected: throws <Instance of 'ArgumentError'>
```

`foundation_gate_configuration_test.dart` asserts that `http://staging.example.test` is **refused**. The factory did not refuse it — it accepted both `https` and `http` for any host, while its own error message already said *"A canonical HTTPS staging origin is required."* The contract, the message and the test all agreed; only the code disagreed.

**This is a real security boundary, not a test technicality.** That origin carries the guardian's bearer token and child roster data, so accepting cleartext for an arbitrary host means a public staging endpoint could be reached unencrypted.

**Fix:** every public origin is now HTTPS. Cleartext HTTP survives only where a real Android device reaches a developer machine — loopback (`localhost`, `*.localhost`, `::1`, `127.x`), mDNS `*.local`, and the RFC 1918 private ranges (`10.x`, `172.16–31.x`, `192.168.x`) — and the decision is made before any networking happens.

| Origin | Before | After |
|---|---|---|
| `https://staging.example.test` | accepted | accepted |
| `http://staging.example.test` | **accepted** | refused |
| `http://localhost:3000`, `http://10.0.2.2:3000`, `http://192.168.1.5:3000` | accepted | accepted (development only) |
| `http://172.32.0.1`, `http://evil.example.com`, `http://999.1.1.1` | accepted | refused |

The rejecting logic was ported and checked against ten representative origins before pushing, including the Android emulator host and a value outside the RFC 1918 B range.

### 4.2 Run ledger — commit `844ec82`

### 4.2 Run ledger — commit `844ec82`

| Workflow | Run | Outcome |
|---|---|---|
| Credential Guard | `37366768433` | ✅ success, 5m37s |
| Backend CI | `37366768461` | ⛔ cancelled after 15m queued — `The job was not acquired by Runner of type hosted even after multiple attempts` |
| Flutter CI | `37366768515` | ⛔ cancelled after 15m queued — same runner-acquisition failure |
| Foundation Gate CI | `37366768468` | ⛔ cancelled after 15m queued — same runner-acquisition failure |

The three cancelled workflows never executed a step. Their conclusions therefore carry **no information about the change** — no analyzer result and no test result exists for this commit.

### 4.2.1 Workflow dispatch attempt — blocked by the available credential

Re-running or dispatching was attempted through every available route, because a `workflow_dispatch` would have produced the Flutter evidence without a new commit:

| Route | Command | Result |
|---|---|---|
| REST dispatch by workflow ID | `POST /repos/{owner}/{repo}/actions/workflows/364337833/dispatches` | `403 Resource not accessible by integration` |
| REST dispatch by workflow file | `POST /repos/{owner}/{repo}/actions/workflows/flutter_ci.yml/dispatches` | `403 Resource not accessible by integration` |
| CLI dispatch | `gh workflow run flutter_ci.yml --ref arena/6233f1a1-family-os` | `403 Resource not accessible by integration` |
| REST re-run of the cancelled run | `POST /repos/{owner}/{repo}/actions/runs/37366768515/rerun` | `403 Resource not accessible by integration` |
| Control: read runs | `GET /repos/{owner}/{repo}/actions/runs` | ✅ `200`, 626 runs readable |

The credential is a GitHub App installation token (`X-Oauth-Scopes` empty, `X-Accepted-Github-Permissions: allows_permissionless_access=true`). It carries **read** access to Actions and **no write** access, so the dispatch is refused before any workflow is considered. This is a permission boundary, not a workflow or syntax problem: REST dispatch versus CLI dispatch made no difference, and the workflow is resolvable (its numeric ID `364337833` was returned).

**Consequence, stated plainly:** the Flutter gate of this lock is **unverified**, not passed, and M0 remains **Open**. The retry is a `push` event, because `push` is the one trigger this credential is allowed to create.

### 4.3 What local evidence does and does not cover
Local evidence fully covers the backend contract, store, authorization and OpenAPI behaviour, because the Node suite runs here. It cannot cover the Dart analyzer or any widget test — but §4.1 shows the analyzer is green in CI and that the three new widget guarantees execute there.

## 5. Lock gates

| # | Gate | State |
|---|---|---|
| 1 | All three M0 deliverables implemented and reviewed | ✅ |
| 2 | Backend suite green on the locking commit | ✅ `93/93` locally; `npm run check` clean |
| 3 | Flutter analyze + test green on the locking commit | ✅ Flutter CI `37372946441` — success, every step green, enforcement step **skipped** because no gate failed |
| 4 | No mock, seed or local-authority fallback on the normal path | ✅ (unchanged from the admitted slice) |
| 5 | Admission boundary reconciled, including presentation facts | ✅ [`03` §6](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md) — scope corrected on 2026-10-06: §6 reconciled **that record** only, leaving `02`, `OPEN_DECISIONS` and `04` on the older name-and-age wording. [`03` §7](03_PRIMARY_GUARDIAN_CREATE_CHILD_PROFILE_ADMISSION.md) closes them. No gate evidence depended on those three documents, so the lock is unaffected. |
| 6 | No secret, credential or real family data introduced | ✅ Credential Guard `37372946422` |
| 7 | Next wave selectable without reopening M0 | ✅ M1 (system 37, Devices) |

### 5.1 Run ledger for the locking commit `3d7ff18`

| Workflow | Run | Outcome |
|---|---|---|
| Flutter CI | `37372946441` | ✅ **success** — analyze, full test suite, generated-source check; runner `GitHub Actions 1000000795` |
| Credential Guard | `37372946422` | ✅ success |
| Foundation Gate CI | `37372946356` | ⛔ runner not acquired (infrastructure). Recorded for completeness: that workflow is a **faster subset** of the same `lib/foundation_gate` + `test/foundation_gate` scope, which the green Flutter CI run already covered in full. |

## 6. What Lock authorizes, and what it does not

**Authorizes:** opening **M1 — Devices** (system 37) under its own Compare → Cover → Compete → Real Engine cadence, exactly as [`../GLOBAL_LAUNCH_MASTER_PLAN.md`](../GLOBAL_LAUNCH_MASTER_PLAN.md) sequences it after M0.

**Does not authorize:** device pairing as a product capability, any Native service, provider use, staging/production release, or the claim that the wider Family Entry & Children Control system is complete. Each remains conditional on its own admission.

## 7. What changed in the repository to reach this lock

| Change | Why it was needed |
|---|---|
| `AiEvent v1` — envelope, migration `009`, transactional emission, guardian-scoped read | Part of the Phase 0 exit criteria in the master plan |
| `PermissionSnapshot v1` — capability catalog, expiring explanation, enforcement-drift test | Same; the client must explain permission, never decide it |
| OpenAPI contract + contract test extended | The two new operations must be enumerated, secured and rate-limited like every other |
| Three widget guarantees added | The admission requires retry-stable idempotency, pending-state lock-out and an Arabic RTL form; the third was untested and the first two were untested when this phase began |
| Admission record amended (`03` §6) | The shipped contract already required `avatarEmoji` and `themeColor`, which the record excluded |
| 3 Rule-12 hardcoded literals moved into copy classes | Pre-existing Flutter CI failure |
| HTTPS enforced for public staging origins | Pre-existing Flutter CI failure and a real cleartext-token boundary defect |

Every one of these is committed with its evidence; nothing in this lock rests on a claim that was not executed.
