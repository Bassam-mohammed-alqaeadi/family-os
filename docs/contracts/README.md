# Contracts and the stage gate

A **contract** is a rule that the backend, the API document and the Flutter app must agree on.
Each contract has one source file. Everything else is generated from it or tested against it.

## Where things live

| Contract | Source of truth | Consumers |
|---|---|---|
| Pairing code (`pairing.v1`) | `backend/contracts/pairing.v1.json` | `backend/src/pairing-code.js`, validation, the production and test stores, `backend/openapi/foundation.v1.json`, `app/lib/foundation_gate/pairing_contract.generated.dart` (generated) |

## Changing a contract

1. Edit the JSON source (the pattern, the length, the issue range, or the examples).
2. Regenerate the Dart side: `node tools/contracts/generate-dart.mjs`.
3. Run the stage gate: `cd backend && npm run verify:stage`.
   It fails until every consumer agrees: the OpenAPI pattern, the backend validation, and the
   generated Dart file. The examples in the JSON are run against the backend and the app.
4. Never write a contract value as a literal in a test. Use the contract, the generator, or the constant.
   `pairing-contract.test.js` fails if the retired pairing alphabet reappears in a test.

## Adding a stage

- Add its acceptance and rejection cases to the contract's `examples`, or add a contract test.
- Cases are cumulative. A later stage does not delete an earlier stage's cases.
- Raise `backend/contracts/baseline.json` (`backendPassMinimum`) to the new passing count.
  Never lower it to make a red build green.

## Claim-attempt policy (pairing.v1)

- At most **5 failed claims per source (IP) within 10 minutes**. A successful claim is not counted.
- The values live in the contract (`claimAttempts`). The limiter, the generated Dart constants, and
  the copy read them. `pairing-contract.test.js` pins them, so a change is deliberate.
- A refused claim returns `429 rate_limit_exceeded`. The app shows "Too many attempts. Wait N minutes".

**Why per source, not per code.** A claim carries only the code. A wrong guess matches no pairing,
so the server cannot say which code it was aimed at. A true per-code counter needs a pairing
handle in the request (the parent's QR could carry it). That is a larger change to the child's
entry flow and is a decision for the owner, not something the contract can silently do.

**Limits of this version.** The counter is in process memory. With more than one server instance
it becomes per instance. Before scaling out, move the counter to shared storage.

## What the gate does and does not check

- Checks: the generated Dart file is current; the backend suite is green; the pass count is at or
  above the floor; the contract examples hold on the backend and in the Dart test.
- Does not run Flutter. Flutter analyze and test run in CI (`flutter_ci.yml`).
- Blocking merges depends on branch protection on `arena/*`, which is a repository setting.
  Until it is enabled, a red commit can still be pushed; CI reports it but does not stop it.
