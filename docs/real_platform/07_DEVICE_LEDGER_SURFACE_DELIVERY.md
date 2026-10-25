# S0 spine, app side — the guardian's device ledger (SCR-FAT-026)

> **Status:** Delivered on branch `arena/04666ad2-family-os`, 2026-10-26. Nothing below is a plan:
> every line is checked against the code in this checkout, and the verification section says exactly
> which gates ran here and which one this sandbox cannot run at all.

**Scope:** the two missing columns of one system — a reachable screen and a journey test — for the
S0 spine (device capability ledger + command bus). The contract, the endpoints and the two typed
Dart clients already existed; **no feature screen imported them.** Nothing else was touched: no
route file, no migration, no backend file, no OpenAPI change.

**Rule:** `AGENTS.md` §1.1 (contract → client → screen → test, five columns) and §5 (one capability,
one truth, server-owned authorization). The screen therefore *gained* the ability to read the spine
and deliberately did **not** gain a second lock button.

---

## What a guardian sees now

`SCR-FAT-026` (device health detail) ends with one new section, mounted after the repair buttons so
a permission that needs fixing stays nearer the thumb than a ledger does:

1. **What this phone can do** — the eleven capabilities the spine defines, in enforcement order:
   stop-now, block overlay, accessibility follow-through, usage metering, app inventory, web filter,
   background location, tamper signals, push delivery, battery reporting, persistence after restart.
   Each line carries the phone's own verdict (`working on the phone` / `needs a permission on the
   phone` / `this phone cannot do it` / `the permission was withdrawn` / `the phone has not told us
   yet` / `waiting for your setup`), the minute the phone reported it, and the app and system versions
   that reported it.
2. **Your orders for this device** — the command ledger: what was ordered, where it got to
   (`accepted → dispatched → received → applied`, or `limited` / `rejected` / `expired` / `failed`),
   the window it was valid for, the receipt the phone sent back, and the failure reason if it failed.
3. **One action** — *Refresh the phone's settings*: a single `refresh_policy` command. The stop and
   the lift stay on the screen-time panel, which is where that decision already lives.

The seven honest states are rendered, not hidden: no server session, a record that is not a server
child, an account that may not see this device, a server that did not answer, a write that was
refused, and an answer that could not be read.

## Files

| Path | Lines | What it is |
|---|---|---|
| `app/lib/features/n12_devices/device_ledger_server_authority.dart` | 333 | The spine's one connection for this screen: two reads, one write, seven states, and the rule that a non-UUID id is never sent |
| `app/lib/features/n12_devices/device_capability_ledger_panel.dart` | 749 | The panel: capability rows in enforcement order, the command ledger with receipts, one `refresh_policy` action, `DeviceLedgerKeys` for the tests |
| `app/lib/core/design/components/device_capability_honesty_badge.dart` | — | Was shipped in S0 with **zero users** and Arabic hardcoded in its source, its own doc promising the labels move to ARB "the moment a screen starts using them live". This is that moment: six `capabilityState*` keys, one vocabulary for the whole platform |
| `app/lib/features/n12_devices/device_health_detail_screen.dart` | +12 | Mount point + `DeviceHealthDetailKeys.capabilityLedger` |
| `app/lib/foundation_gate/main_app_foundation_runtime.dart` | +18 | `capabilityApi` and `commandApi` alongside the other systems' clients |
| `app/lib/main.dart` | +31 | Builds both clients and binds the authority on a live session; `DeviceLedgerAuthority.bind(null)` on the no-server path, so there is no shadow authority after sign-out |
| `app/lib/core/i18n/app_ar.arb` · `app_en.arb` + generated | +62 keys each | 56 `deviceLedger*` + 6 `capabilityState*`; `ar=4035 en=4035`, exact parity |
| `app/tool/arb_messages.py` · `app/tool/messages/n12_device_ledger.json` | — | The declarative ARB writer used for this batch: it refuses a table that would fail a CI gate (banned words, eastern digits, placeholder mismatches, duplicate keys, missing `@key` metadata) *before* writing |
| `app/test/features/n12_devices/support/device_ledger_fake_server.dart` | 250 | One shared fake server for all three test files, answering in the wire shape the endpoints really use |
| `app/test/features/n12_devices/device_ledger_server_authority_test.dart` | 252 | 13 laws |
| `app/test/features/n12_devices/device_capability_ledger_panel_test.dart` | 322 | 9 journeys |
| `app/test/features/n12_devices/device_health_detail_screen_test.dart` | 346 total | 2 new cases on the existing screen harness (7 kept) |

`app/tool/_polish_add_arb.py` (the one-shot writer of the previous wave) is deleted here; its row in
`06_DAY_BOARD_AND_SCREEN_TIME_POLISH_DELIVERY.md` points at `tool/arb_messages.py` instead, which is
table-driven and gate-checked rather than edited-in-place.

## Two decisions that changed the shape of this slice

**The ledger does not offer the lock.** The first draft of this screen had a stop/lift pair, because
the command bus accepts `lock_now` and `release_lock`. It was removed after reading the backend:
`backend/src/app.js:1319` and `:1347` already write `screenTime.lock` directly for the screen-time
panel's buttons. One capability, two buttons, two truths about whether a child's phone is stopped —
`AGENTS.md` §5 forbids that, and no amount of UI polish fixes a split authority. So this screen shows
the gate (`the server takes no order for a capability the phone has not confirmed`), shows every
command already issued with its receipt, points at the panel that decides, and issues only
`refresh_policy` — a soft pull that needs no confirmation sheet and cannot harm a plan.
**Moving the screen-time lock onto the command bus is `S11` in the master plan (line 594), and is
recorded as the follow-up rather than half-done here.**

**A placeholder id is refused, not sent.** `FakeDeviceHealthSeam.demo()` keys devices `dev_a` /
`child_a` / `fam_stage1`. The clients guard UUIDs and throw `invalidInput`; forwarding that to the
screen would have produced "the server refused your order", which blames the family for our fixture.
The authority answers `notLinked` — *this record is not linked to a child on the server* — and sends
nothing, which is the sentence a parent (or the next developer) can act on.

## Strings

All 62 keys went through `app/tool/arb_messages.py` + `tool/messages/n12_device_ledger.json`.
Constraints satisfied at write time, and each is a CI gate: `ar`/`en` key parity; no banned word
(`Native`, `Remote`, `Backend`, `FCM`, `MOCK`, `Gateway`, `relay`, …) in any value; Western digits
only; every placeholder declared with a type; no prose literal in `lib/features/**` (rule 12). The
six state words are named `capabilityState*`, not `deviceLedger*`, because the badge that renders them
is a platform component, not a screen's private vocabulary.

## Verification

| Gate | Result here |
|---|---|
| `node tools/harness/check_dart_imports.mjs .` | ✅ 6513 imports scanned, 3747 skipped, **0 dead** |
| `node tools/android/check_manifest_policy.mjs` | ✅ passed |
| `bash tools/harness/harness_check.sh` | ✅ except the pre-commit "uncommitted work" refusal, which its own history check confirms after the commit |
| Static slice gate (structure, imports resolve, orphan privates, every DTO field and component named-parameter the panel touches exists in its declaration, ARB keys ↔ source usage **both directions**, generated getters present in all three localisation files, rule-12 replica, ARB language gates) | ✅ clean |
| `flutter analyze` · `flutter test` | ⚠️ **cannot run here** — no Flutter/Dart SDK, and the SDK download host is outside this sandbox's allowlist. CI is the only verifier for this slice |
| `cd backend && npm run check && npm test` | ⚠️ not run — `backend/node_modules` is absent in this sandbox and **zero backend files changed** in this slice. CI runs both |
| `test/tool/ui_016_hardcoded_strings_test.dart` (rule 12) | it shells out to `dart run tool/check_hardcoded_strings.dart`, so it can only pass on CI; the python replica of that checker ran here, over both new files and the badge, and found no prose outside ARB |

## CI — the only record that counts

Pushed to `arena/04666ad2-family-os`. **Not yet read at the time of writing this section** — the run
number, the `analyze-test` verdict and every failing case will be appended below with its annotations,
never summarised from hope. The precedent from `06_…`: a job named `Run tests` with
`continue-on-error: true` proves nothing; the verdict is the annotation dump of
`Enforce analyzer, test and generated-source gates`.

## Follow-ups this wave deliberately left open

1. **`S11`**: move the screen-time stop/lift onto the command bus so one capability has one road to
   the handset, then this ledger becomes the receipt view for it (already worded: `deviceLedgerLockElsewhere`).
2. **Phone check** (`docs/safety_phase/PHONE_CHECKS.md`): four lines are specified in the card
   `SAFETY-S0-app-surface.md` §6 — screen-reader order at 2.0, one `refresh_policy` round trip to a
   real `family_commands` row, airplane mode mid-read, and a cross-family device. The fifth column
   stays ⬜ until one of them is dated and passed.
3. **`pullPending` / `submitReceipt` on Kotlin** remain `S1`/`S2` work; nothing in this slice fakes
   them — the ledger reads the receipts the phone has already filed.
4. The stage-one device seam still feeds placeholder ids to `SCR-FAT-025`/`026`. This screen now makes
   that visible instead of laundering it; closing it means wiring the seam to the roster, which is a
   device-record slice, not a ledger one.
