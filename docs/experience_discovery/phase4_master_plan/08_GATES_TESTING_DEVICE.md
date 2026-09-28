# PHASE 4 — Acceptance Gates, Testing Strategy, Real-Device (08)

**Date:** 2026-09-25  

## A. Security / privacy gates (every Local wave)

| Gate | Rule |
|------|------|
| G-RBAC | RoleGuard only; owner-only surfaces enforced |
| G-AUDIT | Append-only; emitters never update/delete |
| G-SOS | SOS/location/chat never subscription-gated |
| G-EXEMPT | Time expiry never locks chat/Quran/SOS |
| G-AI | AiSuggestion approve/reject only; no execute() |
| G-QURAN | No AI-generated verses |
| G-PRIVACY | Collection prefs honored; retention OPEN items stay visible |
| G-CHILDID | No child names outside mock/; screens = ChildId functions |

## B. Offline-first requirements

| Requirement | Wave focus |
|-------------|------------|
| Restart-safe Local stores for converted domains | W0–W3 |
| Offline read of durable chat once Local (FS-010) | W4 gated |
| Outbox/journal survives offline; delivery remote later | W0 + W7 |
| Stale report snapshot OK for FS-009 Local | W4 gated |
| Never claim remote delivered from local enqueue | All waves |

## C. Testing strategy (Phase 5+ execution; plan now)

| Layer | Use for | Avoid |
|-------|---------|-------|
| Unit | Domain stores, Minutes, policy queries | Broad suite as Phase 4 activity |
| Widget | Render + live buttons + loop closure (Rule 17) | Prototype numeral literals |
| Restart-proof | Local persist honesty | Memory-only “green” as durable proof |
| Focused analyze | Changed packages only | Full-repo suite in Phase 4 planning |
| Real-device | W5 NAT capabilities | Emulator-only for GPS/VPN/DeviceAdmin claims |
| Contract seam | Fake alternate Repository proves Rule 25 | Network parsing in features/ |

**Phase 4 itself:** static reconciliation + code inspection only (per Owner). No broad repository suites.

## D. Real-device matrix (W5+)

| Capability | Device proof required |
|------------|----------------------|
| GPS | Live fix + permission deny paths |
| VPN/DNS | Block/allow observable |
| OS intercept | App launch blocked/allowed |
| MediaProjection / camera OS | Capture / disable honesty |
| Mic (FS-008) | After AUD-* + iOS decision |
| FCM/SMS | After REM authorization |
| Telephony | Calls COM:ب |

## E. Per-wave acceptance gate template

```text
WAVE_ID:
  prerequisites: [...]
  authorities_unchanged: yes/no
  dual_authority_audit: clean/fail
  readiness_items_closed: [...]
  still_blocked: [POLICY|NAT|REM|...]
  honesty_badges_updated: yes/no
  production_authorized: NO unless Owner says
  evidence: .verify/<WAVE>.json
```
