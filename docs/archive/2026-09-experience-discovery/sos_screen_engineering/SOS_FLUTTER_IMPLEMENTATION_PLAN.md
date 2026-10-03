# SOS Flutter Implementation Plan

**Status:** AUTHORIZED for SOS Flutter UI slice only  
**Authority:**  
- [`../sos_final/13_SOS_FINAL_MASTER_CONTRACT.md`](../sos_final/13_SOS_FINAL_MASTER_CONTRACT.md)  
- [`14_SOS_SCREEN_ENGINEERING_MASTER.md`](14_SOS_SCREEN_ENGINEERING_MASTER.md)  

**Out of scope:** backend, FCM, SMS, telephony, GPS provider, audio/video, national emergency numbers.

**Owner authorization note:** Extending `core/policy/sos_*` seams is required to separate incident/delivery/location states and backup verification. `tokens.dart` and `.cursor/rules/` remain untouched.

---

## 1. Current gaps vs frozen contract

| Gap | Current Stage-1 | Required |
|---|---|---|
| Incident status | `active` \| `resolved` only | + `acknowledged`, `escalating`; terminal reason on resolve/cancel |
| Delivery / location | Collapsed into labels | Separate enums + honest PENDING/FAILED/UNAVAILABLE |
| Observer | Can resolve (tests assert this) | **Cannot** resolve/escalate/configure |
| ACK vs RESOLVE | Single resolve CTA | Distinct Acknowledge + Resolve |
| Backups | Unlimited; no phone/verify/priority | Max 5; priority 1..5; verification lifecycle |
| Break-glass | Absent | Primary/Full sheet + local audit seam |
| Panic Quiet | Absent | CHD-006 critical-only + FAT-028 toggle |
| Channel honesty | Implies siren/live/call | PENDING / UNAVAILABLE / NOT_CONFIGURED copy |

---

## 2. Files to modify

| File | Why | Contract map |
|---|---|---|
| `app/lib/core/policy/sos_alert.dart` | Expand incident + location + delivery + connection + terminalReason | OD-05, OD-16, OD-19, OD-20 |
| `app/lib/core/policy/sos_alert_repository.dart` | ack / escalate / resolve / cancelFalseAlarm; load deliveries | OD-01…06 |
| `app/lib/core/policy/sos_ladder.dart` | priority, phone, verificationStatus; max 5 | RD-04, RD-05 |
| `app/lib/core/policy/sos_ladder_repository.dart` | enforce max 5, re-verify on phone change, verified-only helpers | RD-04, RD-05 |
| `app/lib/core/policy/sos_fire.dart` | Keep entitlement-free; seed richer alert fixture | OD-14, OD-17 |
| `app/lib/features/n10_emergency/child_sos_button_screen.dart` | Hold already mostly OK; honest firing copy | CHD-005 |
| `app/lib/features/n10_emergency/child_sos_in_progress_screen.dart` | Critical-only board; delivery/location chips; cancel | CHD-006, RD-01 |
| `app/lib/features/n10_emergency/sos_alert_screen.dart` | Incident center; role gates; ACK≠RESOLVE; Break-glass | FAT-018 |
| `app/lib/features/n10_emergency/emergency_setup_screen.dart` | Role gate; max 5; verify UI; Panic Quiet; no national # | FAT-028 |
| `app/lib/core/i18n/app_en.arb` + `app_ar.arb` (+ generated) | New honesty/role/break-glass/verify strings | Rule 12 |
| `app/lib/core/design/components/components.dart` | Export new SOS components | Rule 15 |
| Tests under `app/test/features/n10_emergency/` + policy tests | Invert Observer resolve; add matrices | Validation contract |
| Supporting only if needed | shell already wires FAB; FAT-058 already has SOS banner | OD-14 |

## 3. Files to create

| File | Why |
|---|---|
| `app/lib/core/policy/sos_role_actions.dart` | SosRoleGuard / action allow matrix (RBAC) |
| `app/lib/core/policy/sos_break_glass.dart` | Local in-memory override seam (UI-only) |
| `app/lib/core/policy/sos_settings.dart` | Panic Quiet prefs (memory store) |
| `app/lib/core/design/components/sos_status_banner.dart` | Lifecycle banner |
| `app/lib/core/design/components/sos_delivery_status.dart` | Delivery honesty |
| `app/lib/core/design/components/sos_location_status.dart` | Location class |
| `app/lib/core/design/components/sos_action_bar.dart` | Role-filtered actions |
| `app/lib/core/design/components/sos_break_glass_sheet.dart` | Break-glass flow UI |
| `app/lib/core/design/components/sos_cancel_confirmation.dart` | Child cancel sheet |
| `app/lib/core/design/components/sos_readiness_card.dart` | FAT-028 readiness |
| `app/lib/core/design/components/trusted_contact_card.dart` | Backup row |
| `app/test/core/policy/sos_role_actions_test.dart` | RBAC unit tests |
| `app/test/core/policy/sos_ladder_verification_test.dart` | Max 5 / verify / verify |
| `docs/.../SOS_FLUTTER_IMPLEMENTATION_REPORT.md` | After ship |

Optional compact: timeline + escalation status can be private widgets inside FAT-018 if reuse is thin—still satisfy engineering names as keys/sections.

## 4. Contract → change map

| Requirement | Implementation |
|---|---|
| OD-01 Observer | Hide/disable resolve/escalate/setup/break-glass; unit + widget tests |
| OD-02 Partner | Ack/escalate/resolve; no FAT-028 edit |
| OD-03/04 Full/Primary | Config + Break-glass |
| OD-05 | `acknowledge()` vs `resolve()` |
| OD-06 | Cancel sheet → `cancelFalseAlarm` |
| OD-07/08 | Call CTA = UNAVAILABLE/NOT_CONFIGURED honesty; no national # field |
| OD-09 | Delivery rows PENDING/FAILED; never fake DELIVERED unless mock marks delivered |
| OD-11 | No mic/audio UI |
| OD-12/RD-01 | Panic Quiet flag → CHD-006 chrome |
| OD-13/Q-02A/B | Break-glass sheet + local override list + auto-expire timer in UI |
| OD-14 | Keep fire entitlement-free; hold reachable |
| OD-16 | LocationStatus enum on model |
| RD-04/05 | Ladder model + FAT-028 UI |
| Q-03A | N/A UI (retention is backend); no delete on resolve |

## 5. Tests required

- Hold 3s / early release (existing + tighten)  
- Observer cannot resolve/escalate/configure  
- Partner can ack + escalate; cannot open FAT-028 edit  
- Full/Primary configure + Break-glass  
- ACK ≠ RESOLVE  
- Max 5 / priority / verification / verified-only escalate helper  
- Break-glass role deny + expiry clears override without policy mutation  
- Panic Quiet hides non-critical chrome on CHD-006  
- Location unavailable / delivery pending honesty  
- No national-number / audio widgets (`findsNothing`)  
- Entitlement-free fire still true  

## 6. Risks

| Risk | Mitigation |
|---|---|
| Breaking existing Observer-can-resolve tests | Replace with cannot-resolve assertions |
| ARB codegen / localization drift | Update both ARB; run gen-l10n or hand-sync generated files per repo pattern |
| Scope creep into real GPS/SMS | Honest enums only; no plugins |
| Rule 21 core/policy | Scoped to `sos_*` only under this owner task |

## 7. Rollback

- Revert commits touching `n10_emergency`, `sos_*`, SOS components, ARB, tests.  
- Stage-1 FAB/routes unchanged structurally → low nav regression risk.

## 8. Validation plan

1. Targeted `flutter test` on n10_emergency + sos policy tests  
2. `python .cursor/hooks/verify_ship.py verify`  
3. `dart format` + analyze clean on touched paths  
4. Real-device: launch app, walk CHD-005→006, FAT-018 role switches if demo role switcher exists, FAT-028; **document** that push/GPS/SMS/call were **not** validated as real  

## 9. Stop condition

Stop after SOS UI slice + report. No backend, no other systems.
