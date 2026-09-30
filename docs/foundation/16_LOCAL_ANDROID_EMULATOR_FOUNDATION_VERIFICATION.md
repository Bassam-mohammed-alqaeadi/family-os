# Local Android-emulator Foundation Gate verification

> **Status:** Ready for Owner-only execution after isolated CI pass `36791206030` (2026-10-01).
> **Scope:** Android emulator only; synthetic Firebase Email/Password principals only; one read-only `GET /v1/me/families` discovery flow; no Production, customer data, release, migration or new API work.
> **Prerequisites:** The Owner has accepted `15_FLUTTER_CONNECTED_FOUNDATION_IMPLEMENTATION_PLAN.md`, personally controls the encrypted, non-cloud-synced emulator workstation, and is accountable for the synthetic-principal and staging-data cleanup boundary of **2026-10-31**.

## 1. Purpose and non-goals

This is a manual, local evidence procedure for the isolated Foundation Gate that is already covered by the scoped CI suite. It may demonstrate only this path:

```text
synthetic Email/Password sign-in
  -> Firebase ID token held in process
  -> HTTPS GET /v1/me/families
  -> server-returned minimal family choice, or a generic state
  -> sign-out and volatile-state clear
```

It must not be used to:

- call a mutation endpoint; create, invite, alter or delete any Family OS resource; or apply a role decision in Flutter;
- add a hard-coded family ID, a local family/role fallback, a cache, offline mode, persistence, analytics, Crashlytics, telemetry, screenshots, token diagnostics or legacy-app import;
- test with a real identity, real family/child data, a physical device, Flutter Web, iOS, localhost, a database host, a Render internal hostname or Production; or
- run a CLI/configuration command that contains a Firebase value, API origin, email, password or token.

`Foundation Gate CI` passed the isolated lock installation, lock consistency check, analysis and test suite. This remains a scoped signal only: the unrelated global `Flutter CI` remains red and is not waived or changed by this procedure.

## 2. Local-only configuration boundary

Perform this section only on the approved workstation. Do **not** attach, paste, commit, synchronize, upload or quote any resulting local file, its contents, command output, provider output or identifiers.

The following paths are ignored by `app/.gitignore` and prohibited from being tracked by Credential Guard:

```text
app/android/app/google-services.json
app/ios/Runner/GoogleService-Info.plist
app/lib/foundation_gate/local/firebase_options.dart
app/lib/foundation_gate/local/foundation_gate_local_configuration.dart
app/lib/foundation_gate/local/main.dart
```

Use only the Android configuration material for the approved isolated Firebase project. The provider controls already accepted for that project are Email/Password only; phone/SMS, anonymous and federated providers remain disabled. Do not enable a provider, a Firebase product, an API, a permission or a broader Android restriction exception for this verification.

If the provider-generated Android setup needs a tracked Gradle change, a non-ignored file, an iOS/Web artifact, a `--dart-define`, CI access, a secret-management integration or any configuration outside the paths above, **stop**. That is a scope change and requires a new review; do not work around the boundary.

Before launch, the Owner must create the ignored local composition only:

1. `firebase_options.dart` contains the Owner-provisioned Firebase Android initialization options and is used only by the local entry point.
2. `foundation_gate_local_configuration.dart` constructs `FoundationGateConfiguration` from the Owner-provisioned canonical **HTTPS staging API origin** using `FoundationGateConfiguration.fromStagingApiOrigin`. It contains no database host, Firebase Admin endpoint, internal Render hostname or credential.
3. `main.dart` initializes Firebase with the local options, then constructs only these reviewed objects:
   - `FirebaseEmailPasswordIdentity(FirebaseAuth.instance)`;
   - `FamilyDiscoveryApiClient(configuration: localConfiguration, transport: PackageFoundationGateHttpTransport())`; and
   - `FoundationGateSessionController(identity: ..., discoveryApi: ...)`, passed to `FoundationGateApp(controller: ...)`.

The local entry point must not import `app/lib/main.dart`, a legacy bootstrap/domain, local storage, a cache, an analytics/crash package or an unrelated feature. Do not create a tracked replacement entry point. The tracked `lib/foundation_gate/main.dart` deliberately remains unconfigured.

## 3. Run procedure

1. Confirm the emulator is the approved encrypted local Android emulator and select only a synthetic Email/Password principal. Do not record its email or password.
2. From `app/`, install the exact committed dependency resolution:

   ```bash
   flutter pub get --enforce-lockfile
   ```

3. Launch only the ignored local entry point on that emulator:

   ```bash
   flutter run --target lib/foundation_gate/local/main.dart
   ```

   Do not copy the terminal output into chat, an issue, CI, a document or evidence. Stop if the app presents the tracked unconfigured shell, if Firebase initialization fails, or if an unexpected host/provider/product is involved.
4. Enter the synthetic Email/Password through the emulator UI. Verify that the fields clear after submit and that no raw provider error, token, email, endpoint, family ID or response body appears.
5. For an approved active synthetic principal, verify that the screen presents only server-returned family display name and display-only role. Select one item only as a volatile UI choice; this initial slice must make no follow-up family read or mutation.
6. Where approved synthetic principals and staging controls already make the cases available, observe the generic no-active-family, `401`, `403`, `503` and network-unavailable treatments. Do not create a test hook, alter the client, enable new infrastructure or retain detailed output merely to force a case. The automated suite already covers the mappings.
7. Select **Sign out**. Verify that the app returns to the sign-in screen with form fields empty and no selected family visible. Close the app; do not preserve app screenshots or logs as evidence.

## 4. Evidence and stop conditions

Report only the following labels, with `pass`, `fail`, `not run` or `not available under existing controls` as appropriate:

```text
local Firebase sign-in:
server family discovery:
empty/unrelated behavior:
401 handling:
403 handling:
503 handling:
network-unavailable handling:
sign-out volatile-state clear:
local configuration retained under approved hold or removed:
```

Never report email addresses, passwords, token values/claims, Firebase project/app identifiers, API origins, family IDs, role-to-person associations, raw request/response/provider bodies, logs, screenshots or local file contents.

Stop immediately and suspend the gate if any configuration is exposed, written to a tracked path, sent to CI/chat/logs, synced from the workstation, or if the exercise would require a scope expansion. On withdrawal, rejection, exposure, integrity/provider-lifecycle event, or the **2026-10-31** deadline, retire the Firebase synthetic principals and replace the synthetic PostgreSQL resource according to `12_STAGING_EXECUTION_EVIDENCE.md`; never use direct database deletion or a cleanup bypass.

A successful local run does not authorize a second API read, broader client capability, Production, a release or a public claim. Those require separate evidence and authorization.
