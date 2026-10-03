# UX-LOCAL-SEED — Stage-1 local DB fill for design / Visual QA

**Date:** 2026-09-27  
**Status:** ACTIVE (Owner)  
**Release:** never seeds (kReleaseMode)

## Goal

Fill local producers so father/mother hubs are not empty while we finish final UX. Later Backend swaps the same Repository seams — no UI rewrite.

## What runs at every debug boot

1. Existing LDR `ensureRealLocalSeeded` paths (roster, tasks, calendar, circle, chat samples, time request, safe zones, …).
2. **`applyUxLocalSeed()`** — app install ticket, notif prefs rows, time-request re-arm, wallet once.
3. **`applyAuditPopulation`** when `AUDIT_POPULATED` is true (**default true** in debug) — in-memory studio/learn/advisor fixtures.
4. **Bottom tabs stay on** — populate ≠ vision host. Chrome-free tour only with `audit=vision` or `/dev-screens`.

## Honesty

- No GPS trails, FCM delivered, billing, or live AI as production truth.
- Audit Advisor mock is debug-only; release stays EmptyAdvisor.
- Generic child ids (`demo-child`, `child_b`) — Register §10 names stay in `mock/`.

## Run

```bash
cd app
flutter run --dart-define=AUDIT_POPULATED=true
# or simply flutter run (default AUDIT_POPULATED=true in debug)
```
