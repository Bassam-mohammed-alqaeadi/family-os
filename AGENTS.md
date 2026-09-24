# AGENTS.md — Family OS root execution guard

Read **`PROJECT_EXECUTION_PLAN.md`** before significant work. Do not duplicate the roadmap here.

## Hard guards

1. **Read the plan first** — identify CURRENT PHASE and whether the request belongs there.
2. **Never silently change phase** — Owner must say `CHANGE PHASE`; then update `PROJECT_EXECUTION_PLAN.md` before proceeding.
3. **Detect and report scope drift** — PREMATURE / BLOCKED / CONFLICTING → warn Owner; do not quietly continue.
4. **KEEP + REFINE UX law** — do not redesign frozen surfaces to simplify code.
5. **Single source of truth** — never create a second authority beside the approved domain owner.
6. **Honest capability states** — distinguish UI / domain / SQLite / offline / native / remote; never convert mocks into fake production claims.
7. **Gate Backend and native** — do not start Backend/native work before its approved gate.
8. **Conflict with roadmap** — warn the Owner before editing.

## Progress report (significant tasks)

```
CURRENT PHASE:
TASK PHASE:
STATUS: ALIGNED / PREMATURE / BLOCKED / CONFLICTING
REQUIRED GATE:
WILL MODIFY PRODUCTION CODE: YES/NO
```

## Current markers (see plan for detail)

* PHASE 1.5 COMPLETE  
* PHASE 1.75 NEXT  
* FS-008 → FS-010 ANALYSIS CONTINUES  
* GLOBAL IMPLEMENTATION PLAN / FULL CODEGEN / BACKEND — NOT YET AUTHORIZED  
