# Phase 1.5 — Platform Hardening Master Plan

**Commission:** Owner Phase 1.5 Platform Hardening, Cross-System Reconciliation & Implementation Readiness  
**Date opened:** 2026-09-24  
**Workspace:** `D:\special projects\family`  
**Authority:** Policy Register → Constitution → FS L2/L3 freezes → FS-001…007 closure → this plan  

**Status:** COMPLETE — 2026-09-24 (PHASE-1.5-HARDEN)  
**Exit:** All FIX closed · DEBT recorded · STOP (no P15-QUR / Stage 3)  

Status vocabulary for findings: `PASS` | `FIX` | `DEBT` | `OUT-OF-SCOPE` | `BLOCKED`

---

## 0. Preflight

| Check | Result |
|---|---|
| `LOOP_STATE` | RUNNING · Lane FS CLOSED · NEXT Owner Phase 1.5 |
| Unanswered `QUESTIONS.md` | **None** |
| FS-001…007 + FS-I-RECON | IMPLEMENTED / COMPLETE (closure report) |
| P15-QUR-004…007 | `deferred_campaign` (parked) |
| Stage 3 | NOT STARTED / deferred |

---

## 1. Scope

Prove FS-001…FS-007 are stable inside Family-OS (~42 systems / ~240 services): no damage to shared infra, UX honesty, security/RBAC, persistence, offline vocabulary, or future boundaries. KEEP → REFINE → REPLACE only when required. Mock-only at remote edges.

---

## 2. Findings register (pre-fix)

### Cross-system / composition

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F01 | Seven separate `MemoryLocalDatabase` instances (Loc/WF/AC/SC/Modes/SOS/AI) — cross-system tables invisible | **FIX** | Shared `FsSessionKernel` composition root |
| P15-F02 | Location → Modes fact feed never wired across runtimes | **FIX** | Shared DB + Location publishes via `ModesLocationFactFeed` |
| P15-F03 | SOS handoff uses SOS-runtime DB, not Location-runtime DB | **FIX** | Same shared kernel (F01) |
| P15-F04 | `SqliteLocalDatabase` unused by Stage-1 runtimes (no restart persistence) | **FIX** | Kernel prefers SQLite outside `FLUTTER_TEST`; Memory fallback = DEGRADED honesty |
| P15-F05 | FAT-034 defaults to Prefs AC rules while AC SQLite exists | **FIX** | Bootstrap on `Stage1AppControlRuntime.accessRules` |
| P15-F06 | Smart Modes Prefs fallback on `ensureOpen` failure | **DEBT** | Fail-loud later; not blocking honesty |
| P15-F07 | Unlock / ST / time-request still Prefs | **DEBT** | Non-FS Stage-1 leftovers |
| P15-F08 | WF production path on Domain store | **PASS** | — |

### Capability honesty

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F09 | `defaultSeeds` stale vs shipped IMPLEMENTED until `applyFs*` | **FIX** | Align seeds + `applyAllCampaignCapabilities()` at kernel open |
| P15-F10 | `applyFs001XsysCapabilities` never called from production | **FIX** | Call from Location / `applyAll` |
| P15-F11 | Per-runtime CapabilityRegistry before shared DB | **FIX** | Unified via F01 |

### Policy delivery / enforcement honesty

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F12 | WF save → Configured only; badges SIMULATED | **PASS** | — |
| P15-F13 | `simulateLocalAckToVerified` test-only risk | **DEBT** | Guard later |
| P15-F14 | Native planes correctly MOCK-REMOTE / NOT_IMPLEMENTED | **PASS** | — |

### Security / RBAC

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F15 | SOS / Modes / SC / WF unlock / AI review domain RBAC | **PASS** | — |
| P15-F16 | `AppControlUxBridge.actorFor` maps child → father | **FIX** | `AppControlActor.child()` deny |
| P15-F17 | Router RoleGuard lacks mother-level path matrix | **DEBT** | Domain throws remain; deep-link UI open |
| P15-F18 | SOS never subscription-gated | **PASS** | — |
| P15-F19 | AI suggest-only / no execute | **PASS** | — |

### Offline / outbox

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F20 | `MockRemoteAdapter` not wired into Stage-1 event paths | **DEBT** | Port exists; enqueue deferred Stage 3 — honesty already MOCK-REMOTE |
| P15-F21 | Memory close does not clear rows | **DEBT** | Kernel reset replaces instance |
| P15-F22 | Configured ≠ enforced vocabulary present | **PASS** | — |

### Shell / nav / l10n / visual

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F23 | FS hosts routed; RoleGuard + tombstones | **PASS** | — |
| P15-F24 | Light visual KEEP/REFINE — no redesign needed | **PASS** | Spot-check only |
| P15-F25 | ARB + RTL on FS surfaces | **PASS** | Residual typos → DEBT if found |

### Database

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F26 | Schema v1–v10 + `onUpgrade` steps match | **PASS** | — |
| P15-F27 | No SQLite upgrade-chain integration test | **FIX** | Add focused migration test (temp file / memory step proof) |
| P15-F28 | Duplicate policy stores avoided by ownership matrix | **PASS** | After F01 |

### Device / performance

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F29 | Samsung SM-S906U / Android 16 device pass | **DEBT** / honest **UNSUPPORTED** if unavailable | Record in closure — never fabricate |
| P15-F30 | Performance claims | **OUT-OF-SCOPE** | Evidence-only; no invented metrics |

### Tests / verify

| ID | Finding | Class | Action |
|---|---|---|---|
| P15-F31 | FS-I-RECON / FS-007-UX full suite passed | **PASS** | Re-run `--full` at Phase 1.5 close |
| P15-F32 | Stale `.verify/FS-001-UX.json` failed artifact | **DEBT** | Superseded; optional prune |
| P15-F33 | Shared-kernel + RBAC child + FAT-034 wiring tests | **FIX** | Add/extend focused tests |

### Campaign residuals (expected)

| ID | Finding | Class |
|---|---|---|
| P15-F34 | Native GPS / VPN / OS intercept / capture / OS wake / FCM / cloud classify | **OUT-OF-SCOPE** (Stage 3) |
| P15-F35 | P15-QUR resume / Stage 3 entry | **OUT-OF-SCOPE** — Owner halt after this phase |
| P15-F36 | Product-law blockers | **BLOCKED** — none opened |

---

## 3. FIX execution order

1. **P15-F01/F03/F04/F09/F10/F11** — `FsSessionKernel` + seed align + `applyAll` + SQLite-outside-test  
2. **P15-F02** — Location evaluate path always gets shared `ModesLocationFactFeed`  
3. **P15-F16** — Child actor deny  
4. **P15-F05** — FAT-034 → Domain AC bootstrap  
5. **P15-F27/F33** — Migration + regression tests  
6. Analyze → scoped/full verify → document ledger → closure  

DEBT / OUT-OF-SCOPE: record only; do not expand scope.

---

## 4. Exit criteria

- All **FIX** rows closed or Owner-deferred in QUESTIONS (none expected)  
- `PHASE_1_5_CHANGE_LEDGER.md` + `PHASE_1_5_CLOSURE_REPORT.md` written  
- `verify_ship.py verify --full` exit 0  
- Harness: Phase 1.5 CLOSED · P15-QUR parked · Stage 3 not started · **no next feature wave armed**  
- Final status block published  

---

## 5. Non-goals

- Redesign of L3 screens  
- Backend / Firebase / live remote  
- Resume P15-QUR-004…007  
- Enter Stage 3  
- Invent policy law  
- Fake device validation  
