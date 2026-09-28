# PHASE 3 — Native Capability Map (07)

**Date:** 2026-09-25  
**Sources:** Phase 1.75 §9 Native Boundary · FS capability inventories · Phase 2 NAT columns  

## Schema

`capability` · `registry_id` · `honesty_state` · `fs_touch` · `class`

## Map

| capability | registry_id | honesty_state | fs_touch | class |
|------------|-------------|---------------|----------|-------|
| Native GPS / live fix | fs001.native_gps | NOT_IMPLEMENTED | FS-001 maps/locate | NATIVE DEPENDENCY |
| Silent locate / find my child OS plane | (locate) | NOT_IMPLEMENTED / UI only | SEC:ل / FS-001 | NATIVE DEPENDENCY |
| VPN/DNS web block | fs002.native_block | MOCK-REMOTE | FS-002 | NATIVE DEPENDENCY |
| OS app intercept / Device Admin | fs003.os_intercept | MOCK-REMOTE | FS-003 | NATIVE DEPENDENCY |
| MediaProjection / screenshot agent | fs004.capture_pipeline | MOCK-REMOTE | FS-004 | NATIVE DEPENDENCY |
| OS camera disable plane | fs004.camera_os_plane | MOCK-REMOTE | FS-004 | NATIVE DEPENDENCY |
| Ambient microphone capture | fs008.mic (target) | NOT IMPLEMENTED (analysis) | FS-008 | NATIVE DEPENDENCY |
| OS wake / AlarmManager for Modes | fs005.os_wake | MOCK-REMOTE | FS-005 | NATIVE DEPENDENCY |
| Device lock / anti-tamper OS | prefs device lock | Prefs local; OS lock NAT | Prefs-misc | NATIVE DEPENDENCY |
| Telephony / VoIP calls | com.calls | NOT_IMPLEMENTED | COM:ب | NATIVE DEPENDENCY |
| Share sheet (PDF/report) | fs009.share (target) | NOT IMPLEMENTED until PDF decision | FS-009 | NATIVE DEPENDENCY |
| Push / FCM receive | fs006 / notifications | MOCK-REMOTE | SOS / Notif | NATIVE DEPENDENCY |
| SMS fallback | fs006.remote_delivery | MOCK-REMOTE | FS-006 | NATIVE DEPENDENCY |

## Honesty rule

UI may show designed states; **must not** claim these planes live. Phase 3 records boundaries only — no implementation.
