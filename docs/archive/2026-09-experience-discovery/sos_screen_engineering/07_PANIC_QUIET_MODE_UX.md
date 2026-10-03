# 07 — Panic Quiet Mode UX

**Authority:** RD-01 · OD-12 · OD-14  
**Config surface:** FAT-028  
**Presentation surface:** CHD-006 (and suppresses shell chrome while ACTIVE)

---

## 1. Purpose

During an **active SOS**, the child sees only emergency-critical information/actions so ordinary product UI cannot bury the emergency.

## 2. Entry

| Path | Behavior |
|---|---|
| Config | Primary/Full toggles Panic Quiet ON in FAT-028 → audit `SosPanicQuietModeChanged` |
| Runtime | When incident becomes ACTIVE and mode ON (or always apply critical-only per contract—mode ON enforces stricter chrome kill) | 

**Frozen UX default:** While any SOS incident is ACTIVE for the child, CHD-006 uses critical-only hierarchy; Panic Quiet ON also suppresses competing shell/hub entry while on CHD-006.

## 3. Visual hierarchy (CHD-006)

Allowed:

1. SOS status (lifecycle honesty)  
2. Parent/contact communication state  
3. Location status class  
4. Delivery honesty class  
5. Contact parent action  
6. Explicit cancel → false-alarm sheet  
7. Compact battery/connectivity if needed for honesty  

Forbidden:

- Entertainment / learn / wallet / tasks entry  
- Shell SOS FAB (already hidden on 005/006)  
- Non-SOS hub  
- Audio/video  
- Setup / mute  

## 4. Allowed actions

- Contact parent  
- Cancel with confirmation  
- Observe status (read-only)

## 5. Forbidden navigation

While ACTIVE on CHD-006: no navigation to day entertainment destinations except Contact→CHD-007 (communication is emergency-critical) and post-cancel CHD-004.

## 6. Exit / recovery

| Event | UI |
|---|---|
| Child false-alarm confirm | Leave Panic Quiet board → CHD-004 |
| Parent resolve | Board clears → recovery empty/CHD-004 |
| Mode toggled OFF while idle | Next ACTIVE still critical-only minimum; OFF may allow slightly richer honesty strip only—never entertainment |

## 7. Parent visibility

FAT-028 / readiness: show Panic Quiet ON/OFF. Does **not** mute parent SOS receipt.

## 8. Components

- CHD-006 layout mode flag `panicQuiet`  
- `SosStatusBanner`, `SosLocationStatus`, `SosDeliveryStatus`, `SosCancelConfirmation`
