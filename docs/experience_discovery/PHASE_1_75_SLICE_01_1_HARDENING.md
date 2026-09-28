# PHASE 1.75 — SLICE 01.1 HARDENING

**Date:** 2026-09-24  
**Broad codegen:** NOT ARMED  
**Slice 02:** NOT STARTED

```text
CURRENT PHASE: PHASE 1.75
TASK PHASE: SLICE 01.1 HARDENING
STATUS: ALIGNED
WILL MODIFY PRODUCTION CODE: YES (create_safe_zone_screen.dart only)
```

---

## Result

### `PASS`

FAT-017 production path no longer falls back to `stage1SafeZonesRepository` when Domain bootstrap fails. Explicit test inject preserved. Break-glass untouched. CHD-005 second `fire.fire` verified as non-duplicating for sos_final incidents.

```text
SLICE 01.1 ONLY
SLICE 02 NOT STARTED
PHASE 1.75 BROAD CODEGEN NOT ARMED
```

---

## FAT-017

| Path | OLD | NEW |
|------|-----|-----|
| Domain bootstrap OK | Domain `saveDefinition` | Unchanged — Domain `saveDefinition` |
| Domain bootstrap fail / Domain null + no inject | `_repo.add` → **stage1SafeZonesRepository** (silent second authority) | **Safe failure:** SnackBar `errorNetworkMessage` + Retry (`errorRetryCta` → `_bootstrapDomain`); optional banner; **no Stage-1 write** |
| Explicit `repository:` / `domainRepository:` | Test inject | **Preserved** — injected list repo may still `add` (TEST-ONLY) |

Production init no longer assigns `_repo = stage1SafeZonesRepository`.

---

## CHD-005

Sequence: `crossSystem.fireChildHold` (durable `SosIncident` in sos_final) then `SosFireService.fire`.

**Duplicate sos_final incident?** **No.**  
`MockSosFireService.fire` only increments `fireCount` and runs `NotificationDelivery.simulateSosAlert` — it does **not** write `sos_incident` / lifecycle audit / evidence rows.

**Retained for:** P-4 entitlement-free fire + mock delivery parity.

**Changed in 01.1?** No.

---

## Legacy

| Symbol | Status |
|--------|--------|
| `stage1SafeZonesRepository` | **LEGACY / RETAINED / TEST SUPPORT** — not production FAT-017 default; not deleted |
| `stage1SosBreakGlassStore` | **DEBT** — unchanged (out of 01.1) |

---

## Evidence

Touched file: `app/lib/features/n02_day/create_safe_zone_screen.dart` only.

| Check | Result |
|-------|--------|
| `flutter test …/create_safe_zone_screen_test.dart` | **PASS** 7/7, exit 0 |
| `dart analyze create_safe_zone_screen.dart` | **PASS** — no issues |
| `stage1SafeZonesRepository` in save path | Comment-only refuse (`// Do NOT write…`) — **no production write** |

Verified by [Quick FAT-017 test run](2f6dbe06-eeea-4d2c-b36b-8656dcf31ea8).

---

## Scope

```text
SLICE 01.1 ONLY
SLICE 02 NOT STARTED
PHASE 1.75 BROAD CODEGEN NOT ARMED
```

**HARD STOP.**
