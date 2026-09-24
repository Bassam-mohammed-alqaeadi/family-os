# 03 — SCR-CHD-006 Engineering (Child SOS Active)

**Screen:** SCR-CHD-006 · الاستغاثة جارية  
**Decision:** EXTEND  
**Widget:** `ChildSosInProgressScreen` · Route: `/scr-chd-006?alertId&childId`  
**Authority:** RD-01 Panic Quiet critical-only · OD-06 cancel · OD-16/17/20 honesty

---

## 1. Purpose

Show the child an honest **active SOS** board: status, parent communication, location/delivery honesty, and an explicit cancel/false-alarm path—without ordinary product chrome.

## 2. Audience

| Role | UI |
|---|---|
| Child | Active critical-only board |
| Parents | Parent lean |

## 3. Entry points

- Navigate from CHD-005 after FIRING success  
- Deep link with `alertId` / `childId`  
- Resume if ACTIVE incident exists for child  

## 4. Exit / navigation

| Action | Destination |
|---|---|
| Contact parent | CHD-007 and/or call-fallback (channel class honest) |
| Confirm “I am safe” | Emit false-alarm → CHD-004 |
| Dismiss cancel sheet | Stay ACTIVE |
| Empty CTA | CHD-005 |
| Parent resolves remotely | Board becomes empty / resolved toast → CHD-004 or empty |

## 5. Information hierarchy (Panic Quiet / critical-only)

1. **Primary:** SOS lifecycle status (ACTIVE / ACKNOWLEDGED visible as “parent saw” only if receipt-backed)  
2. **Secondary:** Parent/contact communication state  
3. **Critical status:** Location class + Delivery class (separate)  
4. **Contextual:** Battery / connection / sync-pending (compact strip)  
5. **Actions:** Contact parent · Cancel (sheet)  

**Forbidden while active:** shell SOS FAB, hub entertainment, learn/wallet/tasks entry, audio/video, mute, setup.

## 6. Controls

| Control | Label intent | Roles | Condition | Enabled | Confirm | Event | Result |
|---|---|---|---|---|---|---|---|
| Contact parent | Call / message parent | Child | ACTIVE/ACK/ESCALATING | If channel AVAILABLE or chat AVAILABLE | No | `SosChildContactParent` | Nav CHD-007 or dialer intent |
| Cancel | I am safe / cancel SOS | Child | Open incident | Yes | **Sheet required** | — | Open sheet |
| Confirm safe | Confirm I am safe | Child | Sheet open | Yes | Yes (this is confirm) | `SosFalseAlarmCancelled` | RESOLVED(FALSE_ALARM) → CHD-004 |
| Sheet back | Keep SOS on | Child | Sheet open | Yes | No | none | Stay ACTIVE |
| Open trigger | Open SOS button | Child | empty | Yes | No | — | CHD-005 |

## 7. State inventory

| State | UI |
|---|---|
| loading | Spinner |
| active | Coral board critical-only |
| acknowledged (child view) | Status text updates only if ack delivery/receipt known |
| escalating | Honesty: “help expanding to trusted contacts” if notified |
| resolved / empty | Empty + CTA CHD-005 or auto-leave |
| cancellation sheet | Modal sheet |
| false_alarm_done | Toast + CHD-004 |
| location_acquiring / stale / unavailable | `SosLocationStatus` chip |
| delivery_pending / succeeded / failed | `SosDeliveryStatus` (never static fake “father saw”) |
| child_offline / network_degraded | Sync pending chip |
| low_battery | Battery chip |
| permission_missing | Soft line; SOS remains |
| retrying | On cancel/network fail |
| error | Load error + retry |
| parent_lean | Lean empty |

## 8. Role-specific UI

Child only interactive body. Parents: lean.

## 9. Empty / error / recovery

- Empty: no active incident.  
- Error: load fail.  
- Cancel fail: stay ACTIVE + error snackbar.  
- Parent remote resolve: treat as empty/resolved recovery.

## 10. IA placement

- Full-screen coral hero status  
- Status card for delivery/location  
- Actions bottom of scroll  
- Cancel = bottom sheet (`SosCancelConfirmation`)  
- Snackbar for resolved/cancel success  

## 11. Design system

- Coral full-bleed; liveRegion on headline; min 48dp actions; ARB; no new colors outside tokens.
