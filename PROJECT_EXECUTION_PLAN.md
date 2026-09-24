# FAMILY OS — PROJECT EXECUTION PLAN

**Authority:** Authoritative human-readable execution roadmap for Guardian Eye Pro / Family OS.  
**Owner changes:** Require explicit `CHANGE PHASE` before treating the roadmap as changed.  
**Last governance install:** 2026-09-24

---

## CURRENT POSITION

We began with a complete web prototype containing:

* 42 systems
* 240 services
* 73 journeys
* 130 screens

Cursor converted that prototype into Flutter primarily as a **UI/mock/simulation implementation**.

The current objective is NOT to throw away that prototype.

The approved strategy is:

**Web Prototype**  
→ **Flutter Prototype**  
→ **Real Local Flutter Runtime**  
→ **Complete policies / domains / missing UI**  
→ **Native platform capabilities**  
→ **Backend / Sync**  
→ **Production certification**

---

## CURRENT STATE (authoritative)

| Marker | Status |
|--------|--------|
| `PHASE 1.5 COMPLETE` | Yes (FS-001 → FS-007 reconciliation evidenced) |
| `PHASE 1.75 NEXT` | Yes — next implementation direction |
| `FS-008 → FS-010 ANALYSIS CONTINUES` | Yes |
| `GLOBAL IMPLEMENTATION PLAN NOT YET AUTHORIZED` | Yes |
| `FULL CODEGEN NOT YET AUTHORIZED` | Yes |
| `BACKEND INTEGRATION NOT YET AUTHORIZED` | Yes |

Do not mark any of these as complete unless later evidence proves it.

---

## PHASE 1 — COMPLETE SYSTEM DESIGN

Continue analytical/design work across:

`FS-001 → FS-010`

For every system establish:

* requirements
* policies
* domain ownership
* data ownership
* events
* contracts
* cross-system dependencies
* UX surfaces
* RBAC
* offline behavior
* native requirements
* backend requirements
* testing requirements

**NO** broad production implementation before the design gates justify it.

---

## PHASE 1.5 — UX + IMPLEMENTATION RECONCILIATION

This phase has already been performed for:

`FS-001 → FS-007`

Evidence includes:

* `docs/experience_discovery/FAMILY_OS_SCREEN_BEFORE_AFTER_UX_AUDIT.md`
* `FS_001_007_IMPLEMENTATION_GAP_MATRIX.md`
* `FS_001_007_RECONCILIATION_REPORT.md`

Current findings include under-bound Stage-1 repositories, duplicate authority risks, verification conflicts, and unimplemented native/remote capability planes.

---

## PHASE 1.75 — REAL FLUTTER RUNTIME CONVERSION

**THIS IS THE NEXT IMPLEMENTATION DIRECTION.**

### Objective

Convert the existing Flutter simulation into a **real local Flutter application/runtime**, without redesigning or discarding the existing product experience.

This means progressively replacing simulation-only foundations with real:

* Flutter state management
* Riverpod state
* Domain services
* repositories
* SQLite persistence
* Outbox
* Local Event Bus
* policy evaluation
* audit records
* restart-safe state
* offline behavior
* local cross-system contracts

### Goal

**Real Local Application**

### Not the goal (yet)

**Full Native/Backend Production System**

---

## CRITICAL DISTINCTION

The following are **NOT** the same thing:

`UI implemented`  
≠ `Domain implemented`  
≠ `SQLite persisted`  
≠ `Offline resilient`  
≠ `Native OS enforced`  
≠ `Backend synchronized`

Never report one as another.

Capability states must remain honest:

* REAL LOCAL
* LOCAL ONLY
* MOCK-REMOTE
* NOT IMPLEMENTED
* NOT CONFIGURED
* UNSUPPORTED
* REMOTE UNIMPLEMENTED

---

## FS-001 → FS-007 POLICY

Use the reconciled FS-001 → FS-007 implementation as the **first proving ground** for the Real Flutter Runtime.

* Do **NOT** treat them as evidence that the whole product is complete.
* Do **NOT** freeze the project only around FS-001 → FS-007.
* Continue analytical work on `FS-008 → FS-010` and the broader 42-system product inventory.

---

## DO NOT DO THESE PREMATURELY

Until the relevant design/dependency gates are complete:

* Do not implement all 42 systems blindly.
* Do not convert every PlaceholderScreen just to increase completion percentages.
* Do not invent policies for systems not yet analyzed.
* Do not introduce new duplicate repositories.
* Do not create a second authority beside the approved domain owner.
* Do not replace architecture simply because the current code is imperfect.
* Do not begin full Backend integration prematurely.
* Do not claim native enforcement when the native plane is absent.
* Do not claim cloud functionality when transport/cloud implementation is absent.
* Do not redesign frozen KEEP/REFINE screens merely to simplify implementation.

---

## GLOBAL ROADMAP AFTER PHASE 1.75

After Real Local Flutter Runtime conversion progresses sufficiently:

### PHASE 2

Complete remaining system analysis / policies / L2-L3:

`FS-008 → FS-010`

and reconcile dependencies with the broader:

`42 systems / 240 services / 73 journeys / 130 screens`

### PHASE 3

Global reconciliation:

* System Map
* Domain/Policy Ownership Map
* Data Ownership Map
* Event/Contract Map
* Screen Map
* Journey Integrity Map
* Native Capability Map
* Backend Capability Map
* Full Dependency Graph

### PHASE 4

Master Implementation Plan

Create the real dependency-first implementation graph.

Do **NOT** implement strictly by FS number.

### PHASE 5

Agentic implementation waves:

1. Shared Foundation
2. Local Domains
3. UX integration
4. Cross-system seams
5. Native Android planes
6. Mock transport
7. Real backend
8. Certification

### PHASE 6

Real-device certification, including:

* offline
* restart/recovery
* permissions
* RBAC
* security
* native enforcement
* transport
* device-specific validation

---

## PROGRESS PERCENTAGES ARE NOT EXECUTION AUTHORITY

Do **NOT** optimize for:

* number of green screens
* number of converted services
* percentage of placeholders removed
* test count alone

A feature is considered genuinely implemented only when its required layers are evidenced.

---

## MANDATORY DEVIATION CHECK

Before beginning **ANY** requested implementation, refactor, redesign, migration, or architecture change:

1. Read `PROJECT_EXECUTION_PLAN.md`.
2. Identify the CURRENT PHASE.
3. Identify the requested task's phase.
4. Check dependencies and gates.
5. Check for conflicts with approved architecture/policy.
6. State whether the task is:
   * **ALIGNED**
   * **PREMATURE**
   * **BLOCKED**
   * **CONFLICTING**

If it is PREMATURE, BLOCKED, or CONFLICTING:

**DO NOT silently continue.**

Explicitly tell the Owner:

> "This request is outside the current approved execution phase."

Then explain the exact missing gate.

If the Owner explicitly changes the roadmap, update the governance files **BEFORE** proceeding.

---

## OWNER AUTHORITY

The Product Owner / Executive Director may deliberately change the roadmap.

However, such a change must be **explicit**.

Never infer a phase change from a casual request.

A request such as:

* "let's quickly build this"
* "skip the analysis"
* "do this screen first"
* "connect backend now"
* "rewrite this architecture"

does **NOT** automatically change the approved project phase.

Ask the Owner to explicitly state:

`CHANGE PHASE`

before treating the roadmap as changed.

---

## REQUIRED PROGRESS REPORT FORMAT

At the beginning of significant Agent tasks, report:

```
CURRENT PHASE:
TASK PHASE:
STATUS: ALIGNED / PREMATURE / BLOCKED / CONFLICTING
REQUIRED GATE:
WILL MODIFY PRODUCTION CODE: YES/NO
```
