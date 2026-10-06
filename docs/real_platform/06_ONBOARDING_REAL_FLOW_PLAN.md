# 06 — Onboarding Real-Flow Plan (Account → Family → Child → Device)

> **Status:** ACTIVE — 2026-10-06. Owner: Bassam. Partner agent: Arena.
> **Branch:** `arena/01a10887-family-os`. **Scope lock:** nothing outside this
> journey opens until its Exit Gate passes on a real phone.

## 0. Why this document exists

The five steps below are the *only* path a real family can take into the
product. Each must be **real** (server-confirmed, no local success), **honest**
(every failure is a named state with a next action) and **safe** (no secret,
token or raw provider text ever reaches the UI or logs).

```
[1] Create account ──► [2] Sign in ──► [3] Create family ──► [4] Add child ──► [5] Pair child device ──► Child home
     Firebase            Firebase +        POST /v1/families     POST …/children     POST …/device-pairings  (child handset)
                         GET /v1/me/families                                        POST /v1/device-pairings/claim
```

## 1. Current truth (audited 2026-10-05/06)

| Layer | State | Evidence |
|---|---|---|
| Backend (Node/Express/PG) | **Real & hardened** | 80/80 tests; OIDC/JWKS bearer verify; idempotency; rate limits; `no-store`; hashed one-time pairing codes; `timingSafeEqual`; non-enumerating device self-status |
| Native child telemetry (Kotlin) | **Real** | Keystore-backed credential; foreground service; credential never returned to Flutter; self-status request returns only sanitized device fields |
| Flutter identity/session | **Real, fixed** | First-family creation unblocked; sign-up/sign-in outcomes honest; no account enumeration |
| Flutter screens UX | **Real for B1–B7** | Account, login, family, child, pairing, and paired-child home use genuine outcomes with named retry states |
| Child home after pairing | **Fixed this wave** | Pairing success → role=child → `/scr-chd-004?childId=…`; cold start honours native pairing and displays server-backed label/battery/last-seen without guardian chrome |
| CI | **Flutter + Foundation + Android gates** | Analyzer, tests, generated-source verification, credential guard, and debug APK Kotlin/Gradle compile are enforced |

## 2. Rules for this journey (binding)

1. **Server is the only source of truth.** A step is "done" when the server says 201/200, never before.
2. **One failure = one named state = one next action.** No raw errors, no generic "something went wrong" where a specific, safe reason exists.
3. **Never trap the user in a step that already succeeded.** (The sign-up/discovery trap fixed in this wave is the canonical example.)
4. **Secrets never cross layers.** ID tokens are transient; the device credential lives only in Keystore; pairing codes exist only in widget memory and the QR.
5. **No enumeration.** "Wrong e-mail" and "wrong password" are the same message.
6. **Retry is idempotent.** The same `Idempotency-Key` is reused for the same user attempt.
7. **Offline is a state, not a bug.** Every network call has: pending → success | network | service | denied | session.
8. **Role is derived, not picked.** The device-mode chooser is a *hint*; a paired handset is a child device, a signed-in guardian is a guardian.

## 3. Work breakdown (ordered — each item ships alone and is phone-testable)

### Wave A — Flow correctness (this wave, mostly done)
- [x] A1 First-family creation for new accounts
- [x] A2 Sign-up never advances on failure; never traps after success
- [x] A3 Sign-in routes "no family yet" to setup
- [x] A4 Pairing success → child home; cold start into child home when natively paired
- [x] A5 Sign-out from guardian shell clears the Firebase provider session and volatile family/roster/device state before returning to welcome; provider failure keeps the session open with an inline Retry state (physical-phone pass remains in §5)
- [x] A6 Session expiry mid-journey → `signInAgain` → return to the *same* step after re-auth (2026-10-06: 401/provider no-session clears volatile authority; family, child, and parent-pairing steps push real sign-in above the current form and pop back only after server-backed re-auth; resume targets are local allowlisted paths; physical-phone pass remains in §5)

### Wave B — Screen polish, one screen at a time (UX = real states)
For every screen: **empty / loading / success / each failure** + RTL/AR first + ≥48dp targets + keyboard-safe + back-button safe.
- [x] B1 `CreateAccountScreen` (2026-10-06, zero-mock pass): inline field errors (e-mail format, password policy identical to Firebase), "email already in use → Sign in" action button, show/hide password, submit disabled while pending, no duplicate submits
- [x] B2 `LoginScreen` (fingerprint/trial/invite affordances removed; real `sendPasswordResetEmail` sheet; inline notices; `?email=` pre-fill from sign-up): remove prototype fingerprint/trial affordances or make them honest (disabled + why); forgot-password → **real** Firebase reset e-mail
- [x] B3 `CreateFamilyScreen` (`ChildCountChoice` + trial banner removed; name is the only field; inline error + Retry keeps the form): remove `ChildCountChoice` mock or make it a real server field; pending state; conflict/validation copy
- [x] B4 `AddChildScreen` (server-only create path, preview seams and mock alias removed, per-draft idempotency key reused on retry, fields locked while saving, live preview card). Remaining for ChildrenControlCentre "add another / pair device" next actions → B7 scope: single real create path (name+age+avatar+colour) with roster refresh and "add another / pair device" next actions
- [x] B5 `NativeParentPairingScreen`: countdown to `expiresAt`, regenerate on expiry, large QR, manual code fallback, "device connected" live confirmation via `/devices` poll
- [x] B6 `ChildModePairingScreen` (also: https-origin pre-check before claim, because the native service rejects http origins): permission pre-flight explainer *before* claiming (so a denied permission never burns a code), scan → claim → start progress steps, clear failure reasons per `NativeTelemetryStartResult.reason`
- [x] B7 `ChildDayBoardScreen` first-run for a real paired child: a non-enumerating Device-capability self-read returns only label/battery/last-seen; Android authenticates from Keystore and exposes only a sanitized snapshot; CHD-004 has honest not-reported/unavailable + retry/refresh states; unsupported/unconfigured hosts hide the card; genuine paired-child boot suppresses guardian debug role chrome

### Wave C — Security hardening around the journey
- [x] C1 E-mail verification — Owner decision (2026-10-05; stale-claim regression hardened 2026-10-06): family creation and adding children are NOT blocked; only issuing a pairing QR/code requires a verified e-mail. Server enforces it: `POST .../device-pairings` → `403 {error.code:'email_verification_required'}` unless the ID token carries `email_verified:true`. Parent pairing begins with a provider reload, runs a silent 3-second reload poll (plus resume re-check), and the runtime repeats that reload immediately before issuance so Firebase force-refreshes the ID-token claim. The client safely classifies the reviewed server code without exposing server text; verification, permission, missing-child, non-replayable conflict, service, network, and unexpected-response states each receive localized recovery. The moment the link is clicked — on any device — the gate opens and the pairing code is issued hands-free (no "I verified" button).
- [ ] C2 Backend: `pairing_code` TTL review (short, e.g. 10 min) and max-claim-attempts per code hash
- [ ] C3 Child device anti-tamper v1: detect cleared config (native `configured=false` after being true) → guardian alert via `/devices` `lastSeenAt` staleness
- [ ] C4 Release build: `network_security_config` debug-only (already), signing config, `minifyEnabled`/R8 with keep rules for Firebase
- [x] C5 Secrets guard: `scripts/verify-no-service-account-keys.mjs` rejects `google-services.json`, `*.jks`/`*.keystore`, `android/key.properties`

### Wave D — Verification infrastructure
- [x] D1 CI: `.github/workflows/android_build.yml` builds the debug APK (Kotlin+Gradle compile gate) on `main` and `arena/**`; requires secret `GOOGLE_SERVICES_JSON` (base64) and variable `FAMILY_OS_API_ORIGIN`
- [x] D2 CI: same workflow uploads `family-os-debug-<sha>.apk` as a 14-day artifact with SHA-256 in the run summary
- [ ] D3 Owner phone test script (§5) kept in this doc and ticked per wave

## 4. Error-state matrix (must be true for every step)

| Trigger | Step 1 Sign-up | Step 2 Sign-in | Step 3 Family | Step 4 Child | Step 5 Pair |
|---|---|---|---|---|---|
| Offline | provider network msg, stay | provider network msg, stay | SHR-005 network + Retry (same key) | network result + Retry | claim failed msg; code stays valid |
| Backend 503 | account created → continue to setup | service msg, stay | service state + Retry | service state | claim failed |
| 401 | — | signInAgain | session expired → login | session expired → login | n/a (no bearer) |
| 403 | — | accessDenied | denied state | denied state (co-guardian) | guardian not primary → no code issued |
| 409 | email in use → Sign in | — | conflict state | conflict state | code not replayable → regenerate |
| 400 | invalid e-mail / weak pw | invalid e-mail | validation state | validation state | invalid/expired/used code |

## 5. Owner phone test script (tick on real devices)

1. New e-mail → Create account → lands on device mode → Guardian → Create family → **201** → setup wizard.
2. Kill backend (or disable port-forward) → repeat 1 with another e-mail → toast "account created… continue" → **lands on setup, not stuck**; restore backend → create family succeeds on Retry.
3. Sign out → Sign in with same e-mail + wrong password → single generic credentials message. Sign in correctly → guardian Today.
4. Add child (name+age) → roster shows child → "Pair device" → QR shown with expiry.
5. Child phone: Child mode → grant location (incl. background) → scan QR → **lands on child home**. Reopen app → **still child home**.
6. Guardian: devices list shows the child device with battery + last seen within 2 minutes.
7. Child phone: clear app data → reopen → welcome (not child home). Guardian: device goes stale → (C3) alert.

## 6. Exit gate for this journey

All of §5 ticked on two physical Android devices · Flutter CI + Foundation Gate CI green · Backend CI green · No open P0/P1 in the GitHub milestone **"Onboarding Real Flow"** · `AGENTS.md` marker updated by Owner.

## Onboarding UI kit (shared by B1–B6)

`app/lib/features/shared_onboarding/onboarding_form.dart` + `app/lib/foundation_gate/onboarding_copy.dart` (copy lives outside `features/` per Rule 12):
`OnboardingScaffold`, `OnboardingHeader`, `OnboardingTextField` (inline error under the field),
`OnboardingNotice` (persistent inline server outcome with optional action), `OnboardingSubmitButton`
(spinner + lock = double-submit guard), `PasswordVisibilityToggle`, `looksLikeEmail`, `passwordStrength`.
Rule: no toast for anything the user must act on; no UI element without a real backend action.
