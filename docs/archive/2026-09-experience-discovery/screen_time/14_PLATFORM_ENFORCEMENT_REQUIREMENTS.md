# 14 — Platform Enforcement Requirements

**Date:** 2026-09-23  
**Mode:** Document only — **do not implement**  
**Labels:** `PLATFORM CONSTRAINT` · `CURRENT` (= simulated) · `REQUIRED LATER`

---

## Honesty first

CURRENT Flutter code **simulates** policy. It does **not**:

- Measure real app usage
- Block apps at OS level
- Survive reboot as a device admin agent
- Resist uninstall/tamper

FAT-067/068 honesty patterns must extend to every Screen Time claim.

---

## Android (`PLATFORM CONSTRAINT`)

| Capability | Typical API / mode | Maps to Family OS | Notes |
|---|---|---|---|
| Usage metering | UsageStatsManager (`USAGE_STATS`) | `usedMinutesToday` | User must grant special access |
| App restriction | Accessibility overlays / VPN / Device Owner | App block / lock nav | Accessibility fragile; Device Owner strongest |
| Device Owner / managed | Device Policy Controller | Hard lock, uninstall resist | Enterprise-style; high setup cost |
| Overlay / lock screen | Custom lock activity + DP | Instant lock / expiry | Must keep dialer/SOS |
| Foreground enforcement | Accessibility or OEM APIs | Active session deny | Background limits imperfect |
| Reboot persistence | Foreground service + BOOT_COMPLETED | Policy survive restart | OEM battery kills risk |
| Tamper resistance | Device Admin, package monitor | FAT-038 signals | Never claim perfect |

`schema.sql` already lists `USAGE_STATS` perm key — contract hint only.

---

## iOS (`PLATFORM CONSTRAINT`)

| Capability | API | Maps to Family OS | Notes |
|---|---|---|---|
| FamilyControls | Authorization | Parent/child pairing | Entitlement required |
| ManagedSettings | Shields / restrictions | App block / allow | Works under FamilyControls |
| DeviceActivity | Monitors / schedules | Schedules, thresholds, warnings | Extension process |
| Screen Time reports | Family Sharing | FAT-069 usage | Depth < Android custom agent |
| Always-on agent | Limited | Instant lock weaker | Platform honesty mandatory |

Apple: child communication emergency numbers always allowed — aligns with SOS spirit.

---

## What Stage-1 may claim vs must not

| Claim | Allowed now? |
|---|---|
| “Policy saved and mirrored in-app” | Yes |
| “Device will lock this app at OS level” | **No** without agent |
| “Usage is measured from the phone” | **No** while `usedMinutesToday` mock |
| “iOS enforces like Android” | **No** — honesty badge |

---

## Minimum Stage-3 platform package (requirements list)

1. Android Usage Access onboarding + fallback honesty.
2. iOS FamilyControls onboarding + capability matrix.
3. Enforcement state machine wired to UI Policy Health.
4. Exempt surfaces implemented with OS exceptions (Phone/SOS/chat as feasible).
5. Tamper signals → FAT-038 (father-only visibility).
6. No subscription gate on SOS path even when Screen Time SKU exists.

See: [19_SCREEN_TIME_VALIDATION_MODEL.md](19_SCREEN_TIME_VALIDATION_MODEL.md).
