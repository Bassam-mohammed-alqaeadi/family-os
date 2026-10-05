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
| Backend (Node/Express/PG) | **Real & hardened** | 77/77 tests; OIDC/JWKS bearer verify; idempotency; rate limits; `no-store`; hashed one-time pairing codes; `timingSafeEqual` |
| Native child telemetry (Kotlin) | **Real** | Keystore-backed credential; foreground service; credential never returned to Flutter |
| Flutter identity/session | **Real, fixed** | `842636b`: first-family creation unblocked; sign-up/sign-in outcomes honest; no account enumeration |
| Flutter screens UX | **Partially real** | Several screens still carry prototype copy, mock seams (`ChildCountChoice`, "trial mode", fingerprint) and no loading/skeleton states |
| Child home after pairing | **Fixed this wave** | Pairing success → role=child → `/scr-chd-004?childId=…`; cold start honours the native pairing |
| CI | Analyze + tests only | **No Android build job** → native changes are unverifiable until added |

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
- [ ] A5 Sign-out from guardian shell clears session + returns to welcome (verify end-to-end on phone)
- [ ] A6 Session expiry mid-journey → `signInAgain` → return to the *same* step after re-auth

### Wave B — Screen polish, one screen at a time (UX = real states)
For every screen: **empty / loading / success / each failure** + RTL/AR first + ≥48dp targets + keyboard-safe + back-button safe.
- [ ] B1 `CreateAccountScreen`: inline field errors (e-mail format, password policy identical to Firebase), "email already in use → Sign in" action button, show/hide password, submit disabled while pending, no duplicate submits
- [ ] B2 `LoginScreen`: remove prototype fingerprint/trial affordances or make them honest (disabled + why); forgot-password → **real** Firebase reset e-mail
- [ ] B3 `CreateFamilyScreen`: remove `ChildCountChoice` mock or make it a real server field; pending state; conflict/validation copy
- [ ] B4 `AddChildScreen` ↔ `ChildrenControlCentre`: single real create path (name+age+avatar+colour) with roster refresh and "add another / pair device" next actions
- [ ] B5 `NativeParentPairingScreen`: countdown to `expiresAt`, regenerate on expiry, large QR, manual code fallback, "device connected" live confirmation via `/devices` poll
- [ ] B6 `ChildModePairingScreen`: permission pre-flight explainer *before* claiming (so a denied permission never burns a code), scan → claim → start progress steps, clear failure reasons per `NativeTelemetryStartResult.reason`
- [ ] B7 `ChildDayBoardScreen` first-run for a real paired child: show device label/battery/last-seen from server, hide guardian-only chrome

### Wave C — Security hardening around the journey
- [ ] C1 E-mail verification policy decision (Firebase `sendEmailVerification`) — Owner decision in `QUESTIONS.md`
- [ ] C2 Backend: `pairing_code` TTL review (short, e.g. 10 min) and max-claim-attempts per code hash
- [ ] C3 Child device anti-tamper v1: detect cleared config (native `configured=false` after being true) → guardian alert via `/devices` `lastSeenAt` staleness
- [ ] C4 Release build: `network_security_config` debug-only (already), signing config, `minifyEnabled`/R8 with keep rules for Firebase
- [ ] C5 Secrets guard: extend `credential_guard.yml` to fail on `google-services.json`, `*.jks`, `key.properties`

### Wave D — Verification infrastructure
- [ ] D1 CI: Android `assembleDebug` job (unblocks native changes, re-entry criterion for `BootReceiver`)
- [ ] D2 CI: upload debug APK artifact per push on `arena/*` for phone testing without a local build
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
